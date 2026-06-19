'use strict';

const $ = (s) => document.querySelector(s);
const $$ = (s) => document.querySelectorAll(s);

// --- DOM refs ---
const editor = $('#editor');
const preview = $('#preview');
const presetSelect = $('#preset');
const brandSelect = $('#brand');
const btnConfig = $('#btnConfig');
const btnExport = $('#btnExport');
const btnSavePreset = $('#btnSavePreset');
const configPanel = $('#configPanel');
const fileInput = $('#fileInput');
const renderDot = $('#renderDot');
const wordCountEl = $('#wordCount');
const templateSelect = $('#template');
const previewThemeSelect = $('#previewTheme');

const cfgPageSize = $('#pageSize');
const cfgOrientation = $('#orientation');
const cfgMargins = $('#margins');
const cfgFont = $('#fontFamily');
const cfgFontSize = $('#fontSize');
const cfgPageNumbers = $('#pageNumbers');
const cfgCoverPage = $('#coverPage');
const cfgBreakH1 = $('#breakOnH1');
const cfgAutoTOC = $('#autoTOC');
const cfgWatermark = $('#watermark');
const cfgHeaderText = $('#headerText');
const cfgBwMode = $('#bwMode');

// --- Constants ---
const STORAGE_KEY = 'md-to-pdf-content';
const CUSTOM_PRESETS_KEY = 'md-to-pdf-custom-presets';

const PRESETS = {
  technical:    { font: "system-ui, sans-serif", fontSize: "12px", margins: "normal", pageNumbers: true, breakH1: false, coverPage: false },
  report:       { font: "Georgia, serif", fontSize: "12px", margins: "wide", pageNumbers: true, breakH1: false, coverPage: true },
  notes:        { font: "system-ui, sans-serif", fontSize: "11px", margins: "narrow", pageNumbers: false, breakH1: false, coverPage: false },
  article:      { font: "Georgia, serif", fontSize: "13px", margins: "normal", pageNumbers: true, breakH1: false, coverPage: false },
  presentation: { font: "system-ui, sans-serif", fontSize: "14px", margins: "normal", pageNumbers: false, breakH1: true, coverPage: false },
};

const BRANDS = {
  none: { color: null, font: null },
  narobial: { color: '#5264c4', font: "'Montserrat', system-ui, sans-serif" },
  intable: { color: '#FFCE0A', font: null }
};

const TEMPLATES = {
  cv: `# Nombre Apellido

## Perfil profesional

Breve descripción profesional.

## Experiencia

### Empresa — Cargo (2022 - presente)
- Logro o responsabilidad principal
- Otro logro relevante

### Empresa anterior — Cargo (2019 - 2022)
- Descripción de funciones

## Formación

- **Título universitario** — Universidad (2019)

## Habilidades

| Área | Tecnologías |
|------|-------------|
| Frontend | React, TypeScript, CSS |
| Backend | Node.js, Python |

## Contacto

- Email: nombre@email.com
- GitHub: github.com/nombre
`,
  acta: `# Acta de reunión

**Fecha:** ${new Date().toLocaleDateString('es-ES')}
**Asistentes:** Persona 1, Persona 2, Persona 3

---

## Orden del día

1. Revisión de avances
2. Puntos pendientes
3. Próximos pasos

## Desarrollo

### 1. Revisión de avances
- Punto discutido

### 2. Puntos pendientes
- [ ] Tarea pendiente — Persona 1
- [ ] Otra tarea — Persona 2

## Acuerdos

| Acuerdo | Responsable | Fecha límite |
|---------|-------------|--------------|
| Acción 1 | Persona 1 | DD/MM/YYYY |

## Próxima reunión

**Fecha:** DD/MM/YYYY — **Hora:** HH:MM
`,
  propuesta: `# Propuesta técnica

## Resumen ejecutivo

Descripción breve del proyecto y objetivo.

## Contexto

Situación actual y problema a resolver.

## Solución propuesta

### Arquitectura

Descripción de la arquitectura propuesta.

### Tecnologías

| Capa | Tecnología | Justificación |
|------|-----------|---------------|
| Frontend | React | — |
| Backend | Node.js | — |
| BD | PostgreSQL | — |

### Fases

1. **Fase 1 — MVP** (X semanas)
   - Funcionalidad core

2. **Fase 2 — Iteración** (X semanas)
   - Mejoras y feedback

## Estimación

| Concepto | Horas | Coste |
|----------|-------|-------|
| Desarrollo | X | €X |
| Testing | X | €X |
| **Total** | **X** | **€X** |

---

*Documento generado el ${new Date().toLocaleDateString('es-ES')}*
`
};

