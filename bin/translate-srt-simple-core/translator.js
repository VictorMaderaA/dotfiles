'use strict';

const { CONFIG } = require('./config');
const { callOpenAI } = require('./openai-client');

const delay = ms => new Promise(r => setTimeout(r, ms));

const SYSTEM_PROMPT = `Eres un traductor profesional de subtítulos al ${CONFIG.targetLanguage} (${CONFIG.targetVariant}).

REGLAS:
1. Traduce cada subtítulo de forma natural y fluida.
2. Conserva el mismo número de índices recibidos — ni más, ni menos.
3. Usa signos de apertura españoles (¿, ¡).
4. Máximo ~42 caracteres por línea. Usa \\n para dividir líneas largas.
5. No inventes contenido que no esté en el original.
6. Usa contracciones naturales: "del", "al".
7. Evita calcos del inglés.

FORMATO DE RESPUESTA — solo JSON válido, sin markdown:
{ "translations": { "<índice>": "texto traducido", ... } }`;

async function translateBatch(batch, retries = CONFIG.maxRetries) {
    const input = batch.map(s => `${s.index}: ${s.text}`).join('\n');
    const indices = batch.map(s => s.index).join(', ');
    const userPrompt = `Traduce estos ${batch.length} subtítulos (índices: ${indices}):\n\n${input}`;

    for (let attempt = 1; attempt <= retries; attempt++) {
        try {
            const raw = await callOpenAI([
                { role: 'system', content: SYSTEM_PROMPT },
                { role: 'user', content: userPrompt },
            ]);
            const parsed = JSON.parse(raw);
            const translations = parsed.translations ?? {};

            // Verificar que tenemos todos los índices
            const missing = batch.filter(s => !translations[String(s.index)]);
            if (missing.length === 0) return translations;

            console.warn(` ⚠️ Intento ${attempt}: faltan ${missing.length} índices, reintentando...`);
        } catch (err) {
            console.warn(` ⚠️ Intento ${attempt}: ${err.message}`);
        }
        if (attempt < retries) await delay(1000 * attempt);
    }
    return null;
}

async function translateSubtitles(subtitles) {
    const results = new Map();
    const batches = [];

    for (let i = 0; i < subtitles.length; i += CONFIG.batchSize) {
        batches.push(subtitles.slice(i, i + CONFIG.batchSize));
    }

    console.log(`📦 ${batches.length} lotes (${subtitles.length} subtítulos)\n`);

    for (let i = 0; i < batches.length; i++) {
        const batch = batches[i];
        const range = `${batch[0].index}–${batch.at(-1).index}`;
        process.stdout.write(`🔄 Lote ${i + 1}/${batches.length} (subs ${range})... `);

        const translations = await translateBatch(batch);

        if (translations) {
            for (const sub of batch) {
                results.set(sub.index, translations[String(sub.index)] ?? sub.text);
            }
            console.log('✅');
        } else {
            console.log('❌ fallback al original');
            for (const sub of batch) results.set(sub.index, sub.text);
        }

        if (i < batches.length - 1) await delay(CONFIG.delayMs);
    }

    return subtitles.map(s => ({
        index: s.index,
        timestamp: s.timestamp,
        text: results.get(s.index),
    }));
}

module.exports = { translateSubtitles };
