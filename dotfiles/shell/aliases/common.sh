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

aws-switch() {
  # aws configure --profile nombre-del-perfil

    if [[ -z "$1" ]]; then
        echo "No se especificó un perfil. Perfiles disponibles:"
        aws configure list-profiles
        return 1
    fi

    export AWS_PROFILE="$1"
    echo "Perfil AWS cambiado a: $AWS_PROFILE"
}

aws-assume-qbi() {
  local ROLE_ARN="arn:aws:iam::029423023787:role/QBI-VictorMadera-CrossAccount"
  local SESSION_NAME="qbi-work-session"
  local EXTERNAL_ID="qbi-victor-madera-access"
  local PROFILE_NAME="qbi"
  local CREDENTIALS_FILE="$HOME/.aws/credentials"

  echo "Asumiendo el rol..."
  local CREDENTIALS_JSON=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "$SESSION_NAME" --external-id "$EXTERNAL_ID")

  local AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS_JSON" | jq -r '.Credentials.AccessKeyId')
  local AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS_JSON" | jq -r '.Credentials.SecretAccessKey')
  local AWS_SESSION_TOKEN=$(echo "$CREDENTIALS_JSON" | jq -r '.Credentials.SessionToken')

  if [ "$AWS_ACCESS_KEY_ID" = "null" ] || [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "Error: No se pudieron obtener las credenciales. Revisa permisos y parámetros."
    return 1
  fi

  mkdir -p "$(dirname "$CREDENTIALS_FILE")"
  echo "Actualizando perfil [$PROFILE_NAME] en $CREDENTIALS_FILE..."

  if command -v crudini >/dev/null 2>&1; then
    crudini --set "$CREDENTIALS_FILE" "$PROFILE_NAME" aws_access_key_id "$AWS_ACCESS_KEY_ID"
    crudini --set "$CREDENTIALS_FILE" "$PROFILE_NAME" aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
    crudini --set "$CREDENTIALS_FILE" "$PROFILE_NAME" aws_session_token "$AWS_SESSION_TOKEN"
    crudini --set "$CREDENTIALS_FILE" "$PROFILE_NAME" region "us-east-1"
  else
    awk -v profile="[$PROFILE_NAME]" '
      BEGIN {skip=0}
      $0 == profile {skip=1; next}
      /^\[.*\]/ {skip=0}
      !skip {print}
    ' "$CREDENTIALS_FILE" > "${CREDENTIALS_FILE}.tmp" && mv "${CREDENTIALS_FILE}.tmp" "$CREDENTIALS_FILE"

    {
      echo ""
      echo "[$PROFILE_NAME]"
      echo "aws_access_key_id = $AWS_ACCESS_KEY_ID"
      echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY"
      echo "aws_session_token = $AWS_SESSION_TOKEN"
      echo "region = us-east-1"
    } >> "$CREDENTIALS_FILE"
  fi

  export AWS_PROFILE="$PROFILE_NAME"
  echo "Perfil [$PROFILE_NAME] actualizado y activado en el entorno."
  echo ""
  echo "Para comprobar el perfil, ejecuta:"
  echo "aws sts get-caller-identity --profile $PROFILE_NAME"
}

# Función para crear y activar un entorno virtual pyenv local en la carpeta actual.
# Uso: pyenv_new_local_env [<version_python>]
#   <version_python>: Opcional. Indica la versión de Python a usar para crear el entorno.
#                    Si no se proporciona, se usa la versión LTS (ejemplo: 3.11.8).
#
# La función:
# 1. Verifica que pyenv esté instalado y en el PATH.
# 2. Determina el nombre del entorno basado en la carpeta actual.
# 3. Usa la versión indicada o la versión LTS por defecto.
# 4. Crea el entorno virtual con pyenv-virtualenv.
# 5. Establece el entorno local para la carpeta actual.
# 6. Muestra un mensaje confirmando la creación y activación del entorno.
pyenv_create_activate_venv() {
  if ! command -v pyenv &> /dev/null; then
    echo "pyenv no está instalado o no está en el PATH"
    return 1
  fi

  local env_name=$(basename "$PWD")
  local python_version=${1:-3.11.8}

  if ! pyenv versions --bare | grep -q "^${python_version}\$"; then
    echo "Instalando Python $python_version..."
    pyenv install "$python_version"
  fi

  pyenv virtualenv "$python_version" "$env_name"
  pyenv local "$env_name"

  # Crear un venv estándar dentro del entorno pyenv para evitar restricciones
  ~/.pyenv/versions/$env_name/bin/python -m venv .venv
  source .venv/bin/activate

  echo "Entorno pyenv virtual '$env_name' creado y activado con Python $python_version en el directorio local."
  echo "Entorno venv adicional '.venv' creado y activado."
}

