'use strict';

const $ = (s) => document.querySelector(s);
const editor = $('#editor');
const preview = $('#preview');
const presetSelect = $('#preset');
const brandSelect = $('#brand');
const btnConfig = $('#btnConfig');
const btnExport = $('#btnExport');
const configPanel = $('#configPanel');
const fileInput = $('#fileInput');

const cfgPageSize = $('#pageSize');
const cfgOrientation = $('#orientation');
const cfgMargins = $('#margins');
const cfgFont = $('#fontFamily');
const cfgFontSize = $('#fontSize');
const cfgPageNumbers = $('#pageNumbers');
const cfgCoverPage = $('#coverPage');
const cfgBreakH1 = $('#breakOnH1');

const PRESETS = {
  technical:    { font: "system-ui, sans-serif", fontSize: "12px", margins: "normal", pageNumbers: true, breakH1: false, coverPage: false },
  report:       { font: "Georgia, serif", fontSize: "12px", margins: "wide", pageNumbers: true, breakH1: false, coverPage: true },
  notes:        { font: "system-ui, sans-serif", fontSize: "11px", margins: "narrow", pageNumbers: false, breakH1: false, coverPage: false },
  article:      { font: "Georgia, serif", fontSize: "13px", margins: "normal", pageNumbers: true, breakH1: false, coverPage: false },
  presentation: { font: "system-ui, sans-serif", fontSize: "14px", margins: "normal", pageNumbers: false, breakH1: true, coverPage: false },
};

const BRANDS = {
  none: { color: null, font: null, logoHtml: '' },
  narobial: {
    color: '#5264c4',
    font: "'Montserrat', system-ui, sans-serif",
    // Logo loaded async at init from logos/narobial.txt (base64)
    logoHtml: '<img id="brand-logo" src="" alt="Narobial" style="max-height:60px;margin-bottom:16px">'
  },
  intable: {
    color: '#FFCE0A',
    font: null,
    logoHtml: '<img id="brand-logo" src="" alt="InTable" style="max-height:60px;margin-bottom:16px">'
  }
};

// Logo data from logos.js (LOGO_NAROBIAL, LOGO_INTABLE)
function getLogoSrc(brandKey) {
  if (brandKey === 'narobial' && typeof LOGO_NAROBIAL !== 'undefined') return LOGO_NAROBIAL;
  if (brandKey === 'intable' && typeof LOGO_INTABLE !== 'undefined') return LOGO_INTABLE;
  return '';
}

// --- Rendering ---
function render() {
  if (typeof marked === 'undefined') return;
  preview.innerHTML = marked.parse(editor.value);
  applyPreviewStyles();
}

let renderTimeout;
function scheduleRender() {
  clearTimeout(renderTimeout);
  renderTimeout = setTimeout(render, 150);
}

// --- Preset ---
function applyPreset() {
  const p = PRESETS[presetSelect.value];
  if (!p) return;
  cfgFont.value = p.font;
  cfgFontSize.value = p.fontSize;
  cfgMargins.value = p.margins;
  cfgPageNumbers.checked = p.pageNumbers;
  cfgBreakH1.checked = p.breakH1;
  cfgCoverPage.checked = p.coverPage;
  applyPreviewStyles();
}

// --- Preview styles ---
function applyPreviewStyles() {
  const brand = BRANDS[brandSelect.value];
  const font = (brand && brand.font) || cfgFont.value;
  preview.style.fontFamily = font;
  preview.style.fontSize = cfgFontSize.value;
  // Brand color on headings
  const headings = preview.querySelectorAll('h1,h2,h3');
  const color = (brand && brand.color) || '';
  headings.forEach(h => { h.style.color = color; });
}

