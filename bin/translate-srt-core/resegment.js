// resegment.js
'use strict';

const fs = require('fs');

// Estándares profesionales (compatibles con Netflix / BBC guidelines)
const STANDARDS = {
    maxCPS: 17,            // caracteres por segundo (Netflix: 17)
    minDurationSec: 0.5,   // duración mínima por subtítulo
    maxDurationSec: 7.0,   // duración máxima por subtítulo
    maxLineChars: 42,      // máx chars por línea
    maxLines: 2,           // máx líneas por subtítulo
    minPauseSec: 0.4,      // pausa entre palabras que fuerza corte
};

// ─────────────────────────────────────────────────────────────────────────────
// Parsing del JSON de WhisperX
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Carga el JSON de WhisperX y extrae un array plano de palabras con timestamps.
 * Soporta el formato CLI (word_segments raíz) y el formato Python (words dentro de segments).
 *
 * @param {string} jsonPath
 * @returns {{ words: WordEntry[], hasWordTimestamps: boolean }}
 *
 * @typedef {{ word: string, start: number, end: number, speaker: string|null }} WordEntry
 */
function loadWhisperXJson(jsonPath) {
    if (!fs.existsSync(jsonPath)) {
        throw new Error(`JSON de WhisperX no encontrado: ${jsonPath}`);
    }

    const raw = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
    let words = [];
    let hasWordTimestamps = false;

    // Formato CLI: word_segments en raíz (con speaker si hay diarización)
    if (Array.isArray(raw.word_segments) && raw.word_segments.length > 0) {
        words = raw.word_segments
            .filter(w => typeof w.start === 'number' && typeof w.end === 'number')
            .map(w => ({
                word: (w.word ?? '').trim(),
                start: w.start,
                end: w.end,
                speaker: w.speaker ?? null,
            }));
        hasWordTimestamps = words.length > 0;
    }

    // Fallback: extraer words de dentro de cada segment
    if (words.length === 0 && Array.isArray(raw.segments)) {
        for (const seg of raw.segments) {
            const segSpeaker = seg.speaker ?? null;

            if (Array.isArray(seg.words) && seg.words.length > 0) {
                for (const w of seg.words) {
                    // Algunos tokens (números, etc.) pueden no tener timestamps [issue #1115]
                    if (typeof w.start !== 'number' || typeof w.end !== 'number') continue;
                    words.push({
                        word: (w.word ?? '').trim(),
                        start: w.start,
                        end: w.end,
                        speaker: w.speaker ?? segSpeaker,
                    });
                }
                hasWordTimestamps = true;
            } else {
                // Sin word timestamps: usar el segmento como unidad atómica
                words.push({
                    word: (seg.text ?? '').trim(),
                    start: seg.start,
                    end: seg.end,
                    speaker: segSpeaker,
                    isSegment: true,
                });
            }
        }
    }

    if (words.length === 0) {
        throw new Error('El JSON de WhisperX no contiene palabras ni segmentos válidos.');
    }

    return { words, hasWordTimestamps };
}

// ─────────────────────────────────────────────────────────────────────────────
// Construcción de bloques
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Decide si debe abrirse un nuevo bloque ANTES de la palabra en posición `idx`.
 */
function shouldSplitBefore(words, idx, currentText, blockStart) {
    if (idx === 0 || currentText.length === 0) return false;

    const prev = words[idx - 1];
    const curr = words[idx];

    // Cambio de hablante → corte siempre
    if (prev.speaker && curr.speaker && prev.speaker !== curr.speaker) return true;

    // Pausa larga entre palabras
    const pause = curr.start - prev.end;
    if (pause >= STANDARDS.minPauseSec) return true;

    // Texto acumulado excedería el máximo (2 líneas × 42 chars)
    const projected = (currentText + ' ' + curr.word).trim();
    if (projected.length > STANDARDS.maxLineChars * STANDARDS.maxLines) return true;

    // Duración excedería el máximo
    if (curr.end - blockStart > STANDARDS.maxDurationSec) return true;

    // Fin de frase con contenido suficiente → corte natural
    const prevWord = prev.word.trim();
    if (/[.!?]$/.test(prevWord) && currentText.length > 20) return true;

    return false;
}

