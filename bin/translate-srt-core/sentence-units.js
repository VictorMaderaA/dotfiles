// sentence-units.js
"use strict";

const { formatSubtitleText } = require("./resegment");
const { stripLeadingSpeakerTag } = require("./tags-and-speakers");

const MAX_UNIT_MEMBERS = 6; // válvula de seguridad, ver nota en groupIntoUnits
const MAX_UNIT_CHARS = 220; // ídem

/**
 * Agrupa sub-bloques finos (con `sentenceBoundary`) en unidades de sentido (oraciones).
 *
 * Válvula de seguridad: si el ASR no puntúa bien, un tramo largo sin `.!?` produciría
 * con la regla literal una unidad gigantesca (crece hasta el próximo cambio de hablante
 * o fin de archivo). MAX_UNIT_MEMBERS/MAX_UNIT_CHARS cierran la unidad igualmente en ese
 * caso, degradando como mucho al comportamiento de "fragmento por fragmento" para ese
 * tramo — nunca lo empeoran.
 */
function groupIntoUnits(subs) {
  const units = [];
  let buffer = [];

  for (let i = 0; i < subs.length; i++) {
    buffer.push(subs[i]);
    const isLast = i === subs.length - 1;
    const bufferChars = buffer.reduce((n, s) => n + s.text.length, 0);
    const forcedClose =
      buffer.length >= MAX_UNIT_MEMBERS || bufferChars >= MAX_UNIT_CHARS;

    if (subs[i].sentenceBoundary === true || isLast || forcedClose) {
      units.push(buildUnit(buffer, units.length + 1));
      buffer = [];
    }
  }
  return units;
}

function buildUnit(members, unitId) {
  const text = members
    .map((m, idx) => (idx === 0 ? m.text : stripLeadingSpeakerTag(m.text)))
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
  return { unitId, members, text };
}

/**
 * Reparte `total` proporcionalmente entre `counts`, método de mayor resto (Hamilton).
 * Suelo de 1 para cualquier miembro con contenido (`counts[i] > 0`), nunca negativo.
 */
function allocateProportional(counts, total) {
  const n = counts.length;
  if (n === 1) return [total];

  const sum = counts.reduce((a, b) => a + b, 0) || 1;
  const raw = counts.map((c) => (c / sum) * total);
  const alloc = raw.map(Math.floor);

  for (let i = 0; i < n; i++) {
    if (counts[i] > 0 && alloc[i] === 0) alloc[i] = 1;
  }

  let diff = total - alloc.reduce((a, b) => a + b, 0);
  const order = raw
    .map((r, i) => ({ i, frac: r - Math.floor(r) }))
    .sort((a, b) => b.frac - a.frac);

  let oi = 0;
  while (diff > 0) {
    alloc[order[oi % n].i]++;
    diff--;
    oi++;
  }
  while (diff < 0) {
    const j = alloc.indexOf(Math.max(...alloc));
    if (alloc[j] > 0) {
      alloc[j]--;
      diff++;
    } else {
      break;
    }
  }

  return alloc;
}

/**
 * Reparte el texto traducido de una unidad entre los sub-índices originales que la
 * componen, proporcionalmente al nº de palabras de cada fragmento original.
 * Nunca parte palabras; el último miembro se queda con el resto exacto de tokens.
 */
function distributeUnitTranslation(unit, translatedUnitText) {
  if (unit.members.length === 1) {
    return [{ index: unit.members[0].index, text: translatedUnitText }];
  }

  const flat = translatedUnitText
    .replace(/\n+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  const tokens = flat.length ? flat.split(" ") : [];

  const counts = unit.members.map(
    (m) =>
      stripLeadingSpeakerTag(m.text).trim().split(/\s+/).filter(Boolean).length,
  );

  const alloc = tokens.length
    ? allocateProportional(counts, tokens.length)
    : counts.map(() => 0);

  const out = [];
  let cursor = 0;
  for (let i = 0; i < unit.members.length; i++) {
    const n = i === unit.members.length - 1 ? tokens.length - cursor : alloc[i];
    const slice = tokens.slice(cursor, cursor + n).join(" ");
    cursor += n;
    out.push({
      index: unit.members[i].index,
      text: formatSubtitleText(slice || ""),
    });
  }
  return out;
}

module.exports = {
  groupIntoUnits,
  allocateProportional,
  distributeUnitTranslation,
};
