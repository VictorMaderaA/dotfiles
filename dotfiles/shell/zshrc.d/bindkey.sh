# Activar modo emacs (similar a bash, sin vim)
bindkey -e

# Navegación por palabras con Ctrl+Shift+Alt+← (atrás) y Ctrl+Shift+Alt+→ (adelante)
bindkey "^[[1;3D" backward-word
bindkey "^[[1;3C" forward-word

# Alternativas comunes para Alt+← y Alt+→ (por si las anteriores no funcionan)
bindkey "^[b" backward-word
bindkey "^[f" forward-word
