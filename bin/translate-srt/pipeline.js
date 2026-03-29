// pipeline.js
'use strict';

const fs = require('fs');
const path = require('path');

const { CONFIG } = require('./config');
const { parseSRT, buildSRT } = require('./srt-io');
const {
    protectTags,
    restoreTags,
    buildSpeakerMap,
    normalizeSpeakerTags,
    stripNormalizedSpeakers
} = require('./tags-and-speakers');
const { buildAdaptiveBatches } = require('./batching');
const { callOpenAI } = require('./openai-client');
const { extractGlossary, buildSystemPrompt, buildUserPrompt, buildSinglePrompt } = require('./prompts');
const { validateBatchIndices, validateSubtitleText } = require('./validation');

const log = {
    info: (...a) => console.log(...a),
    warn: (...a) => console.warn(' ⚠️', ...a),
    error: (...a) => console.error(' ❌', ...a),
    ok: (...a) => console.log(' ✅', ...a)
};

const delay = ms => new Promise(r => setTimeout(r, ms));

// Patrones de watermarks típicos de ASR
const ASR_WATERMARKS = [
    /transcri(?:ption|bed) by/i,
    /subtitles? by/i,
    /castingwords/i,
    /amara\.org/i,
    /opensubtitles/i,
    /sync(?:ed|hronized) by/i
];

function isWatermark(text) {
    return ASR_WATERMARKS.some(p => p.test(text));
}

/**
 * Fase completa de traducción SRT.
 */