// --- Logo data from logos.js ---
function getLogoSrc(brandKey) {
  if (brandKey === 'narobial' && typeof LOGO_NAROBIAL !== 'undefined') return LOGO_NAROBIAL;
  if (brandKey === 'intable' && typeof LOGO_INTABLE !== 'undefined') return LOGO_INTABLE;
  return '';
}

// --- Toast system ---
function showToast(message, type = 'info', duration = 2500) {
  const container = $('#toastContainer');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = message;
  container.appendChild(toast);
  setTimeout(() => toast.remove(), duration);
}

function announceToSR(message) {
  const el = $('#srAnnouncer');
  el.textContent = message;
  setTimeout(() => { el.textContent = ''; }, 3000);
}

// --- Word count ---
function updateWordCount() {
  const text = editor.value.trim();
  const words = text ? text.split(/\s+/).length : 0;
  wordCountEl.textContent = `${words}w · ${text.length}c`;
}

// --- Rendering ---
function render() {
  if (typeof marked === 'undefined') return;
  preview.innerHTML = marked.parse(editor.value);
  applyPreviewStyles();
  if (typeof Prism !== 'undefined') Prism.highlightAllUnder(preview);
  renderMermaid();
}

function getMermaidThemeVars() {
  const brand = brandSelect.value;
  const base = { fontSize: '12px', wrap: true };
  if (brand === 'narobial') {
    return {
      theme: 'base',
      themeVariables: {
        ...base,
        primaryColor: '#e8ebf7', primaryBorderColor: '#5264c4', primaryTextColor: '#1a1a1a',
        secondaryColor: '#f0f2fa', secondaryBorderColor: '#7b8cd4',
        tertiaryColor: '#f8f9fd', tertiaryBorderColor: '#9aa6dc',
        lineColor: '#5264c4', textColor: '#1a1a1a', mainBkg: '#e8ebf7',
        nodeBorder: '#5264c4', clusterBkg: '#f0f2fa',
        titleColor: '#5264c4', edgeLabelBackground: '#fff'
      }
    };
  }
  if (brand === 'intable') {
    return {
      theme: 'base',
      themeVariables: {
        ...base,
        primaryColor: '#FFF8E0', primaryBorderColor: '#FFCE0A', primaryTextColor: '#303030',
        secondaryColor: '#FFF3CC', secondaryBorderColor: '#EA7D1A',
        tertiaryColor: '#FFFBF0', tertiaryBorderColor: '#FFE785',
        lineColor: '#EA7D1A', textColor: '#303030', mainBkg: '#FFF8E0',
        nodeBorder: '#FFCE0A', clusterBkg: '#FFFBF0',
        titleColor: '#303030', edgeLabelBackground: '#fff'
      }
    };
  }
  return { theme: 'default', themeVariables: base };
}

function initMermaidTheme() {
  if (typeof mermaid === 'undefined') return;
  const cfg = getMermaidThemeVars();
  mermaid.initialize({
    startOnLoad: false,
    ...cfg,
    flowchart: { useMaxWidth: true, padding: 12, nodeSpacing: 30, rankSpacing: 40 },
    sequence: { useMaxWidth: true, boxMargin: 8, noteMargin: 8 },
    themeCSS: '.node rect, .node polygon, .node circle { stroke-width: 1.5px; } .edgeLabel { font-size: 11px; }'
  });
}

function renderMermaid() {
  if (typeof mermaid === 'undefined') return;
  initMermaidTheme();
  const codeBlocks = preview.querySelectorAll('pre code.language-mermaid');
  codeBlocks.forEach((block) => {
    const pre = block.parentElement;
    const container = document.createElement('div');
    container.className = 'mermaid';
    container.textContent = block.textContent;
    pre.replaceWith(container);
  });
  mermaid.run({ nodes: preview.querySelectorAll('.mermaid') });
}