/**
 * Divide texto en máximo 2 líneas de ~42 chars, buscando el corte natural más cercano
 * al punto medio.
 */
function formatSubtitleText(text) {
    const clean = text.trim().replace(/\s+/g, ' ');
    if (clean.length <= STANDARDS.maxLineChars) return clean;

    const mid = Math.floor(clean.length / 2);
    let left = mid;
    let right = mid;

    while (left > 0 || right < clean.length) {
        if (left > 0 && clean[left] === ' ') {
            return `${clean.slice(0, left).trim()}\n${clean.slice(left).trim()}`;
        }
        if (right < clean.length && clean[right] === ' ') {
            return `${clean.slice(0, right).trim()}\n${clean.slice(right).trim()}`;
        }
        left--;
        right++;
    }

    // Forzar corte duro si no hay espacio (raro)
    return `${clean.slice(0, STANDARDS.maxLineChars)}\n${clean.slice(STANDARDS.maxLineChars)}`;
}

/**
 * Construye bloques de subtítulo a partir de palabras con timestamps.
 */
function buildBlocksFromWords(words) {
    const blocks = [];
    let buffer = [];
    let blockStart = null;

    for (let i = 0; i < words.length; i++) {
        const word = words[i];
        const currentText = buffer.map(w => w.word).join(' ').trim();

        if (buffer.length > 0 && shouldSplitBefore(words, i, currentText, blockStart)) {
            blocks.push({
                start: blockStart,
                end: words[i - 1].end,
                text: formatSubtitleText(currentText),
                speaker: buffer[0].speaker ?? null,
            });
            buffer = [];
            blockStart = null;
        }

        if (buffer.length === 0) blockStart = word.start;
        buffer.push(word);
    }

    // Emitir último bloque
    if (buffer.length > 0) {
        const text = buffer.map(w => w.word).join(' ').trim();
        blocks.push({
            start: blockStart,
            end: buffer.at(-1).end,
            text: formatSubtitleText(text),
            speaker: buffer[0].speaker ?? null,
        });
    }

    return blocks;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de timestamps
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Segundos → timestamp SRT  (HH:MM:SS,mmm)
 * @param {number} seconds
 * @returns {string}
 */
function formatTimestamp(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);
    const ms = Math.round((seconds % 1) * 1000);
    return [
        String(h).padStart(2, '0'),
        String(m).padStart(2, '0'),
        String(s).padStart(2, '0'),
    ].join(':') + ',' + String(ms).padStart(3, '0');
}

/**
 * Timestamp SRT → segundos
 * @param {string} ts
 * @returns {number}
 */
function parseTimestamp(ts) {
    const [hm, rest] = ts.trim().split(/,/);
    const parts = hm.split(':').map(Number);
    const ms = parseInt(rest, 10) / 1000;
    return parts[0] * 3600 + parts[1] * 60 + parts[2] + ms;
}

// ─────────────────────────────────────────────────────────────────────────────
// Estadísticas de calidad
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Calcula métricas de calidad sobre el array de subtítulos resegmentados.
 */
function computeStats(subtitles) {
    const durations = subtitles.map(s => {
        const [startTs, endTs] = s.timestamp.split(' --> ');
        return parseTimestamp(endTs) - parseTimestamp(startTs);
    });

    const cpsList = subtitles.map((s, i) => {
        const charCount = s.text.replace(/\n/g, '').length;
        return charCount / Math.max(durations[i], 0.1);
    });

    return {
        totalSubtitles: subtitles.length,
        avgDurationSec: (durations.reduce((a, b) => a + b, 0) / durations.length).toFixed(2),
        maxDurationSec: Math.max(...durations).toFixed(2),
        avgCPS: (cpsList.reduce((a, b) => a + b, 0) / cpsList.length).toFixed(1),
        maxCPS: Math.max(...cpsList).toFixed(1),
        aboveMaxCPS: cpsList.filter(c => c > STANDARDS.maxCPS).length,
    };
}

