#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const { CONFIG } = require('./config');
const { parseSRT, buildSRT } = require('./srt-io');
const { translateSubtitles } = require('./translator');
const { isVideoFile, extractSubsFromVideo } = require('./extract-subs');
const { cleanSubtitles, restoreStyle } = require('./clean-subs');

function printUsage() {
    console.error(`
Uso:
  translate-srt-simple <entrada.srt|video.mkv> [salida.srt] [--no-clean]

Ejemplos:
  translate-srt-simple video.srt                → video.es.srt
  translate-srt-simple video.srt video.spa.srt
  translate-srt-simple pelicula.mkv             → extrae subs, traduce a .es.srt

Limpieza previa (desactivable con --no-clean): elimina frames de efectos/karaoke,
quita tags ASS y conserva posición ({\\anN}) y cursiva.

Formatos de video soportados: mkv, mp4, avi, webm, ts, m2ts, mov, wmv

Variables de entorno:
  OPENAI_API_KEY   → Clave de la API de OpenAI (requerida)
  OPENAI_MODEL     → Modelo (por defecto: gpt-4.1-mini)
  TARGET_VARIANT   → Variante: es-ES, es-MX, etc. (por defecto: es-ES)
`);
}

async function main() {
    const args = process.argv.slice(2);
    const noClean = args.includes('--no-clean');
    const [inputFile, outputArg] = args.filter(a => a !== '--no-clean');

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

    let subtitles = parseSRT(fs.readFileSync(srtFile, 'utf-8'));
    let styleMeta = null;
    if (!noClean && subtitles.length) {
        const { subs, meta, stats } = cleanSubtitles(subtitles);
        console.log(`🧹 Limpieza: ${stats.input} → ${stats.output} (fusionados ${stats.merged}, efectos ${stats.effects}, dibujos ${stats.drawings}, vacíos ${stats.empty})`);
        subtitles = subs;
        styleMeta = meta;
    }
    if (!subtitles.length) { console.error('❌ No se encontraron subtítulos válidos.'); process.exit(1); }

    console.log(`📄 ${subtitles.length} subtítulos: ${path.basename(srtFile)}`);
    console.log(`🤖 Modelo: ${CONFIG.model} | Destino: ${CONFIG.targetVariant}\n`);

    let translated = await translateSubtitles(subtitles);
    if (styleMeta) translated = restoreStyle(translated, styleMeta);
    fs.writeFileSync(outputFile, buildSRT(translated), 'utf-8');
    console.log(`\n✅ Traducción completada → ${outputFile}`);
}

main().catch(err => { console.error(`\n❌ Error fatal: ${err.message}`); process.exit(1); });
