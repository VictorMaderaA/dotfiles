// batching.js
'use strict';
const { CONFIG } = require('./config');

/**
 * Estimación rápida de tokens: ~1 token cada 4 chars (inglés/español).
 */
function estimateTokens(text) {
    return Math.ceil(text.length / 4);
}

/**
 * Divide subtítulos en lotes adaptativos.
 */
function buildAdaptiveBatches(subtitles, maxTokens = CONFIG.maxTokensPerBatch, maxSubs = CONFIG.maxSubsPerBatch) {    const batches = [];
    let current = [];
    let tokens = 0;
    const effectiveMax = Math.floor(maxTokens * 0.6);

    for (const sub of subtitles) {
        const subTokens = estimateTokens(`${sub.index}: ${sub.protectedText}\n`);
        const tokensFull = tokens + subTokens > effectiveMax;
        const subsFull = current.length >= maxSubs;

        if (current.length > 0 && (tokensFull || subsFull)) {
            batches.push(current);
            current = [];
            tokens = 0;
        }

        current.push(sub);
        tokens += subTokens;
    }

    if (current.length > 0) batches.push(current);
    return batches;
}

module.exports = {
    estimateTokens,
    buildAdaptiveBatches
};