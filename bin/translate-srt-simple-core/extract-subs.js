'use strict';

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const VIDEO_EXTS = new Set(['.mkv', '.mp4', '.avi', '.webm', '.ts', '.m2ts', '.mov', '.wmv']);

function isVideoFile(filePath) {
    return VIDEO_EXTS.has(path.extname(filePath).toLowerCase());
}

// ── Nombres legibles para códecs y idiomas ──────────────────────────────────

const CODEC_NAMES = {
    subrip: 'SRT (texto)',
    ass: 'ASS/SSA (texto con estilos)',
    ssa: 'SSA (texto con estilos)',
    mov_text: 'MP4 texto (mov_text)',
    webvtt: 'WebVTT (texto)',
    hdmv_pgs_subtitle: 'PGS (imagen — Blu-ray)',
    dvd_subtitle: 'VobSub (imagen — DVD)',
    dvb_subtitle: 'DVB (imagen — TV digital)',
    xsub: 'XSUB (imagen)',
};

const LANG_NAMES = {
    eng: 'Inglés', en: 'Inglés',
    spa: 'Español', es: 'Español',
    fre: 'Francés', fra: 'Francés', fr: 'Francés',
    ger: 'Alemán', deu: 'Alemán', de: 'Alemán',
    ita: 'Italiano', it: 'Italiano',
    por: 'Portugués', pt: 'Portugués',
    jpn: 'Japonés', ja: 'Japonés',
    kor: 'Coreano', ko: 'Coreano',
    chi: 'Chino', zho: 'Chino', zh: 'Chino',
    rus: 'Ruso', ru: 'Ruso',
    ara: 'Árabe', ar: 'Árabe',
    hin: 'Hindi', hi: 'Hindi',
    und: 'Desconocido',
};

function humanCodec(codec) {
    return CODEC_NAMES[codec] || codec;
}

function humanLang(code) {
    if (!code) return 'Sin idioma';
    return LANG_NAMES[code] || code.toUpperCase();
}

function isTextCodec(codec) {
    return ['subrip', 'ass', 'ssa', 'mov_text', 'webvtt'].includes(codec);
}

// ── ffprobe: obtener pistas de subtítulos ───────────────────────────────────

const MAX_PROBE_RETRIES = 3;

function probeSubtitleTracks(videoPath) {
    for (let attempt = 1; attempt <= MAX_PROBE_RETRIES; attempt++) {
        try {
            const raw = execFileSync('ffprobe', [
                '-v', 'quiet',
                '-print_format', 'json',
                '-show_streams',
                '-select_streams', 's',
                videoPath,
            ], { encoding: 'utf-8', timeout: 30000 });

            const { streams = [] } = JSON.parse(raw);
            return streams.map((s, i) => ({
                ffIndex: s.index,
                subIndex: i,
                codec: s.codec_name,
                lang: s.tags?.language || null,
                title: s.tags?.title || null,
                forced: s.disposition?.forced === 1,
                defaultTrack: s.disposition?.default === 1,
                isText: isTextCodec(s.codec_name),
            }));
        } catch (err) {
            if (attempt < MAX_PROBE_RETRIES) {
                console.warn(` ⚠️ ffprobe intento ${attempt}/${MAX_PROBE_RETRIES} falló, reintentando...`);
                continue;
            }
            throw new Error(`ffprobe falló tras ${MAX_PROBE_RETRIES} intentos: ${err.message}`);
        }
    }
}

// ── Mostrar pistas de forma legible ─────────────────────────────────────────

function formatTrackList(tracks) {
    return tracks.map((t, i) => {
        const num = `  ${i + 1})`.padEnd(5);
        const lang = humanLang(t.lang);
        const codec = humanCodec(t.codec);
        const flags = [
            t.defaultTrack && '⭐ por defecto',
            t.forced && '🔒 forzado',
            !t.isText && '⚠️ imagen (no extraíble como texto)',
        ].filter(Boolean).join(', ');
        const title = t.title ? ` — "${t.title}"` : '';
        const flagStr = flags ? `  [${flags}]` : '';

        return `${num}${lang} | ${codec}${title}${flagStr}`;
    }).join('\n');
}

