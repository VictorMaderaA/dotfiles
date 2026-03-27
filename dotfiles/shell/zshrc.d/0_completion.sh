# Patrón recomendado para compinit con caché
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit -d ~/.zcompdump
else
  compinit -C -d ~/.zcompdump  # -C salta la comprobación de seguridad para mayor velocidad
fi

# Bash completion configuration (para Zsh)
if [[ -f /usr/share/zsh/completion/_bash_completion ]]; then
  source /usr/share/zsh/completion/_bash_completion
elif [[ -f /etc/zsh_completion ]]; then
  source /etc/zsh_completion
fi
