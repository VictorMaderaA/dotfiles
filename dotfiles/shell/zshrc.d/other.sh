# Funciones de utilidad optimizadas para Zsh

rename_unique() {
  local counter=0
  # Zsh usa modificadores en los patrones en lugar de shopt
  for f in *(ND.); do
    local ext="${f##*.}"
    local newname="file-$RANDOM.$ext"
    while [[ -f "$newname" ]]; do newname="file-$RANDOM.$ext"; done
    mv -f "$f" "$newname" && {
      echo "✓ $f → $newname"
      ((counter++))
    }
  done
  echo "Listo: $counter archivos."
}

# Eliminado rename_unique_simple por ser duplicado de rename_unique

compress_video() {
  local crf=${1:-28}
  for f in *.mp4(N) *.webm(N); do
    [[ -f "$f" ]] || continue
    local tmp="${f:r}.tmp.mp4"
    ffmpeg -y -i "$f" -nostdin \
      -map_metadata -1 \
      -vf "scale='trunc(iw/2)*2:trunc(ih/2)*2'" \
      -c:v libx265 -crf "$crf" -preset medium -pix_fmt yuv420p \
      -c:a aac -b:a 128k \
      "$tmp" && \
    mv "$tmp" "$f" && \
    echo "✓ $f → CRF $crf" || {
      rm -f "$tmp"
      echo "✗ Error: $f" >&2
    }
  done
  echo "Compresión completada (directorio actual)."
}

compress_av1() {
  local crf=${1:-30}
  for f in *.mp4(N) *.webm(N); do
    local tmp="${f:r}.tmp.mp4"
    ffmpeg -y -i "$f" -nostdin \
      -map_metadata -1 -vf "scale='trunc(iw/2)*2:trunc(ih/2)*2'" \
      -c:v libsvtav1 -crf "$crf" -preset 8 \
      -c:a aac -b:a 128k "$tmp" && mv "$tmp" "$f"
  done
}

strip_metadata() {
  # En Zsh, podemos iterar recursivamente con **/*
  for f in **/*(ND.); do
      # Saltar si ya es .tmp
      [[ "$f" == *.tmp.* ]] && continue

      local tmp="${f:r}.tmp.${f:e}"

      if command -v exiftool >/dev/null 2>&1; then
        exiftool -all= -o "$tmp" -overwrite_original "$f" && \
        echo "✓ Metadata eliminada (exiftool): $f"
      elif command -v ffmpeg >/dev/null 2>&1 && [[ "$f" =~ \.(mp4|webm|avi|mov|mkv|flv|m4v)$ ]]; then
        ffmpeg -y -i "$f" -map_metadata -1 -c copy -nostdin "$tmp" && \
        mv "$tmp" "$f" && echo "✓ Metadata eliminada (ffmpeg): $f"
      else
        continue
      fi || {
        rm -f "$tmp"
        echo "✗ Error en: $f" >&2
      }
  done
  echo "Completado."
}