// ── Selección interactiva ───────────────────────────────────────────────────

function ask(question) {
    const rl = readline.createInterface({ input: process.stdin, output: process.stderr });
    return new Promise(resolve => {
        rl.question(question, answer => { rl.close(); resolve(answer.trim()); });
    });
}

async function selectTrack(tracks) {
    // Si solo hay una pista de texto, usarla directamente
    const textTracks = tracks.filter(t => t.isText);
    if (textTracks.length === 1) {
        console.log(`\n📌 Única pista de texto encontrada: ${humanLang(textTracks[0].lang)} | ${humanCodec(textTracks[0].codec)}`);
        return textTracks[0];
    }

    console.log(`\n🎬 Pistas de subtítulos encontradas:\n`);
    console.log(formatTrackList(tracks));
    console.log();

    if (textTracks.length === 0) {
        console.error('❌ No hay pistas de subtítulos de texto extraíbles (solo imagen/PGS).');
        process.exit(1);
    }

    while (true) {
        const input = await ask(`Selecciona pista (1-${tracks.length}): `);
        const n = parseInt(input, 10);
        if (n >= 1 && n <= tracks.length) {
            const chosen = tracks[n - 1];
            if (!chosen.isText) {
                console.warn(` ⚠️ La pista ${n} es de imagen (${humanCodec(chosen.codec)}), no se puede extraer como texto. Elige otra.`);
                continue;
            }
            return chosen;
        }
        console.warn(` ⚠️ Opción inválida. Introduce un número entre 1 y ${tracks.length}.`);
    }
}

// ── ffmpeg: extraer subtítulo a SRT ─────────────────────────────────────────

const MAX_EXTRACT_RETRIES = 3;

function extractSubtitle(videoPath, track, outputSrt) {
    for (let attempt = 1; attempt <= MAX_EXTRACT_RETRIES; attempt++) {
        try {
            execFileSync('ffmpeg', [
                '-y', '-v', 'warning',
                '-i', videoPath,
                '-map', `0:${track.ffIndex}`,
                '-c:s', 'srt',
                outputSrt,
            ], { encoding: 'utf-8', timeout: 120000 });

            // Verificar que el archivo se creó y tiene contenido
            if (!fs.existsSync(outputSrt) || fs.statSync(outputSrt).size === 0) {
                throw new Error('Archivo extraído vacío');
            }

            return outputSrt;
        } catch (err) {
            if (fs.existsSync(outputSrt)) fs.unlinkSync(outputSrt);
            if (attempt < MAX_EXTRACT_RETRIES) {
                console.warn(` ⚠️ Extracción intento ${attempt}/${MAX_EXTRACT_RETRIES} falló, reintentando...`);
                continue;
            }
            throw new Error(`Extracción falló tras ${MAX_EXTRACT_RETRIES} intentos: ${err.message}`);
        }
    }
}

// ── API pública ─────────────────────────────────────────────────────────────

/**
 * Extrae subtítulos de un archivo de video.
 * Devuelve la ruta al .srt extraído.
 */
async function extractSubsFromVideo(videoPath) {
    console.log(`\n🔍 Analizando: ${path.basename(videoPath)}`);

    const tracks = probeSubtitleTracks(videoPath);
    if (tracks.length === 0) {
        throw new Error('No se encontraron pistas de subtítulos en el archivo.');
    }

    const track = await selectTrack(tracks);
    const langSuffix = track.lang && track.lang !== 'und' ? `.${track.lang}` : '.extracted';
    const outputSrt = videoPath.replace(/\.[^.]+$/, `${langSuffix}.srt`);

    console.log(`\n📤 Extrayendo: ${humanLang(track.lang)} (${humanCodec(track.codec)}) → ${path.basename(outputSrt)}`);
    extractSubtitle(videoPath, track, outputSrt);
    console.log(`✅ Extraído: ${outputSrt}\n`);

    return outputSrt;
}

module.exports = { isVideoFile, extractSubsFromVideo };
