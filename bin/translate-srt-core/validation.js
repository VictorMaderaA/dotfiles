// validation.js
'use strict';

const { CONFIG } = require('./config');

/**
 * Verifica que el mapa de traducciones contiene exactamente los índices esperados.
 */
function validateBatchIndices(batch, translations) {
    const cleaned = Object.fromEntries(
        Object.entries(translations).filter(([k]) => {
            const n = parseInt(k, 10);
            return !isNaN(n) && String(n) === k.trim();
        })
    );

    const expected = new Set(batch.map(s => String(s.index)));
    const received = new Set(Object.keys(cleaned));

    const missing = [...expected].filter(k => !received.has(k)).map(Number);
    const extra = [...received].filter(k => !expected.has(k)).map(Number);

    return { valid: missing.length === 0 && extra.length === 0, missing, extra, cleaned };
}

/**
 * Heurística de validación de longitud.
 */
function validateSubtitleText(original, translated) {
    if (!translated || translated.trim().length === 0) {
        return { ok: false, reason: 'vacío' };
    }
    const ratio = translated.length / Math.max(original.length, 1);
    if (ratio > CONFIG.maxRatioExpansion) {
        return { ok: false, reason: `expansión excesiva (${ratio.toFixed(1)}x)` };
    }
    if (original.trim().length > 3 && ratio < CONFIG.minRatioExpansion) {
        return { ok: false, reason: `contracción excesiva (${ratio.toFixed(1)}x)` };
    }
    // ¿El texto quedó sin traducir?
    // Fix: excluir de la comprobación si el texto es corto o no contiene letras
    const hasTranslatableContent = /[a-zA-Z]{3,}/.test(original.trim());
    const normalize = t => t.trim().replace(/\s+/g, ' ');
    if (hasTranslatableContent && normalize(translated) === normalize(original)) {
        return { ok: false, reason: 'texto idéntico al original (sin traducir)' };
    }
    // ¿Placeholder sin restaurar?
    if (/__T\d+__/.test(translated)) {
        return { ok: false, reason: 'placeholder __Tn__ sin restaurar' };
    }
    return { ok: true };
}

module.exports = {
    validateBatchIndices,
    validateSubtitleText
};