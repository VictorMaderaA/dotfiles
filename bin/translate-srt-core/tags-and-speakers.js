// tags-and-speakers.js
'use strict';

// [MUSIC], [APPLAUSE], ♪ ... ♪, (laughs), etiquetas HTML, etc.
const TAG_PATTERN = /(\[[^\]]+\]|♪[^♪\n]*♪|♪|\([^)\n]{1,40}\)|<[a-zA-Z/][^>]*>)/g;

// [SPEAKER_06]:, [S1]:, [John]:, SPEAKER 1:
const SPEAKER_TAG_PATTERN = /\[([A-Z_a-z0-9 ]+)\]:\s*/g;

/**
 * Sustituye etiquetas no textuales por placeholders únicos.
 */
function protectTags(text) {
    const map = new Map();
    let counter = 0;
    const result = text.replace(TAG_PATTERN, match => {
        const key = `__T${counter++}__`;
        map.set(key, match);
        return key;
    });
    return { protectedText: result, tagMap: map };
}

/**
 * Restaura placeholders a sus etiquetas originales.
 */
function restoreTags(text, map) {
    let result = text;
    for (const [key, value] of map) {
        result = result.replaceAll(key, value);
    }
    return result;
}

/**
 * Extrae hablantes únicos del archivo y les asigna una letra (A, B, C…).
 */
function buildSpeakerMap(subtitles) {
    const map = new Map();
    const labels = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    for (const sub of subtitles) {
        for (const match of sub.text.matchAll(SPEAKER_TAG_PATTERN)) {
            const id = match[1].trim();
            if (!map.has(id)) {
                map.set(id, labels[map.size] ?? `S${map.size + 1}`);
            }
        }
    }
    return map;
}

/**
 * [SPEAKER_06]: texto → A: texto
 */
function normalizeSpeakerTags(text, speakerMap) {
    return text.replace(SPEAKER_TAG_PATTERN, (_, id) => {
        const label = speakerMap.get(id.trim()) ?? '?';
        return `${label}: `;
    });
}

/**
 * Elimina etiquetas cortas de hablante del texto traducido.
 * A: texto → texto
 */
function stripNormalizedSpeakers(text) {
    return text.replace(/^[A-Z]\s*:\s*/gm, '').trim();
}

module.exports = {
    protectTags,
    restoreTags,
    buildSpeakerMap,
    normalizeSpeakerTags,
    stripNormalizedSpeakers
};