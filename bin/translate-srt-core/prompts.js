// prompts.js
'use strict';

const {CONFIG} = require('./config');
const {callOpenAI} = require('./openai-client');

/**
 * Extrae glosario y metadatos de una muestra.
 */
async function extractGlossary(subtitles) {
    const total = subtitles.length;
    const seen = new Set();
    const indices = [
        ...subtitles.slice(0, 30),
        ...subtitles.slice(Math.floor(total * 0.4), Math.floor(total * 0.4) + 25),
        ...subtitles.slice(Math.floor(total * 0.75), Math.floor(total * 0.75) + 25),
    ]
        .filter(s => !seen.has(s.index) && seen.add(s.index));
    const sample = indices.map(s => s.text).join(' ');

    const system = `Eres un asistente de localización. Analiza el fragmento y devuelve SOLO este JSON:

"glossary": [{ "original": "term", "spanish": "traducción", "note": "contexto breve" }],
"contentType": "documentary|series|interview|tutorial|podcast|other",
"register": "formal|informal|mixed"

Incluye únicamente: nombres propios (personas, lugares, marcas), jerga temática, términos técnicos.
Máximo 30 términos. Si no hay términos relevantes, devuelve "glossary": [].`;

    try {
        const raw = await callOpenAI(
            [
                {role: 'system', content: system},
                {role: 'user', content: `Transcripción:\n${sample}`}
            ],
            {jsonObject: true, temperature: 0.1}
        );
        const data = JSON.parse(raw);
        return {
            glossary: Array.isArray(data.glossary) ? data.glossary : [],
            contentType: data.contentType ?? 'other',
            register: data.register ?? 'mixed'
        };
    } catch (err) {
        console.warn(`⚠️ No se pudo extraer glosario: ${err.message}`);
        return {glossary: [], contentType: 'other', register: 'mixed'};
    }
}

/**
 * Prompt de sistema estático para toda la sesión.
 */
function buildSystemPrompt(meta, speakerMap = new Map()) {
    const glossarySection = meta.glossary.length
        ? `\nGLOSARIO OBLIGATORIO — respeta estos términos en toda la traducción:\n` +
        meta.glossary
            .map(t => ` • "${t.original}" → "${t.spanish}"${t.note ? ` (${t.note})` : ''}`)
            .join('\n') + '\n'
        : '';

    const speakerSection = speakerMap.size > 0
        ? `\nHABLANTES IDENTIFICADOS:\n` +
        [...speakerMap.entries()]
            .map(([id, label]) => ` ${label} = ${id}`)
            .join('\n') +
        `\nUsa estas etiquetas para mantener coherencia de género gramatical y tono por personaje a lo largo de toda la traducción.\n`
        : '';

    const registerNote =
        meta.register === 'informal'
            ? 'usa "tú", lenguaje coloquial y natural'
            : meta.register === 'formal'
                ? 'usa "usted", lenguaje cuidado y profesional'
                : 'adapta el tratamiento según el hablante y la situación';

    return `Eres un traductor y post-editor profesional de subtítulos, especializado en localización al ${CONFIG.targetLanguage} (${CONFIG.targetVariant}).

TIPO DE CONTENIDO: ${meta.contentType} | REGISTRO: ${meta.register}
${glossarySection}${speakerSection}
━━━ REGLAS ESTRICTAS ━━━
1. Traduce ÚNICAMENTE el bloque <TRADUCIR>. El bloque <CONTEXTO> es solo referencia — JAMÁS incluyas su contenido en la salida.
2. Corrige errores de transcripción ASR (Whisper / AssemblyAI): palabras partidas o fusionadas, homófonos incorrectos, puntuación ausente, frases cortadas, alucinaciones.
3. Registro: ${registerNote}.
4. Infiere y respeta el género gramatical de cada hablante cuando el contexto lo permita. Si un hablante tiene etiqueta (A, B…), mantén coherencia de género para esa etiqueta en todo el archivo.
5. Longitud de línea: máximo ~42 caracteres. Usa \\n para dividir líneas largas.
6. Conserva los placeholders __T0__, __T1__… exactamente donde aparecen. No los traduzcas ni los muevas.
7. Devuelve EXACTAMENTE los mismos índices numéricos recibidos, ni uno más, ni uno menos.
8. PROHIBIDO inventar, inferir o completar contenido que no esté explícitamente en <TRADUCIR>.
9. En la salida, ELIMINA las etiquetas de hablante (A:, B:…). El SRT final no debe contenerlas.
10. Si un bloque contiene dos hablantes distintos, sepáralos así: "— frase hablante 1\\n— frase hablante 2".
11. Usa signos de apertura españoles (¿, ¡) en preguntas y exclamaciones.
12. Evita calcos del inglés: usa expresiones idiomáticas naturales en español.
13. Evita gerundios encadenados (ej: 'estaba siendo llevado' → 'lo llevaban').
14. Normaliza comillas: usa «» en lugar de \\"\\" para citas largas.
15. Usa contracciones naturales del español: 'del' en vez de 'de el', 'al' en vez de 'a el'.

━━━ FORMATO DE RESPUESTA ━━━
Responde SOLO con JSON válido, sin texto adicional, sin markdown:
{ "translations": { "<índice>": "texto traducido", ... } }

━━━ EJEMPLO ━━━
Entrada:

<TRADUCIR>
42: A: Yeah.
43: A: How did you stand there so calm? Oh, my gosh.
44: B: Now it's your turn. I'm going in. __T0__
</TRADUCIR>

Salida esperada:
{ "translations": { "42": "Sí.", "43": "¿Cómo pudiste quedarte tan tranquilo?\\nDios mío.", "44": "Ahora te toca. Voy a entrar. __T0__" } }`;
}

/**
 * Prompt de usuario para lote (incluye contexto previo y STOP).
 */
function buildUserPrompt(batch, context) {
    const expectedIndices = batch.map(s => s.index).join(', ');
    // En buildUserPrompt, cambiar el formato del bloque CONTEXTO:
    const ctxBlock = context.length
        ? `<CONTEXTO>\n${context.map(s =>
            `${s.index} [orig]: ${s.text}\n${s.index} [trad]: ${s.translatedText}`
        ).join('\n')}\n</CONTEXTO>\n\n`
        : '';

    const inputBlock = batch.map(s => `${s.index}: ${s.protectedText}`).join('\n');
    const first = batch.at(0).index;
    const last = batch.at(-1).index;

    return `${ctxBlock}<TRADUCIR>
${inputBlock}
</TRADUCIR>

TRADUCIR EXACTAMENTE ESTOS ${batch.length} ÍNDICES (del ${first} al ${last}): ${expectedIndices}
STOP: no incluyas índices anteriores al ${first} ni posteriores al ${last}.`;
}

/**
 * Prompt de usuario para traducción individual.
 */
function buildSinglePrompt(sub) {
    return `Traduce SOLO este subtítulo al ${CONFIG.targetLanguage} (${CONFIG.targetVariant}).
Devuelve únicamente JSON, sin texto extra.

<TRADUCIR>
${sub.index}: ${sub.protectedText}
</TRADUCIR>`;
}

module.exports = {
    extractGlossary,
    buildSystemPrompt,
    buildUserPrompt,
    buildSinglePrompt
};