// ─────────────────────────────────────────────────────────────────────────────
// API pública
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Resegmenta un único bloque SRT usando las palabras del JSON que caen dentro
 * de su ventana temporal. Nunca produce timestamps fuera del intervalo original.
 *
 * @param {object}      originalSub  - { index, timestamp, text }
 * @param {WordEntry[]} allWords     - Array plano de palabras del JSON
 * @param {number}      margin       - Tolerancia en segundos al buscar palabras
 * @returns {object[]}               - Uno o más bloques con timestamps refinados
 */
function resegmentBlock(originalSub, allWords, margin = 0.4) {
    const [startTs, endTs] = originalSub.timestamp.split(' --> ');
    const origStart = parseTimestamp(startTs);
    const origEnd   = parseTimestamp(endTs);

    const winStart = Math.max(0, origStart - margin);
    const winEnd   = origEnd + margin;

    const words = allWords.filter(w =>
        typeof w.start === 'number' &&
        typeof w.end   === 'number' &&
        w.start >= winStart &&
        w.end   <= winEnd
    );

    // Sin palabras en la ventana → conservar bloque original sin cambios
    if (words.length === 0) return [{ ...originalSub }];

    // Detección de deriva: si el centro de las palabras se aleja >1 s del centro del bloque
    const wordsCenter = (words[0].start + words.at(-1).end) / 2;
    const origCenter  = (origStart + origEnd) / 2;
    if (Math.abs(wordsCenter - origCenter) > 1.0) {
        return [{ ...originalSub }];
    }

    const rawBlocks = buildBlocksFromWords(words);

    // Si no hay ganancia real, conservar original
    if (rawBlocks.length <= 1 && words.length < 3) return [{ ...originalSub }];

    return rawBlocks.map((block, i) => {
        // Clamp: el primer sub-bloque no puede empezar antes del bloque original,
        // el último no puede acabar después
        const clampedStart = i === 0
            ? Math.max(block.start, origStart)
            : block.start;
        const clampedEnd = i === rawBlocks.length - 1
            ? Math.min(block.end, origEnd)
            : block.end;

        return {
            index: originalSub.index, // se reasigna en el paso final
            timestamp: `${formatTimestamp(clampedStart)} --> ${formatTimestamp(clampedEnd)}`,
            text: block.speaker ? `[${block.speaker}]: ${block.text}` : block.text,
        };
    });
}

/**
 * Genera subtítulos resegmentados usando el JSON de WhisperX como guía,
 * pero anclando siempre los timestamps a los bloques del SRT original.
 *
 * @param {string}   jsonPath     - Ruta al .json de WhisperX
 * @param {object[]} originalSubs - Array de subtítulos del SRT original (fuente de verdad temporal)
 * @returns {{ subtitles: object[], stats: object, hasWordTimestamps: boolean }}
 */
function resegmentFromJson(jsonPath, originalSubs) {
    const { words, hasWordTimestamps } = loadWhisperXJson(jsonPath);

    if (words.length === 0) {
        throw new Error('El JSON de WhisperX no contiene palabras ni segmentos válidos.');
    }

    // Resegmentar bloque a bloque, respetando los anclajes temporales del SRT original
    const allBlocks = [];
    for (const sub of originalSubs) {
        const blocks = resegmentBlock(sub, words);
        allBlocks.push(...blocks);
    }

    // Reasignar índices secuenciales
    const subtitles = allBlocks.map((block, i) => ({ ...block, index: i + 1 }));

    return {
        subtitles,
        stats: computeStats(subtitles),
        hasWordTimestamps,
    };
}

module.exports = {
    resegmentFromJson,
    formatTimestamp,
    parseTimestamp,
    STANDARDS,
};