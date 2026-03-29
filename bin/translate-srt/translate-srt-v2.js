#!/usr/bin/env node
// translate-srt-v2.js
'use strict';

const path = require('path');
const fs = require('fs');
const { translateSrtFile } = require('./pipeline');

async function main() {
    const [, , inputFile, outputArg] = process.argv;

    if (!inputFile) {
        console.error('\nUso: translate-srt-v2 <entrada.srt> [salida.srt]\n');
        process.exit(1);
    }

    if (!fs.existsSync(inputFile)) {
        console.error(`❌ Archivo no encontrado: ${inputFile}`);
        process.exit(1);
    }

    const outputFile =
        outputArg ||
        inputFile.replace(/\.srt$/i, '.es.srt') ||
        `${path.basename(inputFile, path.extname(inputFile))}.es.srt`;

    try {
        await translateSrtFile(inputFile, outputFile);
    } catch (err) {
        console.error('\n❌ Error fatal:', err.message);
        process.exit(1);
    }
}

main();