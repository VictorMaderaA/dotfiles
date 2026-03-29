// openai-client.js
'use strict';

const https = require('https');
const { CONFIG } = require('./config');

/**
 * Llama a OpenAI /v1/chat/completions.
 * Usa siempre process.env[CONFIG.apiKeyEnvVar] para la API key.
 */
function callOpenAI(messages, opts = {}) {
    return new Promise((resolve, reject) => {
        const apiKey = process.env[CONFIG.apiKeyEnvVar];

        if (!apiKey) {
            return reject(new Error(
                `OPENAI API key no encontrada. Exporta ${CONFIG.apiKeyEnvVar} en tu entorno.\n` +
                '⚠️ NO hardcodees claves en el código; usa variables de entorno.'
            ));
        }

        const body = JSON.stringify({
            model: CONFIG.model,
            messages,
            temperature: opts.temperature ?? 0.2,
            max_tokens: opts.maxTokens ?? CONFIG.maxOutputTokens,
            ...(opts.jsonMode && { response_format: { type: 'json_object' } })
        });

        const req = https.request({
            hostname: 'api.openai.com',
            path: '/v1/chat/completions',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${apiKey}`,
                'Content-Length': Buffer.byteLength(body)
            }
        }, res => {
            let data = '';
            res.on('data', chunk => (data += chunk));
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    if (parsed.error) {
                        return reject(new Error(`OpenAI: ${parsed.error.message}`));
                    }
                    resolve(parsed.choices[0].message.content);
                } catch (err) {
                    reject(new Error(`Respuesta inválida de la API: ${data.slice(0, 300)}`));
                }
            });
        });

        req.on('error', reject);
        req.write(body);
        req.end();
    });
}

module.exports = { callOpenAI };