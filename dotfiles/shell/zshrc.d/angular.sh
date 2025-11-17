# ng instalado globalmente
if command -v ng >/dev/null 2>&1; then
  source <(ng completion script)
fi

# Caso instalado en proyecto
if [ -f ./node_modules/.bin/ng ]; then
  source <(./node_modules/.bin/ng completion script)
fi

# Caso especifico para inTable
if [ -f ./web/node_modules/.bin/ng ]; then
  source <(./web/node_modules/.bin/ng completion script)
fi
