#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const { CONFIG } = require('./config');
const { parseSRT, buildSRT } = require('./srt-io');
const { translateSubtitles } = require('./translator');
const { isVideoFile, extractSubsFromVideo } = require('./extract-subs');

function printUsage() {
    console.error(`
Uso:
  translate-srt-simple <entrada.srt|video.mkv> [salida.srt]

Ejemplos:
  translate-srt-simple video.srt                → video.es.srt
  translate-srt-simple video.srt video.spa.srt
  translate-srt-simple pelicula.mkv             → extrae subs, traduce a .es.srt

Formatos de video soportados: mkv, mp4, avi, webm, ts, m2ts, mov, wmv

Variables de entorno:
  OPENAI_API_KEY   → Clave de la API de OpenAI (requerida)
  OPENAI_MODEL     → Modelo (por defecto: gpt-4.1-mini)
  TARGET_VARIANT   → Variante: es-ES, es-MX, etc. (por defecto: es-ES)
`);
}

async function main() {
    const [inputFile, outputArg] = process.argv.slice(2);

    if (!inputFile) { printUsage(); process.exit(1); }
    if (!fs.existsSync(inputFile)) { console.error(`❌ No encontrado: ${inputFile}`); process.exit(1); }

    // Si es video, extraer subtítulos primero
    let srtFile = inputFile;
    if (isVideoFile(inputFile)) {
        srtFile = await extractSubsFromVideo(inputFile);
    }

    const outputFile = outputArg ?? srtFile.replace(/\.srt$/i, '.es.srt');

    if (path.resolve(outputFile) === path.resolve(srtFile)) {
        console.error('❌ El archivo de salida no puede ser el mismo que el de entrada.');
        process.exit(1);
    }

    const subtitles = parseSRT(fs.readFileSync(srtFile, 'utf-8'));
    if (!subtitles.length) { console.error('❌ No se encontraron subtítulos válidos.'); process.exit(1); }

    console.log(`📄 ${subtitles.length} subtítulos: ${path.basename(srtFile)}`);
    console.log(`🤖 Modelo: ${CONFIG.model} | Destino: ${CONFIG.targetVariant}\n`);

    const translated = await translateSubtitles(subtitles);
    fs.writeFileSync(outputFile, buildSRT(translated), 'utf-8');
    console.log(`\n✅ Traducción completada → ${outputFile}`);
}

main().catch(err => { console.error(`\n❌ Error fatal: ${err.message}`); process.exit(1); });
