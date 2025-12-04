#Navigation and listing:
alias ll='ls -alF' # (Long detailed listing with file type indicators)
alias la='ls -A' # (List all except . and ..)
alias l='ls -CF' # (Classify and columnate list)
alias ..='cd ..' # (Go up one directory)
alias ...='cd ../..' # (Go up two directories)


#Command shortcuts:
alias c='clear' # (Clear the terminal)
alias r='source ~/.zshrc' # (Reload Zsh config)
alias h='history 10' # (Show last 10 commands)
alias hg='history | grep' # (Search command history)


#Git helpers:
alias gs='git status'
alias gf='git fetch'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'


#Package management (apt example):
alias update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias remove='sudo apt purge'
alias clean='sudo apt autoremove'


#npm/yarn shortcuts (if using Node.js):
alias ni='npm install'
alias nis='npm install --save'
alias nrb='npm run build'
alias nrs='npm run start'


#Global aliases for easier piping (Zsh-specific):
alias -g G='| grep' # (For quick grep in commands)
alias -g L='| less'
alias -g H='| head'

#Docker
alias dr='docker compose run -it --rm'

alias grep='grep --color=auto' # (Grep con colores por defecto)

alias rename='renombrar'
renombrar() {
  if [ $# -ne 2 ]; then
    echo "Uso: renombrar archivo_o_carpeta_vieja archivo_o_carpeta_nueva"
  else
    mv "$1" "$2"
  fi
}

whisper_subs() {
  export PYTORCH_ALLOC_CONF=expandable_segments:True
  export OMP_NUM_THREADS=8

  local filepath="$1"
  local idioma="${2:-es}"
  local modelo="${3:-medium}"
  local output_dir="${4:-$(dirname "$filepath")}"

#tiny
#base
#small
#medium
#large

  # Obtener nombre base sin extensión
  local base_name="$(basename "$filepath")"
  base_name="${base_name%.*}"

  # Carpeta de salida (por defecto misma carpeta del archivo)
  mkdir -p "$output_dir"

  whisper "$filepath" --language "$idioma" --model "$modelo" --output_format srt --output_dir "$output_dir"

  # Renombrar el archivo .srt generado para que tenga el mismo base_name que el video
  # Whisper por defecto agrega extensión .srt al nombre original.
  # Asumimos que Whisper genera archivo con base_name y extensión .srt dentro de output_dir
  mv "$output_dir"/"${base_name}".srt "$output_dir"/"${base_name}.${idioma}.srt"
}
