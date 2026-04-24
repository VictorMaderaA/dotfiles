'use strict';

function parseSRT(raw) {
    return raw.replace(/\r\n/g, '\n').replace(/\r/g, '\n')
        .trim().split(/\n\n+/)
        .reduce((acc, block) => {
            const lines = block.trim().split('\n');
            if (lines.length < 3) return acc;
            const index = parseInt(lines[0], 10);
            if (isNaN(index)) return acc;
            acc.push({ index, timestamp: lines[1].trim(), text: lines.slice(2).join('\n').trim() });
            return acc;
        }, []);
}

function buildSRT(subs) {
    return subs.map(s => `${s.index}\n${s.timestamp}\n${s.text}`).join('\n\n') + '\n';
}

module.exports = { parseSRT, buildSRT };