let renderTimeout;
function scheduleRender() {
  cancelAnimationFrame(renderTimeout);
  if (renderDot) renderDot.classList.add('rendering');
  renderTimeout = requestAnimationFrame(() => {
    if ('requestIdleCallback' in window) {
      requestIdleCallback(() => { render(); updateWordCount(); renderDot.classList.remove('rendering'); }, { timeout: 200 });
    } else {
      render(); updateWordCount(); renderDot.classList.remove('rendering');
    }
  });
}

// --- Auto-save ---
let saveTimeout;
function autoSave() { localStorage.setItem(STORAGE_KEY, editor.value); }

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

// --- Custom presets ---
function loadCustomPresets() {
  presetSelect.querySelectorAll('option[data-custom]').forEach(o => o.remove());
  const customs = JSON.parse(localStorage.getItem(CUSTOM_PRESETS_KEY) || '{}');
  Object.keys(customs).forEach(name => {
    const opt = document.createElement('option');
    opt.value = name;
    opt.textContent = `⭐ ${name}`;
    opt.dataset.custom = 'true';
    presetSelect.appendChild(opt);
  });
  Object.assign(PRESETS, customs);
}

// --- Preview styles ---
function applyPreviewStyles() {
  const brand = BRANDS[brandSelect.value];
  const font = (brand && brand.font) || cfgFont.value;
  preview.style.fontFamily = font;
  preview.style.fontSize = cfgFontSize.value;
  const color = (brand && brand.color) || 'inherit';
  preview.style.setProperty('--brand-color', color);
}

