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