async function translateSrtFile(inputFile, outputFile) {
    if (!fs.existsSync(inputFile)) {
        throw new Error(`Archivo no encontrado: ${inputFile}`);
    }

    const raw = fs.readFileSync(inputFile, 'utf-8');
    const subtitles = parseSRT(raw);

    const cleanedSubtitles = subtitles.filter(s => {
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

    // FASE 1: normalizar speakers + proteger etiquetas
    const speakerMap = buildSpeakerMap(cleanedSubtitles);
    const tagMaps = new Map();
    const protectedSubs = cleanedSubtitles.map(s => {
        const normalized = normalizeSpeakerTags(s.text, speakerMap);
        const { protectedText, tagMap } = protectTags(normalized);
        tagMaps.set(s.index, tagMap);
        return { ...s, protectedText };
    });

    if (speakerMap.size > 0) {
        log.info(
            `🎙️ ${speakerMap.size} hablantes detectados: ` +
            [...speakerMap.entries()].map(([id, l]) => `${l}=${id}`).join(', ')
        );
    }

    // FASE 2: glosario
    log.info('\n🔍 Analizando contenido (glosario y metadatos)...');
    const meta = await extractGlossary(cleanedSubtitles);
    log.info(`   Tipo: ${meta.contentType} | Registro: ${meta.register} | Términos en glosario: ${meta.glossary.length}`);

    // FASE 3: prompt de sistema
    const systemPrompt = buildSystemPrompt(meta, speakerMap);

    // FASE 4: lotes adaptativos
    const batches = buildAdaptiveBatches(protectedSubs);
    log.info(`\n📦 ${batches.length} lotes generados (máx ~${CONFIG.maxTokensPerBatch} tokens/lote)\n`);

    // FASE 5: traducción
    const resultMap = new Map(); // índice → texto traducido (con placeholders)
    let contextBuffer = [];
    let fallbackCount = 0;

    for (let i = 0; i < batches.length; i++) {
        const batch = batches[i];
        const batchNum = i + 1;
        const range = `${batch.at(0).index}–${batch.at(-1).index}`;

        process.stdout.write(`🔄 Lote ${batchNum}/${batches.length} (subs ${range})... `);

        let translations = {};
        try {
            const userPrompt = buildUserPrompt(batch, contextBuffer);
            let finalResult = null;

            for (let attempt = 1; attempt <= CONFIG.maxBatchRetries; attempt++) {
                try {
                    const raw = await callOpenAI(
                        [
                            { role: 'system', content: systemPrompt },
                            { role: 'user', content: userPrompt }
                        ],
                        { jsonMode: true }
                    );
                    const parsed = JSON.parse(raw);
                    const translationsObj = parsed.translations ?? {};
                    const { valid, missing, extra, cleaned } = validateBatchIndices(batch, translationsObj);

                    if (valid) {
                        finalResult = cleaned;
                        break;
                    }

                    log.warn(
                        `Intento ${attempt}/${CONFIG.maxBatchRetries} — índices incorrectos. ` +
                        `Faltan: [${missing}] | Extra: [${extra}]`
                    );

                    // Último intento: limpiar extras y salir
                    if (attempt === CONFIG.maxBatchRetries) {
                        finalResult = null; // fuerza traducción individual
                    } else {
                        await delay(1000 * attempt);
                    }
                } catch (err) {
                    log.error(`Intento ${attempt}/${CONFIG.maxBatchRetries} — error API: ${err.message}`);
                    if (attempt === CONFIG.maxBatchRetries) {
                        throw err;
                    }
                    await delay(1000 * attempt);
                }
            }

            if (finalResult === null) {
                log.warn(`Lote ${batchNum} escalado a traducción individual (${batch.length} subs).`);
                await translateBatchIndividually(batch, systemPrompt, resultMap);
            } else {
                translations = finalResult;
                await validateAndFillBatch(batch, translations, systemPrompt, resultMap);
            }
        } catch (err) {
            log.error(`Lote ${batchNum} falló definitivamente: ${err.message}`);
            // fallback total a originales
            for (const sub of batch) {
                if (!resultMap.has(sub.index)) {
                    resultMap.set(sub.index, sub.text);
                    fallbackCount++;
                }
            }
        }

        // contexto para siguiente lote
        contextBuffer = batch
            .slice(-CONFIG.contextSize)
            .map(s => ({ ...s, translatedText: resultMap.get(s.index) ?? s.text }));

        console.log('✅');

        if (i < batches.length - 1) await delay(CONFIG.delayMs);
    }

    // FASE 6: restaurar etiquetas y escribir SRT
    const outputSubs = cleanedSubtitles.map(s => {
        const translatedOrOriginal = resultMap.get(s.index) ?? s.text;
        const restored = restoreTags(translatedOrOriginal, tagMaps.get(s.index));
        return {
            index: s.index,
            timestamp: s.timestamp,
            text: stripNormalizedSpeakers(restored)
        };
    });

    // Stats de fallback
    const unchanged = outputSubs.filter(
        s => s.text === cleanedSubtitles.find(o => o.index === s.index)?.text
    ).length;
    fallbackCount += unchanged;

    if (unchanged > 0) {
        log.warn(`${unchanged} subtítulos conservaron el texto original (fallback).`);
    }

    const fallbackRatio = fallbackCount / cleanedSubtitles.length;
    log.info(`Fallback ratio aproximado: ${(fallbackRatio * 100).toFixed(1)}%`);

    if (fallbackRatio > CONFIG.strictFallbackThreshold) {
        log.error(
            `Umbral estricto de fallback superado (${(fallbackRatio * 100).toFixed(1)}% > ` +
            `${(CONFIG.strictFallbackThreshold * 100).toFixed(1)}%). No se genera archivo de salida.`
        );
        throw new Error('Traducción marcada como fallida por exceso de fallbacks.');
    }

    fs.writeFileSync(outputFile, buildSRT(outputSubs), 'utf-8');
    log.info(`\n✅ Traducción completada → ${outputFile}\n`);
}

/**
 * Valida textos del lote y reintenta individuales si es necesario.
 */
async function validateAndFillBatch(batch, translations, systemPrompt, resultMap) {
    const toRetry = [];

    for (const sub of batch) {
        const text = translations[String(sub.index)];
        const { ok, reason } = validateSubtitleText(sub.text, text);

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

/**
 * Traduce una lista de subtítulos individualmente con reintentos.
 */
async function translateBatchIndividually(subs, systemPrompt, resultMap) {
    for (const sub of subs) {
        let recoveredText = null;

        for (let attempt = 1; attempt <= CONFIG.maxSingleRetries; attempt++) {
            try {
                const userPrompt = buildSinglePrompt(sub);
                const raw = await callOpenAI(
                    [
                        { role: 'system', content: systemPrompt },
                        { role: 'user', content: userPrompt }
                    ],
                    { jsonMode: true }
                );
                const parsed = JSON.parse(raw);
                const text = (parsed.translations ?? {})[String(sub.index)];
                if (text) {
                    recoveredText = text;
                    break;
                }
            } catch (err) {
                log.warn(`Sub #${sub.index} intento ${attempt}/${CONFIG.maxSingleRetries} falló: ${err.message}`);
                if (attempt < CONFIG.maxSingleRetries) {
                    await delay(300 * attempt);
                }
            }
        }

        if (!recoveredText) {
            log.warn(`Sub #${sub.index} sin recuperación — se conserva original.`);
            recoveredText = sub.text;
        }

        resultMap.set(sub.index, recoveredText);
        await delay(300);
    }
}

module.exports = {
    translateSrtFile
};