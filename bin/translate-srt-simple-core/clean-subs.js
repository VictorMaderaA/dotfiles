"use strict";

// Limpieza previa a la traducción de SRT convertidos desde ASS:
// elimina frames de efectos/karaoke, quita tags de estilo y guarda
// posición (\anN) y cursiva para reaplicarlos tras traducir.

const MAX_EFFECT_MS = 100; // bloques más cortos que esto son frames de efecto
const MERGE_GAP_MS = 100; // huecos menores se consideran el mismo rótulo

const TS_RE = /(\d+):(\d+):(\d+)[,.](\d+)\s*-->\s*(\d+):(\d+):(\d+)[,.](\d+)/;

function parseTimestamp(ts) {
  const m = ts.match(TS_RE);
  if (!m) return null;
  const ms = (h, mi, s, f) => ((+h * 60 + +mi) * 60 + +s) * 1000 + +f;
  return { start: ms(m[1], m[2], m[3], m[4]), end: ms(m[5], m[6], m[7], m[8]) };
}

function formatMs(total) {
  const pad = (n, w = 2) => String(n).padStart(w, "0");
  const h = Math.floor(total / 3600000);
  const m = Math.floor(total / 60000) % 60;
  const s = Math.floor(total / 1000) % 60;
  return `${pad(h)}:${pad(m)}:${pad(s)},${pad(total % 1000, 3)}`;
}

function stripStyle(raw) {
  const an = raw.match(/\{\\an([1-9])\}/)?.[1] ?? null;
  const italic = /<i>/i.test(raw);
  const text = raw
    .replace(/\{[^}]*\}/g, "")
    .replace(/<\/?(?:font|b|i|u|s)\b[^>]*>/gi, "")
    .replace(/\\N/g, "\n")
    .replace(/[ \t]+\n/g, "\n")
    .trim();
  return { text, an: an && an !== "2" ? an : null, italic };
}

function cleanSubtitles(subs) {
  const stats = {
    input: subs.length,
    drawings: 0,
    merged: 0,
    effects: 0,
    empty: 0,
  };
  const items = [];

  for (const s of subs) {
    const t = parseTimestamp(s.timestamp);
    if (!t) continue;
    if (/\{[^}]*\\p[1-9]/.test(s.text)) {
      stats.drawings++;
      continue;
    }
    const style = stripStyle(s.text);
    if (!/[\p{L}\p{N}]/u.test(style.text)) {
      stats.empty++;
      continue;
    }
    const prev = items.at(-1);
    if (
      prev &&
      prev.text === style.text &&
      prev.an === style.an &&
      t.start - prev.end <= MERGE_GAP_MS &&
      t.start >= prev.start
    ) {
      prev.end = Math.max(prev.end, t.end);
      stats.merged++;
      continue;
    }
    items.push({ ...style, start: t.start, end: t.end });
  }

  const kept = items.filter((i) => {
    if (i.end - i.start <= MAX_EFFECT_MS) {
      stats.effects++;
      return false;
    }
    return true;
  });

  const meta = new Map();
  const cleaned = kept.map((i, k) => {
    meta.set(k + 1, { an: i.an, italic: i.italic });
    return {
      index: k + 1,
      timestamp: `${formatMs(i.start)} --> ${formatMs(i.end)}`,
      text: i.text,
    };
  });
  stats.output = cleaned.length;
  return { subs: cleaned, meta, stats };
}

function restoreStyle(subs, meta) {
  return subs.map((s) => {
    const { an, italic } = meta.get(s.index) ?? {};
    let text = s.text;
    if (italic && !/<i>/i.test(text))
      text = text
        .split("\n")
        .map((l) => `<i>${l}</i>`)
        .join("\n");
    if (an) text = `{\\an${an}}${text}`;
    return { ...s, text };
  });
}

module.exports = { cleanSubtitles, restoreStyle };
