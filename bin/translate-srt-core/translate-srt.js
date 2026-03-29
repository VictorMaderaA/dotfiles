#!/usr/bin/env node
// translate-srt-v2.js
'use strict';

const path = require('path');
const fs = require('fs');
const { translateSrtFile } = require('./pipeline');

function printUsage() {
    console.error(`
Uso:
  translate-srt-v2 <entrada.srt> [salida.srt] [--json whisperx.json]

Ejemplos:
  translate-srt-v2 video.srt
  translate-srt-v2 video.srt video.es.srt
  translate-srt-v2 video.srt --json video.json
  translate-srt-v2 video.srt video.es.srt --json video.json

Variables de entorno requeridas:
  OPENAI_API_KEY   → Clave de la API de OpenAI

Opcionales:
  OPENAI_MODEL     → Modelo a usar (por defecto: gpt-4o-mini)
  TARGET_VARIANT   → Variante de español: es-ES, es-MX, etc. (por defecto: es-ES)
`);
}

async function main() {
    const args = process.argv.slice(2);

    // Extraer --json <path> antes de procesar el resto
    let jsonPath = null;
    const jsonFlagIdx = args.indexOf('--json');
    if (jsonFlagIdx !== -1) {
        jsonPath = args[jsonFlagIdx + 1] ?? null;
        if (!jsonPath || jsonPath.startsWith('--')) {
            console.error('❌ --json requiere una ruta de archivo como argumento.');
            process.exit(1);
        }
        args.splice(jsonFlagIdx, 2);
    }

    const [inputFile, outputArg] = args;

    if (!inputFile) {
        printUsage();
        process.exit(1);
    }

    if (!fs.existsSync(inputFile)) {
        console.error(`❌ Archivo SRT no encontrado: ${inputFile}`);
        process.exit(1);
    }

    if (jsonPath && !fs.existsSync(jsonPath)) {
        console.error(`❌ Archivo JSON no encontrado: ${jsonPath}`);
        process.exit(1);
    }

    const outputFile =
        outputArg ??
        inputFile.replace(/\.srt$/i, '.es.srt');

    try {
        await translateSrtFile(inputFile, outputFile, jsonPath);
    } catch (err) {
        console.error('\n❌ Error fatal:', err.message);
        process.exit(1);
    }
}

main();