// --- Export ---
function exportPDF() {
  const body = document.body;
  body.className = '';
  body.classList.add(`preset-${presetSelect.value}`);
  body.classList.add(`margin-${cfgMargins.value}`);
  body.classList.add(`orient-${cfgOrientation.value}`);
  if (cfgPageNumbers.checked) body.classList.add('page-numbers');
  if (cfgCoverPage.checked) body.classList.add('cover-page');
  if (cfgBreakH1.checked) body.classList.add('break-h1');
  if (brandSelect.value !== 'none') body.classList.add(`brand-${brandSelect.value}`);

  let pageRule = document.getElementById('dynamic-page-rule');
  if (!pageRule) { pageRule = document.createElement('style'); pageRule.id = 'dynamic-page-rule'; document.head.appendChild(pageRule); }
  const margins = { normal: '2.5cm', narrow: '1.5cm', wide: '3cm' }[cfgMargins.value] || '2.5cm';
  const size = cfgPageSize.value.toLowerCase();
  const orient = cfgOrientation.value === 'landscape' ? ' landscape' : '';
  pageRule.textContent = `@media print { @page { size: ${size}${orient}; margin: ${margins}; } }`;

  injectCover();
  preview.style.fontFamily = (BRANDS[brandSelect.value] && BRANDS[brandSelect.value].font) || cfgFont.value;
  preview.style.fontSize = cfgFontSize.value;

  // Wait for logo to render before printing
  const logo = preview.querySelector('.cover img');
  if (logo && !logo.complete) {
    logo.onload = () => window.print();
    logo.onerror = () => window.print();
  } else {
    window.print();
  }
}

// --- Cover ---
function injectCover() {
  const existing = preview.querySelector('.cover');
  if (existing) existing.remove();
  // Restore hidden H1
  const hiddenH1 = preview.querySelector('h1[style*="display: none"]');
  if (hiddenH1) hiddenH1.style.display = '';

  if (!cfgCoverPage.checked) return;

  const firstH1 = preview.querySelector('h1');
  const title = firstH1 ? firstH1.textContent : 'Documento';
  const brandKey = brandSelect.value;
  const brand = BRANDS[brandKey];

  let logoEl = '';
  if (brandKey !== 'none') {
    const src = getLogoSrc(brandKey);
    if (src) logoEl = `<img src="${src}" alt="${brandKey}" style="max-height:60px;margin-bottom:16px">`;
  }

  const cover = document.createElement('div');
  cover.className = 'cover';
  cover.innerHTML = `${logoEl}<h1>${title}</h1><p class="cover-meta">${new Date().toLocaleDateString('es-ES', { year: 'numeric', month: 'long', day: 'numeric' })}</p>`;
  preview.insertBefore(cover, preview.firstChild);
  if (firstH1) firstH1.style.display = 'none';
}

// --- File loading ---
function loadFile(file) {
  if (!file) return;
  const reader = new FileReader();
  reader.onload = (e) => { editor.value = e.target.result; render(); };
  reader.readAsText(file);
}

// --- Events ---
editor.addEventListener('input', scheduleRender);
presetSelect.addEventListener('change', applyPreset);
brandSelect.addEventListener('change', applyPreviewStyles);
btnExport.addEventListener('click', exportPDF);
btnConfig.addEventListener('click', () => {
  const open = configPanel.classList.toggle('hidden') === false;
  btnConfig.setAttribute('aria-expanded', open);
});
[cfgFont, cfgFontSize, cfgMargins, cfgOrientation, cfgPageNumbers, cfgCoverPage, cfgBreakH1, cfgPageSize].forEach(el => {
  el.addEventListener('change', applyPreviewStyles);
});
fileInput.addEventListener('change', (e) => loadFile(e.target.files[0]));
editor.addEventListener('dragover', (e) => { e.preventDefault(); editor.style.borderColor = '#e94560'; });
editor.addEventListener('dragleave', () => { editor.style.borderColor = ''; });
editor.addEventListener('drop', (e) => {
  e.preventDefault(); editor.style.borderColor = '';
  const file = e.dataTransfer.files[0];
  if (file && /\.(md|markdown|txt)$/i.test(file.name)) loadFile(file);
});

// --- Init ---
document.addEventListener('DOMContentLoaded', () => {
  applyPreset();
  editor.value = `# Documento de ejemplo

## Introducción

Este es un **conversor de Markdown a PDF**. Escribe o pega tu contenido Markdown en el panel izquierdo y selecciona un preset adecuado.

## Características

- Presets para distintos tipos de documento
- Selector de marca (brand) para documentos corporativos
- Configuración de márgenes, fuentes y tamaño
- Vista previa en tiempo real
- Exportación vía diálogo de impresión del navegador

## Código de ejemplo

\`\`\`javascript
function hello() {
  console.log("Hola mundo");
}
\`\`\`

## Tabla

| Columna A | Columna B | Columna C |
|-----------|-----------|-----------|
| Dato 1    | Dato 2    | Dato 3    |
| Dato 4    | Dato 5    | Dato 6    |

> **Nota:** Selecciona "Guardar como PDF" en el diálogo de impresión para obtener tu documento.
`;
  render();
});
