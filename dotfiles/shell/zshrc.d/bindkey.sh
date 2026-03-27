# Activar modo emacs (similar a bash, sin vim)
bindkey -e

# Navegación por palabras con Ctrl+← (atrás) y Ctrl+→ (adelante)
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# Navegación por palabras con Ctrl+Shift+Alt+← (atrás) y Ctrl+Shift+Alt+→ (adelante)
bindkey "^[[1;3D" backward-word
bindkey "^[[1;3C" forward-word

# Alternativas comunes para Alt+← y Alt+→ (por si las anteriores no funcionan)
bindkey "^[b" backward-word
bindkey "^[f" forward-word

# Borrar palabra hacia atrás / adelante con Ctrl
bindkey "^W"      backward-kill-word
bindkey "^[[3;5~" kill-word

# Inicio/fin de línea con Home/End
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
