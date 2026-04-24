'use strict';

const CONFIG = {
    model: process.env.OPENAI_MODEL || 'gpt-4.1-mini',
    apiKeyEnvVar: process.env.OPENAI_API_KEY_VAR || 'OPENAI_API_KEY',
    batchSize: 30,
    maxRetries: 3,
    delayMs: 500,
    temperature: 0.1,
    maxOutputTokens: 4000,
    targetLanguage: 'español',
    targetVariant: process.env.TARGET_VARIANT || 'es-ES',
};

module.exports = { CONFIG };
