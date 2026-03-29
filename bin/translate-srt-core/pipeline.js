// pipeline.js
'use strict';

const fs = require('fs');
const path = require('path');

const {CONFIG} = require('./config');
const {parseSRT, buildSRT} = require('./srt-io');
const {
    protectTags,
    restoreTags,
    buildSpeakerMap,
    normalizeSpeakerTags,
    stripNormalizedSpeakers,
} = require('./tags-and-speakers');
const {buildAdaptiveBatches} = require('./batching');
const {callOpenAI} = require('./openai-client');
const {
    extractGlossary,
    buildSystemPrompt,
    buildUserPrompt,
    buildSinglePrompt,
} = require('./prompts');
const {validateBatchIndices, validateSubtitleText} = require('./validation');
const {resegmentFromJson, STANDARDS: RESEGMENT_STANDARDS} = require('./resegment');

const log = {
    info: (...a) => console.log(...a),
    warn: (...a) => console.warn(' ⚠️', ...a),
    error: (...a) => console.error(' ❌', ...a),
    ok: (...a) => console.log(' ✅', ...a),
};

const delay = ms => new Promise(r => setTimeout(r, ms));

const ASR_WATERMARKS = [
    /transcri(?:ption|bed) by/i,
    /subtitles? by/i,
    /castingwords/i,
    /amara\.org/i,
    /opensubtitles/i,
    /sync(?:ed|hronized) by/i,
];