// --- Export ---
function exportPDF() {
  const body = document.body;
  const savedClasses = body.className;
  body.className = '';
  body.classList.add(`preset-${presetSelect.value}`);
  body.classList.add(`margin-${cfgMargins.value}`);
  body.classList.add(`orient-${cfgOrientation.value}`);
  if (cfgPageNumbers.checked) body.classList.add('page-numbers');
  if (cfgCoverPage.checked) body.classList.add('cover-page');
  if (cfgBreakH1.checked) body.classList.add('break-h1');
  if (brandSelect.value !== 'none') body.classList.add(`brand-${brandSelect.value}`);
  if (cfgBwMode.checked) body.classList.add('bw-mode');

  let pageRule = document.getElementById('dynamic-page-rule');
  if (!pageRule) { pageRule = document.createElement('style'); pageRule.id = 'dynamic-page-rule'; document.head.appendChild(pageRule); }
  const margins = { normal: '2.5cm', narrow: '1.5cm', wide: '3cm' }[cfgMargins.value] || '2.5cm';
  const size = cfgPageSize.value.toLowerCase();
  const orient = cfgOrientation.value === 'landscape' ? ' landscape' : '';
  pageRule.textContent = `@media print { @page { size: ${size}${orient}; margin: ${margins}; } }`;

  injectCover();
  if (cfgAutoTOC.checked) injectTOC();
  injectWatermark();
  injectHeader();
  preview.style.fontFamily = (BRANDS[brandSelect.value] && BRANDS[brandSelect.value].font) || cfgFont.value;
  preview.style.fontSize = cfgFontSize.value;

  const cleanup = () => {
    body.className = savedClasses;
    document.title = savedTitle;
    preview.querySelector('.cover')?.remove();
    preview.querySelector('.toc')?.remove();
    preview.querySelector('.watermark')?.remove();
    preview.querySelector('.print-header')?.remove();
    const hiddenH1 = preview.querySelector('h1[style*="display: none"]');
    if (hiddenH1) hiddenH1.style.display = '';
  };

  // Set document title for PDF filename suggestion
  const savedTitle = document.title;
  const firstH1 = preview.querySelector('h1:not([style*="display: none"])');
  const rawName = loadedFileName || (firstH1 ? firstH1.textContent.trim() : '') || 'documento';
  // Remove filesystem-unsafe chars and replace spaces with hyphens
  const docName = rawName.replace(/[/\\:*?"<>|]/g, '').replace(/\s+/g, '-').trim() || 'documento';
  document.title = docName;

  window.addEventListener('afterprint', cleanup, { once: true });

  const logo = preview.querySelector('.cover img');
  if (logo && !logo.complete) {
    logo.onload = () => window.print();
    logo.onerror = () => window.print();
  } else {
    window.print();
  }
  announceToSR('PDF exportado');
}

// --- Cover ---
function injectCover() {
  preview.querySelector('.cover')?.remove();
  const hiddenH1 = preview.querySelector('h1[style*="display: none"]');
  if (hiddenH1) hiddenH1.style.display = '';
  if (!cfgCoverPage.checked) return;

  const firstH1 = preview.querySelector('h1');
  const title = firstH1 ? firstH1.textContent : 'Documento';
  const brandKey = brandSelect.value;
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

// --- TOC ---
function injectTOC() {
  preview.querySelector('.toc')?.remove();
  const headings = preview.querySelectorAll('h1:not(.cover h1), h2, h3');
  if (headings.length === 0) return;
  let items = '';
  headings.forEach(h => {
    if (h.style.display === 'none') return;
    const level = parseInt(h.tagName[1]);
    const indent = (level - 1) * 16;
    items += `<li style="margin-left:${indent}px">${h.textContent}</li>`;
  });
  const toc = document.createElement('nav');
  toc.className = 'toc';
  toc.innerHTML = `<h2>Índice</h2><ul>${items}</ul>`;
  const cover = preview.querySelector('.cover');
  preview.insertBefore(toc, cover ? cover.nextSibling : preview.firstChild);
}

// --- Watermark ---
function injectWatermark() {
  const text = cfgWatermark.value.trim();
  if (!text) return;
  const wm = document.createElement('div');
  wm.className = 'watermark';
  wm.textContent = text;
  preview.appendChild(wm);
}

// --- Header ---
function injectHeader() {
  const text = cfgHeaderText.value.trim();
  if (!text) return;
  const el = document.createElement('div');
  el.className = 'print-header';
  el.textContent = text;
  preview.insertBefore(el, preview.firstChild);
}

// --- File loading ---
let loadedFileName = '';

function loadFile(file) {
  if (!file) return;
  loadedFileName = file.name.replace(/\.(md|markdown|txt)$/i, '');
  const reader = new FileReader();
  reader.onload = (e) => {
    editor.value = e.target.result;
    render();
    updateWordCount();
    autoSave();
    showToast(`Cargado: ${file.name}`, 'success');
  };
  reader.readAsText(file);
}

// --- Events ---
editor.addEventListener('input', () => {
  scheduleRender();
  clearTimeout(saveTimeout);
  saveTimeout = setTimeout(autoSave, 1000);
});

presetSelect.addEventListener('change', applyPreset);
brandSelect.addEventListener('change', () => { applyPreviewStyles(); render(); });
btnExport.addEventListener('click', exportPDF);

btnConfig.addEventListener('click', () => {
  const open = configPanel.classList.toggle('hidden') === false;
  btnConfig.setAttribute('aria-expanded', open);
});

[cfgFont, cfgFontSize, cfgMargins, cfgOrientation, cfgPageNumbers, cfgCoverPage, cfgBreakH1, cfgPageSize].forEach(el => {
  el.addEventListener('change', applyPreviewStyles);
});

fileInput.addEventListener('change', (e) => loadFile(e.target.files[0]));

// Drag & drop
editor.addEventListener('dragover', (e) => { e.preventDefault(); editor.style.borderColor = '#e94560'; });
editor.addEventListener('dragleave', () => { editor.style.borderColor = ''; });
editor.addEventListener('drop', (e) => {
  e.preventDefault(); editor.style.borderColor = '';
  const file = e.dataTransfer.files[0];
  if (file && /\.(md|markdown|txt)$/i.test(file.name)) loadFile(file);
});

// Tab indent
editor.addEventListener('keydown', (e) => {
  if (e.key === 'Tab') {
    e.preventDefault();
    const start = editor.selectionStart;
    const end = editor.selectionEnd;
    editor.value = editor.value.substring(0, start) + '  ' + editor.value.substring(end);
    editor.selectionStart = editor.selectionEnd = start + 2;
    scheduleRender();
  }
});

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
  if (e.ctrlKey && e.shiftKey && e.key === 'E') { e.preventDefault(); exportPDF(); }
  if (e.ctrlKey && e.shiftKey && e.key === 'P') { e.preventDefault(); btnConfig.click(); }
  if (e.ctrlKey && e.shiftKey && e.key === 'O') { e.preventDefault(); fileInput.click(); }
});

// Save preset
btnSavePreset.addEventListener('click', () => {
  const name = prompt('Nombre del preset:');
  if (!name) return;
  const preset = {
    font: cfgFont.value, fontSize: cfgFontSize.value, margins: cfgMargins.value,
    pageNumbers: cfgPageNumbers.checked, breakH1: cfgBreakH1.checked, coverPage: cfgCoverPage.checked
  };
  const customs = JSON.parse(localStorage.getItem(CUSTOM_PRESETS_KEY) || '{}');
  customs[name] = preset;
  localStorage.setItem(CUSTOM_PRESETS_KEY, JSON.stringify(customs));
  loadCustomPresets();
  presetSelect.value = name;
  showToast(`Preset "${name}" guardado`, 'success');
});

// Preview theme
previewThemeSelect.addEventListener('change', (e) => {
  const pane = document.querySelector('.preview-pane');
  pane.classList.remove('theme-dark', 'theme-sepia');
  if (e.target.value !== 'light') pane.classList.add(`theme-${e.target.value}`);
});

// Template
templateSelect.addEventListener('change', (e) => {
  const key = e.target.value;
  if (!key) return;
  if (editor.value.trim() && !confirm('¿Reemplazar contenido actual con el template?')) {
    e.target.value = '';
    return;
  }
  editor.value = TEMPLATES[key];
  render(); updateWordCount(); autoSave();
  e.target.value = '';
  showToast(`Template "${key}" cargado`, 'success');
});

// Mobile tabs
$$('.mobile-tabs .tab').forEach(tab => {
  tab.addEventListener('click', () => {
    $$('.mobile-tabs .tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    const pane = tab.dataset.pane;
    document.querySelector('.editor-pane').classList.toggle('mobile-visible', pane === 'editor');
    document.querySelector('.preview-pane').classList.toggle('mobile-visible', pane === 'preview');
  });
});

// --- Init ---
document.addEventListener('DOMContentLoaded', () => {
  // Mermaid init
  // Mermaid init with brand theming
  initMermaidTheme();

  // Task list support via marked renderer
  const renderer = new marked.Renderer();
  const origListitem = renderer.listitem;
  renderer.listitem = function(text) {
    const t = (typeof text === 'object') ? (text.text || '') : text;
    if (t.startsWith('[x] ')) return `<li class="task-item"><input type="checkbox" checked disabled> ${t.slice(4)}</li>`;
    if (t.startsWith('[ ] ')) return `<li class="task-item"><input type="checkbox" disabled> ${t.slice(4)}</li>`;
    return `<li>${t}</li>`;
  };
  marked.setOptions({ renderer, gfm: true, breaks: true });

  loadCustomPresets();
  applyPreset();

  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved) {
    editor.value = saved;
  } else {
    editor.value = `# Documento de ejemplo

## Introducción

Este es un **conversor de Markdown a PDF**. Escribe o pega tu contenido Markdown en el panel izquierdo y selecciona un preset adecuado.

## Características

- Presets para distintos tipos de documento
- Selector de marca (brand) para documentos corporativos
- Configuración de márgenes, fuentes y tamaño
- Vista previa en tiempo real
- Exportación vía diálogo de impresión del navegador
- [x] Syntax highlighting con Prism
- [ ] Feature pendiente de ejemplo

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

## Atajos

- **Ctrl+Shift+E** — Exportar PDF
- **Ctrl+Shift+P** — Toggle config
- **Ctrl+Shift+O** — Abrir archivo
- **Tab** — Indentar
`;
  }
  render();
  updateWordCount();
});
