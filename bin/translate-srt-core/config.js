// config.js
'use strict';

/**
 * ⚠️ REPO PÚBLICO / DOTFILES:
 *
 * - NO hardcodees aquí ninguna clave "sk-..." de OpenAI.
 * - La API key se lee SIEMPRE de process.env.OPENAI_API_KEY.
 * - Si en algún momento pegas una clave real en este archivo,
 *   bórrala ANTES de hacer push a tu repo público.
 */

const CONFIG = {
    // Modelo y API
    model: process.env.OPENAI_MODEL || 'gpt-4o',
    apiKeyEnvVar: 'OPENAI_API_KEY',

    // Procesamiento de lotes
    maxTokensPerBatch: 600,
    maxSubsPerBatch: 20,
    contextSize: 10,
    delayMs: 700,
    maxOutputTokens: 2500,
    temperature: 0.1,

    // Reintentos
    maxBatchRetries: 3,
    maxSingleRetries: 2,

    // Validación por subtítulo
    maxRatioExpansion: 3,
    minRatioExpansion: 0.15,

    // Idioma de salida
    targetLanguage: 'español',
    targetVariant: process.env.TARGET_VARIANT || 'es-ES', // p.ej. 'es-ES', 'es-MX'

    // Estricto: si demasiados fallbacks, marcar fallo global
    strictFallbackThreshold: 0.08 // 8% de subs en fallback → error
};

module.exports = { CONFIG };