function isWatermark(text) {
    return ASR_WATERMARKS.some(p => p.test(text));
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point principal
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Pipeline completo de traducción SRT.
 *
 * @param {string}      inputFile   Ruta al .srt de entrada
 * @param {string}      outputFile  Ruta al .srt de salida traducido
 * @param {string|null} jsonPath    (opcional) Ruta al .json de WhisperX para resegmentación
 */
async function translateSrtFile(inputFile, outputFile, jsonPath = null) {
    if (!fs.existsSync(inputFile)) {
        throw new Error(`Archivo no encontrado: ${inputFile}`);
    }

    // ── FASE 0: Origen de subtítulos ──────────────────────────────────────────
    // El SRT original es siempre la fuente de verdad temporal.
    // El JSON, si existe, solo refina la segmentación dentro de esos anclajes.
    const rawSrt = fs.readFileSync(inputFile, 'utf-8');
    const originalSubs = parseSRT(rawSrt);
    let rawSubtitles;

    if (jsonPath) {
        log.info('\n🔬 JSON de WhisperX detectado — aplicando resegmentación anclada al SRT original...');

        const {subtitles: resegmented, stats, hasWordTimestamps} = resegmentFromJson(jsonPath, originalSubs);

        if (!hasWordTimestamps) {
            log.warn('El JSON no contiene timestamps por palabra; resegmentación basada en segmentos (menos precisa).');
        }

        log.info(
            `   Subtítulos: ${stats.totalSubtitles} | ` +
            `Duración media: ${stats.avgDurationSec}s (máx ${stats.maxDurationSec}s) | ` +
            `CPS medio: ${stats.avgCPS} (máx ${stats.maxCPS})`
        );

        if (stats.aboveMaxCPS > 0) {
            log.warn(`${stats.aboveMaxCPS} subtítulo(s) superan ${RESEGMENT_STANDARDS.maxCPS} CPS tras resegmentación.`);
        }

        rawSubtitles = resegmented;
    } else {
        log.info('\n📄 Usando SRT directamente (sin resegmentación). Añade --json para mayor calidad.');
        rawSubtitles = originalSubs;
    }

    // ── PRE-FASE: Eliminar watermarks ─────────────────────────────────────────
    const cleanedSubtitles = rawSubtitles.filter(s => {
        if (isWatermark(s.text)) {
            log.warn(`Sub #${s.index} eliminado (watermark ASR): "${s.text.slice(0, 60)}"`);
            return false;
        }
        return true;
    });

    if (!cleanedSubtitles.length) {
        throw new Error('No se encontraron subtítulos válidos en el archivo.');
    }

    log.info(`📄 ${cleanedSubtitles.length} subtítulos cargados: ${path.basename(inputFile)}`);
    log.info(`🤖 Modelo: ${CONFIG.model}`);

    // ── FASE 1: Normalizar speakers + proteger etiquetas ──────────────────────
    const speakerMap = buildSpeakerMap(cleanedSubtitles);
    const tagMaps = new Map();

    const protectedSubs = cleanedSubtitles.map(s => {
        const normalized = normalizeSpeakerTags(s.text, speakerMap);
        const {protectedText, tagMap} = protectTags(normalized);
        tagMaps.set(s.index, tagMap);
        return {...s, protectedText};
    });

    if (speakerMap.size > 0) {
        log.info(
            `🎙️ ${speakerMap.size} hablantes detectados: ` +
            [...speakerMap.entries()].map(([id, l]) => `${l}=${id}`).join(', ')
        );
    }

    // ── FASE 2: Glosario ──────────────────────────────────────────────────────
    log.info('\n🔍 Analizando contenido (glosario y metadatos)...');
    const meta = await extractGlossary(cleanedSubtitles);
    log.info(`   Tipo: ${meta.contentType} | Registro: ${meta.register} | Glosario: ${meta.glossary.length} términos`);

    // ── FASE 3: Prompt de sistema ─────────────────────────────────────────────
    const systemPrompt = buildSystemPrompt(meta, speakerMap);

    // ── FASE 4: Lotes adaptativos ─────────────────────────────────────────────
    const batches = buildAdaptiveBatches(protectedSubs);
    log.info(`\n📦 ${batches.length} lotes generados (máx ~${CONFIG.maxTokensPerBatch} tokens/lote)\n`);

    // ── FASE 5: Traducción ────────────────────────────────────────────────────
    const resultMap = new Map();
    let contextBuffer = [];

    for (let i = 0; i < batches.length; i++) {
        const batch = batches[i];
        const batchNum = i + 1;
        const range = `${batch.at(0).index}–${batch.at(-1).index}`;

        process.stdout.write(`🔄 Lote ${batchNum}/${batches.length} (subs ${range})... `);

        try {
            const userPrompt = buildUserPrompt(batch, contextBuffer);
            let finalResult = null;

            for (let attempt = 1; attempt <= CONFIG.maxBatchRetries; attempt++) {
                try {
                    const raw = await callOpenAI(
                        [
                            {role: 'system', content: systemPrompt},
                            {role: 'user', content: userPrompt},
                        ],
                        {jsonObject: true}
                    );

                    const parsed = JSON.parse(raw);
                    const translationsObj = parsed.translations ?? {};
                    const {valid, missing, extra, cleaned} = validateBatchIndices(batch, translationsObj);

                    if (valid) {
                        finalResult = cleaned;
                        break;
                    }

                    log.warn(
                        `Intento ${attempt}/${CONFIG.maxBatchRetries} — índices incorrectos. ` +
                        `Faltan: [${missing}] | Extra: [${extra}]`
                    );

                    if (attempt < CONFIG.maxBatchRetries) {
                        await delay(1000 * attempt);
                    }
                } catch (err) {
                    log.error(`Intento ${attempt}/${CONFIG.maxBatchRetries} — error API: ${err.message}`);
                    if (attempt < CONFIG.maxBatchRetries) await delay(1000 * attempt);
                    else throw err;
                }
            }

            if (finalResult === null) {
                log.warn(`Lote ${batchNum} escalado a traducción individual (${batch.length} subs).`);
                await translateBatchIndividually(batch, systemPrompt, resultMap);
            } else {
                await validateAndFillBatch(batch, finalResult, systemPrompt, resultMap);
            }
        } catch (err) {
            log.error(`Lote ${batchNum} falló definitivamente: ${err.message}`);
            for (const sub of batch) {
                if (!resultMap.has(sub.index)) {
                    resultMap.set(sub.index, sub.text);
                }
            }
        }

        const newItems = batch.slice(-CONFIG.contextSize).map(s => ({
            ...s,
            translatedText: restoreTags(resultMap.get(s.index) ?? s.text, tagMaps.get(s.index))
        }));
        contextBuffer = [...contextBuffer, ...newItems].slice(-CONFIG.contextSize);

        console.log('✅');

        if (i < batches.length - 1) await delay(CONFIG.delayMs);
    }

    // ── FASE 6: Restaurar etiquetas y escribir SRT ────────────────────────────
    const outputSubs = cleanedSubtitles.map(s => {
        const translated = resultMap.get(s.index) ?? s.text;
        const restored = restoreTags(translated, tagMaps.get(s.index));
        return {
            index: s.index,
            timestamp: s.timestamp,
            text: stripNormalizedSpeakers(restored),
        };
    });

    // ✅ Comparar contra el texto ya procesado (sin hablantes):
    const cleanedStripped = new Map(
        cleanedSubtitles.map(s => [s.index, stripNormalizedSpeakers(restoreTags(s.text, tagMaps.get(s.index)))])
    );
    const unchanged = outputSubs.filter(s => s.text === cleanedStripped.get(s.index)).length;

    if (unchanged > 0) log.warn(`${unchanged} subtítulos conservaron el texto original (fallback).`);

    // unchanged es la medida definitiva: lo que realmente quedó sin traducir en el output final
    const fallbackRatio = cleanedSubtitles.length > 0 ? unchanged / cleanedSubtitles.length : 0;
    log.info(`Fallback ratio: ${(fallbackRatio * 100).toFixed(1)}%`);

    if (fallbackRatio > CONFIG.strictFallbackThreshold) {
        throw new Error(
            `Umbral estricto de fallback superado ` +
            `(${(fallbackRatio * 100).toFixed(1)}% > ` +
            `${(CONFIG.strictFallbackThreshold * 100).toFixed(1)}%). ` +
            `No se generó el archivo de salida.`
        );
    }

    fs.writeFileSync(outputFile, buildSRT(outputSubs), 'utf-8');
    log.info(`\n✅ Traducción completada → ${outputFile}\n`);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers internos
// ─────────────────────────────────────────────────────────────────────────────

async function validateAndFillBatch(batch, translations, systemPrompt, resultMap) {
    const toRetry = [];

    for (const sub of batch) {
        const text = translations[String(sub.index)];
        const {ok, reason} = validateSubtitleText(sub.protectedText, text);

        if (ok) {
            resultMap.set(sub.index, text);
        } else {
            log.warn(`Sub #${sub.index} inválido (${reason}) — se reintentará individualmente.`);
            toRetry.push(sub);
        }
    }

    if (toRetry.length > 0) {
        await translateBatchIndividually(toRetry, systemPrompt, resultMap);
    }
}

async function translateBatchIndividually(subs, systemPrompt, resultMap) {
    for (const sub of subs) {
        let recovered = null;

        for (let attempt = 1; attempt <= CONFIG.maxSingleRetries; attempt++) {
            try {
                const raw = await callOpenAI(
                    [
                        {role: 'system', content: systemPrompt},
                        {role: 'user', content: buildSinglePrompt(sub)},
                    ],
                    {jsonObject: true}
                );
                const text = (JSON.parse(raw).translations ?? {})[String(sub.index)];
                if (text) {
                    recovered = text;
                    break;
                }
            } catch (err) {
                log.warn(`Sub #${sub.index} intento ${attempt}/${CONFIG.maxSingleRetries}: ${err.message}`);
                if (attempt < CONFIG.maxSingleRetries) await delay(300 * attempt);
            }
        }

        if (!recovered) {
            log.warn(`Sub #${sub.index} sin recuperación — se conserva original.`);
            recovered = sub.text;
        }

        resultMap.set(sub.index, recovered);
        await delay(300);
    }
}

module.exports = {translateSrtFile};