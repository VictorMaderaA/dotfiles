// srt-io.js
'use strict';

/**
 * Parsea contenido SRT en array de objetos subtítulo.
 * @param {string} raw
 * @returns {{ index: number, timestamp: string, text: string }[]}
 */
function parseSRT(raw) {
    const content = raw
        .replace(/\r\n/g, '\n')
        .replace(/\r/g, '\n');

    return content
        .trim()
        .split(/\n\n+/)
        .reduce((acc, block) => {
            const lines = block.trim().split('\n');
            if (lines.length < 3) return acc;
            const index = parseInt(lines[0], 10);
            if (isNaN(index)) return acc;
            acc.push({
                index,
                timestamp: lines[1].trim(),
                text: lines.slice(2).join('\n').trim()
            });
            return acc;
        }, []);
}

/**
 * Serializa array de subtítulos a string SRT válido.
 * @param {{ index: number, timestamp: string, text: string }[]} subs
 * @returns {string}
 */
function buildSRT(subs) {
    return subs
        .map(s => `${s.index}\n${s.timestamp}\n${postProcessText(s.text)}`)
        .join('\n\n') + '\n';
}

function postProcessText(text) {
    return text
        .replace(/\.\.\./g, '…')          // elipsis tipográfica
        .replace(/  +/g, ' ')              // espacios dobles
        .replace(/\?{2,}/g, '?')           // colapsa ?? → ?
        .replace(/!{2,}/g, '!')            // colapsa !! → !
        .replace(/^([—–]\s*)/gm, '— ')    // normalizar guión de diálogo
        .replace(/\n{2,}/g, '\n')   // colapsar saltos dobles dentro del texto
        .trim();
}
module.exports = { parseSRT, buildSRT };