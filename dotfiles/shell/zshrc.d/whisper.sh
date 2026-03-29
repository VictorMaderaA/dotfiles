#!/usr/bin/env bash
export HF_TOKEN="REMOVED"   # HuggingFace — requerido para diarización

# whisper_subs_v2.sh
#
# Wrapper para WhisperX vía Docker con diarización opcional.
# Genera SRT + JSON y está pensado para vivir en un repo público "dotfiles".
#
# ⚠️ IMPORTANTE (REPO PÚBLICO):
#   - NO hardcodees aquí tu HF_TOKEN real.
#   - Exporta HF_TOKEN en tu entorno (por ejemplo, en un .zshrc privado).
#   - Si alguna vez ves un valor tipo "hf_xxx" escrito literalmente en este archivo,
#     BÓRRALO antes de hacer push al repo público.

export WHISPER_MODEL="${WHISPER_MODEL:-large-v3}"      # Modelo WhisperX (large-v3 por defecto)
export WHISPER_OUTPUT_DIR="${WHISPER_OUTPUT_DIR:-./subtitles}"  # Directorio de salida por defecto

whisper_subs() {
  local input="$1"
  local lang="${2:-}"  # idioma opcional, p.ej. "en", "es"
  local model="${WHISPER_MODEL:-large-v3}"
  local output_dir="${WHISPER_OUTPUT_DIR:-$HOME/subtitles}"
  local hf_token="${HF_TOKEN:-}"   # se espera vía entorno
  local docker_image="whisperx:local"
  local dockerfile_dir="$HOME/.docker/whisperx"
  local hash_file="$dockerfile_dir/.build_hash"

  # Ayuda
  if [[ -z "$input" || "$input" == "-h" || "$input" == "--help" ]]; then
    echo "Uso: whisper_subs <input> [idioma]"
    echo "  whisper_subs --rebuild              # fuerza reconstrucción de imagen Docker"
    echo ""
    echo "Ejemplos:"
    echo "  whisper_subs 'https://youtu.be/xxxx' en"
    echo "  whisper_subs './video.mp4' es"
    echo ""
    echo "Variables de entorno:"
    echo "  HF_TOKEN           → Token HuggingFace (diarización de hablantes)"
    echo "  WHISPER_MODEL      → Modelo WhisperX (por defecto: large-v3)"
    echo "  WHISPER_OUTPUT_DIR → Directorio salida (por defecto: ~/subtitles)"
    echo ""
    echo "⚠️  Este script está pensado para repos públicos (dotfiles)."
    echo "   NO guardes aquí tokens reales; usa variables de entorno."
    return 0
  fi

  # Dependencias
  local missing=()
  command -v docker &>/dev/null || missing+=("docker")
  command -v ffmpeg &>/dev/null || missing+=("ffmpeg")
  [[ "$input" =~ ^https?:// ]] && { command -v yt-dlp &>/dev/null || missing+=("yt-dlp"); }

  if (( ${#missing[@]} )); then
    echo "❌ Dependencias faltantes: ${missing[*]}"
    echo "   Instala por ejemplo: sudo apt install docker.io ffmpeg; pip install yt-dlp"
    return 1
  fi

  # Dockerfile
  mkdir -p "$dockerfile_dir"

  cat > "$dockerfile_dir/Dockerfile" << 'DOCKERFILE'
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3.10 python3-pip python3.10-dev \
      ffmpeg git libsndfile1 && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf python3.10 /usr/bin/python3 && \
    ln -sf python3 /usr/bin/python

# torch + torchaudio cu121 (sin torchvision)
RUN pip install --no-cache-dir \
    torch==2.3.1 \
    torchaudio==2.3.1 \
    --index-url https://download.pytorch.org/whl/cu121

# Versiones fijadas compatibles con whisperx + pyannote
RUN pip install --no-cache-dir \
    "ctranslate2==4.4.0" \
    "transformers==4.44.2" \
    "tokenizers==0.19.1"

RUN pip install --no-cache-dir \
    "whisperx" \
    "pyannote.audio>=3.3" \
    "pyannote.core>=5.0"

WORKDIR /app
ENTRYPOINT ["whisperx"]
DOCKERFILE

  # Rebuild automático
  local current_hash
  current_hash=$(sha256sum "$dockerfile_dir/Dockerfile" | cut -d' ' -f1)
  local stored_hash
  stored_hash=$(cat "$hash_file" 2>/dev/null || echo "")
  local force_rebuild=false
  [[ "$input" == "--rebuild" ]] && force_rebuild=true

  if $force_rebuild || \
     ! docker image inspect "$docker_image" &>/dev/null || \
     [[ "$current_hash" != "$stored_hash" ]]; then

    if $force_rebuild; then
      echo "🐳 Rebuild forzado de '$docker_image'..."
      docker rmi "$docker_image" &>/dev/null || true
    elif ! docker image inspect "$docker_image" &>/dev/null; then
      echo "🐳 Imagen '$docker_image' no encontrada — construyendo..."
    else
      echo "🐳 Dockerfile actualizado — reconstruyendo imagen..."
    fi
    echo "   (primera vez: ~5-10 min)"

    docker build -t "$docker_image" "$dockerfile_dir/"
    if [[ $? -ne 0 ]]; then
      echo "❌ Error al construir la imagen Docker"
      return 1
    fi

    echo "$current_hash" > "$hash_file"
    echo "✅ Imagen '$docker_image' lista"
    [[ "$input" == "--rebuild" ]] && return 0
  fi

  # GPU / CPU
  local use_gpu=false
  local compute_type="int8"
  local device="cpu"

  if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null 2>&1; then
    use_gpu=true
    compute_type="float16"
    device="cuda"
    echo "🖥️  GPU NVIDIA detectada → CUDA + float16"
  else
    echo "💻 Sin GPU → modo CPU (int8). Considera WHISPER_MODEL=turbo si existe."
  fi

  mkdir -p "$output_dir"
  local tmpdir
  tmpdir=$(mktemp -d)
  local raw_audio=""
  local base_name=""

  # Descargar si es URL
  if [[ "$input" =~ ^https?:// ]]; then
    echo "⬇️  Descargando audio..."
    yt-dlp \
      --no-playlist \
      --extract-audio \
      --audio-quality 0 \
      --output "$tmpdir/audio.%(ext)s" \
      "$input" 2>&1 | grep -E "(Downloading|Destination|ERROR|already)"

    if [[ $? -ne 0 ]]; then
      echo "❌ Error al descargar el audio"
      rm -rf "$tmpdir"
      return 1
    fi

    base_name=$(yt-dlp --get-title --no-playlist "$input" 2>/dev/null \
      | tr '[:upper:]' '[:lower:]' \
      | sed 's/[^a-z0-9]/_/g; s/__*/_/g; s/^_//; s/_$//')
    [[ -z "$base_name" ]] && base_name="video_$(date +%Y%m%d_%H%M%S)"
    raw_audio=$(ls "$tmpdir"/audio.* 2>/dev/null | head -1)
  else
    # Archivo local
    if [[ ! -f "$input" ]]; then
      echo "❌ Archivo no encontrado: $input"
      rm -rf "$tmpdir"
      return 1
    fi
    base_name=$(basename "$input" | sed 's/\.[^.]*$//')
    raw_audio="$input"
  fi

  # WAV 16k mono
  echo "🔄 Normalizando audio (WAV 16kHz mono)..."
  local wav_file="$tmpdir/audio.wav"

  ffmpeg -i "$raw_audio" -ar 16000 -ac 1 -f wav "$wav_file" -y -loglevel error
  if [[ $? -ne 0 || ! -f "$wav_file" ]]; then
    echo "❌ Error en la conversión de audio"
    rm -rf "$tmpdir"
    return 1
  fi

  # Ejecutar WhisperX
  echo "🎙️  Transcribiendo con WhisperX"
  echo "   Modelo: $model | Device: $device ($compute_type)"

  local hf_cache="$HOME/.cache/huggingface"
  mkdir -p "$hf_cache"

  local docker_cmd=(
    docker run --rm
    -v "$tmpdir:/app"
    -v "$hf_cache:/root/.cache/huggingface"
  )

  $use_gpu && docker_cmd+=(--gpus all)

  docker_cmd+=(
    "$docker_image"
    "audio.wav"
    --model "$model"
    --device "$device"
    --compute_type "$compute_type"
    --batch_size 16

    # Salida: todos los formatos (SRT, VTT, TXT, TSV, JSON, AUD) para tener JSON rico
    --output_dir /app
    --output_format all

    --max_line_width 42
    --max_line_count 2

    --beam_size 5
    --temperature 0
    --compression_ratio_threshold 2.4
    --logprob_threshold -1.0
    --no_speech_threshold 0.6
    --suppress_tokens -1

    --vad_onset 0.500
    --vad_offset 0.363
    --chunk_size 6

    --initial_prompt "Subtitles with proper punctuation, capitalization and sentence boundaries."
    --print_progress True
  )

  [[ -n "$lang" ]] && docker_cmd+=(--language "$lang")

  if [[ -n "$hf_token" ]]; then
    echo "👥 Diarización activada (pyannote)"
    docker_cmd+=(--diarize --hf_token "$hf_token")
  else
    echo "⚠️  Sin diarización — exporta HF_TOKEN para separar hablantes"
  fi

  "${docker_cmd[@]}"
  local exit_code=$?

  # Mover salidas
  if [[ $exit_code -eq 0 ]]; then
    local srt_found json_found
    srt_found=$(ls "$tmpdir"/*.srt 2>/dev/null | head -1)
    json_found=$(ls "$tmpdir"/*.json 2>/dev/null | head -1)

    mkdir -p "$output_dir"

    if [[ -n "$srt_found" ]]; then
      local srt_final="$output_dir/${base_name}.srt"
      mv "$srt_found" "$srt_final"
      echo "✅ SRT generado: $srt_final"
    else
      echo "⚠️  WhisperX terminó sin errores pero no generó SRT"
    fi

    if [[ -n "$json_found" ]]; then
      local json_final="$output_dir/${base_name}.json"
      mv "$json_found" "$json_final"
      echo "✅ JSON generado: $json_final"
    else
      echo "⚠️  WhisperX no generó JSON (comprueba --output_format)."
    fi

    rm -rf "$tmpdir"
  else
    rm -rf "$tmpdir"
    echo "❌ Error durante la transcripción (código: $exit_code)"
    echo "💡 Si el error es de dependencias, prueba: whisper_subs --rebuild"
    return 1
  fi
}