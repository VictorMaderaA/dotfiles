'use strict';

const https = require('https');
const { CONFIG } = require('./config');

function callOpenAI(messages, opts = {}) {
    return new Promise((resolve, reject) => {
        const apiKey = process.env[CONFIG.apiKeyEnvVar];
        if (!apiKey) {
            return reject(new Error(`API key no encontrada. Exporta ${CONFIG.apiKeyEnvVar}.`));
        }

        const body = JSON.stringify({
            model: CONFIG.model,
            messages,
            temperature: opts.temperature ?? CONFIG.temperature,
            max_tokens: opts.maxTokens ?? CONFIG.maxOutputTokens,
            response_format: { type: 'json_object' },
        });

        const req = https.request({
            hostname: 'api.openai.com',
            path: '/v1/chat/completions',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${apiKey}`,
                'Content-Length': Buffer.byteLength(body),
            },
        }, res => {
            let data = '';
            res.on('data', chunk => (data += chunk));
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    if (parsed.error) return reject(new Error(`OpenAI: ${parsed.error.message}`));
                    resolve(parsed.choices[0].message.content);
                } catch {
                    reject(new Error(`Respuesta inválida: ${data.slice(0, 300)}`));
                }
            });
        });

        req.on('error', reject);
        req.write(body);
        req.end();
    });
}

module.exports = { callOpenAI };
