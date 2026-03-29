# ─── Detecta browser disponible para extraer cookies ─────────────────────────
_ytdl_detect_browser() {
  for browser in firefox chrome chromium brave; do
    if command -v "${browser}" &>/dev/null; then
      echo "${browser}"
      return 0
    fi
  done
  return 1
}

# ─── Actualiza yt-dlp detectando método de instalación ───────────────────────
_ytdl_update() {
  local ytdlp_path
  ytdlp_path="$(which yt-dlp)"
  echo "    → Actualizando yt-dlp (${ytdlp_path})..."

  if pip3 show yt-dlp &>/dev/null 2>&1; then
    pip3 install --upgrade yt-dlp --quiet && return 0
  fi
  if command -v brew &>/dev/null && brew list yt-dlp &>/dev/null 2>&1; then
    brew upgrade yt-dlp && return 0
  fi
  if [[ "${ytdlp_path}" == /usr/* || "${ytdlp_path}" == /opt/* ]]; then
    sudo yt-dlp -U && return 0
  fi
  yt-dlp -U && return 0
}

# ─── Comando principal ────────────────────────────────────────────────────────
_ytdl() {
  local url="${1}"
  local dest="${2:-${HOME}/Downloads}"

  if [[ -z "${url}" ]]; then
    echo "Uso:  ytdl <URL> [directorio_destino]"
    echo "Ej.:  ytdl 'https://youtu.be/xxxxx' ~/Videos"
    return 1
  fi

  if ! command -v yt-dlp &>/dev/null; then
    echo "❌  yt-dlp no instalado. Ejecuta: pip3 install yt-dlp"
    return 1
  fi

  mkdir -p "${dest}"

  # ── Runtime JS para resolver el n-challenge ──────────────────────────────
  local js_args=()
  if command -v node &>/dev/null; then
    js_args=(--js-runtimes node --remote-components ejs:github)
  else
    echo "⚠️  Node.js no encontrado → n-challenge puede fallar"
    echo "    Instala: sudo apt install nodejs  |  brew install node"
  fi

  # ── Cookies del browser → provee PO Token automáticamente ────────────────
  local cookie_args=()
  local browser
  browser="$(_ytdl_detect_browser)"
  if [[ -n "${browser}" ]]; then
    echo "🍪  Usando cookies de: ${browser}"
    cookie_args=(--cookies-from-browser "${browser}")
  else
    echo "⚠️  No se detectó ningún browser — sin cookies (calidad puede ser menor)"
  fi

  # ── ffmpeg para merge de streams separados ────────────────────────────────
  local format_str
  if command -v ffmpeg &>/dev/null; then
    format_str="bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best"
  else
    echo "⚠️  ffmpeg no detectado → formato preempaquetado"
    format_str="b"
  fi

  # ── Argumentos comunes ────────────────────────────────────────────────────
  local common_args=(
    "${cookie_args[@]}"
    "${js_args[@]}"
    --merge-output-format mp4
    --write-subs
    --write-auto-subs
    --sub-langs "orig"
    --convert-subs srt
    --no-playlist
    --retries 5
    --fragment-retries 5
    --concurrent-fragments 4
    --continue
    -o "${dest}/%(title).100B [%(id)s].%(ext)s"
  )

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎬  URL    : ${url}"
  echo "📁  Destino: ${dest}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # ── Intento 1: web+mweb con cookies (calidad máxima) ─────────────────────
  echo "⏳  Intento 1/3: cliente web con cookies..."
  yt-dlp -f "${format_str}" \
    --extractor-args "youtube:player_client=web,mweb" \
    "${common_args[@]}" "${url}"
  local code=$?

  # ── Intento 2: android_vr (no requiere PO Token) ──────────────────────────
  if [[ ${code} -ne 0 ]]; then
    echo ""
    echo "⚠️  Falló. Intento 2/3: cliente android_vr (sin PO Token requerido)..."
    yt-dlp -f "${format_str}" \
      --extractor-args "youtube:player_client=android_vr,web" \
      "${common_args[@]}" "${url}"
    code=$?
  fi

  # ── Intento 3: actualizar yt-dlp + tv client como último recurso ──────────
  if [[ ${code} -ne 0 ]]; then
    echo ""
    echo "⚠️  Sigue fallando. Actualizando yt-dlp y usando cliente tv..."
    yt-dlp --rm-cache-dir
    _ytdl_update
    yt-dlp -f "${format_str}" \
      --extractor-args "youtube:player_client=tv,android_vr" \
      "${common_args[@]}" "${url}"
    code=$?
  fi

  echo ""
  if [[ ${code} -eq 0 ]]; then
    echo "✅  Completado → ${dest}"
  else
    echo "❌  Descarga fallida. Ejecuta para diagnosticar:"
    echo "    yt-dlp --list-formats '${url}'"
    return 1
  fi
}

# ─── Extrae audio de un vídeo y lo convierte a MP3 ───────────────────────────
_to_mp3() {
  local input="${1}"
  local quality="${2:-0}"

  if [[ -z "${input}" ]]; then
    echo "Uso:  to_mp3 <archivo_video> [calidad]"
    echo "      calidad: 0 (mejor, ~245kbps) → 9 (peor), por defecto 0"
    echo "Ej.:  to_mp3 video.mp4"
    echo "      to_mp3 video.mp4 2"
    return 1
  fi

  if [[ ! -f "${input}" ]]; then
    echo "❌  Archivo no encontrado: ${input}"
    return 1
  fi

  if ! command -v ffmpeg &>/dev/null; then
    echo "❌  ffmpeg no instalado: sudo apt install ffmpeg  |  brew install ffmpeg"
    return 1
  fi

  local output="${input:r}.mp3"

  if [[ -f "${output}" ]]; then
    output="${input:r}_$(date +%s).mp3"
  fi

  echo "🎵  Entrada : ${input}"
  echo "💾  Salida  : ${output}"
  echo "⚙️   Calidad : VBR q${quality}"
  echo "⏳  Convirtiendo..."

  ffmpeg -i "${input}" -vn -codec:a libmp3lame -q:a "${quality}" -id3v2_version 3 -y "${output}" 2>&1 | grep -E "(Error|error|Duration|Audio|size=|time=)"

  local code=${pipestatus[1]}
  echo ""
  if [[ ${code} -eq 0 ]]; then
    local size
    size=$(du -h "${output}" | cut -f1)
    echo "✅  MP3 generado (${size}) → ${output}"
  else
    echo "❌  Conversión fallida (código ${code})"
    return 1
  fi
}

alias to_mp3='noglob _to_mp3'
alias ytdl='noglob _ytdl'