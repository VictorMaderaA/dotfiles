deploynarobial() {
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  if [ -n "$branch" ]; then
    ssh -t root@qdevweb.intraquiter "bash /home/deploy/deploy.sh \"$branch\""
  else
    ssh -t root@qdevweb.intraquiter "bash /home/deploy/deploy.sh"
  fi
}


# ============================================================================
# AWS CloudWatch Logs Search Function
# ============================================================================

# Función auxiliar: validar dependencias del sistema
__awscwl_check_dependencies() {
  local missing_deps=()

  if ! command -v aws &> /dev/null; then
    missing_deps+=("aws-cli")
  fi

  if ! command -v jq &> /dev/null; then
    missing_deps+=("jq")
  fi

  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "❌ Error: Dependencias faltantes: ${missing_deps[*]}"
    return 1
  fi

  return 0
}

# Función auxiliar: mostrar uso y aliases disponibles
__awscwl_show_usage() {
  cat << 'EOF'
❌ Uso: aws_cwlogs_search <log_group_alias> <texto1> [texto2...]

Aliases disponibles:
  gof      -> /aws/lambda/gof-integration-lambda (eu-central-1)
  default  -> /aws/lambda/DEMOSTRATCION_NO_FUNCIONAL-api (eu-west-1)

Ejemplos:
  aws_cwlogs_search gof "ERROR" "timeout"
  aws_cwlogs_search default "user@example.com"
EOF
}

# Función auxiliar: resolver alias a log group y región
__awscwl_resolve_alias() {
  local alias="$1"
  local log_group=""
  local region=""

  case "$alias" in
    prod|gof)
      log_group="/aws/lambda/gof-integration-lambda"
      region="eu-central-1"
      ;;
    default)
      log_group="/aws/lambda/DEMOSTRATCION_NO_FUNCIONAL-api"
      region="eu-west-1"
      ;;
    *)
      # Usar valor literal si no coincide con ningún alias
      log_group="$alias"
      region="${AWS_DEFAULT_REGION:-eu-west-1}"
      ;;
  esac

  # Retornar valores separados por pipe
  echo "${log_group}|${region}"
}

# Función auxiliar: buscar un texto en CloudWatch Logs
__awscwl_search_text() {
  local log_group="$1"
  local region="$2"
  local search_text="$3"

  start_time_ms=$(( ($(date +%s) - 30*24*60*60) * 1000 ))
  end_time_ms=$(( $(date +%s) * 1000 ))

  aws logs filter-log-events \
    --log-group-name "$log_group" \
    --filter-pattern "$search_text" \
    --region "$region" \
    --start-time "$start_time_ms" \
    --end-time "$end_time_ms" \
    --query 'events[].{stream:logStreamName, timestamp:timestamp}' \
    --output json 2>&1

}

# Función auxiliar: procesar y formatear resultados con jq
__awscwl_process_results() {
  local temp_file="$1"
  local total_searches="$2"

  jq -r --argjson total_searches "$total_searches" '
    # Agrupar eventos por stream para cada búsqueda
    def grouper(items):
      reduce items[] as $ev ({};
        .[$ev.stream] = (.[$ev.stream] // []) + [$ev.timestamp]
      );

    # Procesar todos los grupos de resultados
    map(grouper(.)) as $all_grouped |

    # Validar que existan grupos
    if ($all_grouped | length) == 0 then
      []
    else
      # Recopilar TODOS los streams únicos de TODAS las búsquedas
      ($all_grouped | map(keys) | add | unique) as $all_streams |

      # Para cada stream, calcular cuántas búsquedas lo contienen
      $all_streams | map(
        . as $stream |
        {
          stream: $stream,
          # Contar en cuántas búsquedas aparece este stream
          searches_found: ($all_grouped | map(has($stream)) | map(select(. == true)) | length),
          # Total de eventos en todas las búsquedas
          count: ($all_grouped | map(.[$stream] // []) | add | length),
          # Último evento (más reciente)
          last: ($all_grouped | map(.[$stream] // []) | add | max),
          # Primer evento (más antiguo)
          first: ($all_grouped | map(.[$stream] // []) | add | min)
        }
      ) |

      # Ordenar por: 1) número de búsquedas donde aparece, 2) número de coincidencias
      sort_by([-.searches_found, -.count]) |

      # Formatear salida
      map(
        "Stream: \(.stream)\n" +
        "  🔍 Búsquedas coincidentes: \(.searches_found)/\($total_searches)\n" +
        "  📈 Total coincidencias: \(.count)\n" +
        "  🕐 Primer evento: \(.first / 1000 | strftime("%Y-%m-%d %H:%M:%S"))\n" +
        "  🕑 Último evento: \(.last / 1000 | strftime("%Y-%m-%d %H:%M:%S"))\n" +
        "─────────────────────────────────────────────────────────────────"
      ) |
      join("\n")
    end
  ' "$temp_file"
}

# Función principal: buscar en CloudWatch Logs
aws_cwlogs_search() {
  # Validar número de argumentos
  if [ $# -lt 2 ]; then
    __awscwl_show_usage
    return 1
  fi

  # Validar dependencias
  if ! __awscwl_check_dependencies; then
    return 1
  fi

  # Resolver alias a log group y región
  local log_group_alias="$1"
  local resolved
  resolved=$(__awscwl_resolve_alias "$log_group_alias")
  local log_group="${resolved%|*}"
  local aws_region="${resolved#*|}"

  shift # Eliminar primer argumento (alias)
  local search_texts=("$@")
  local total_searches=${#search_texts[@]}

  # Mostrar información de búsqueda
  echo "🔍 Buscando en: $log_group"
  echo "🌍 Región: $aws_region"
  echo "📝 Textos: ${search_texts[*]}"
  echo ""

  # Array para almacenar resultados
  local -a all_results=()

  # Buscar cada texto
  for text in "${search_texts[@]}"; do
    echo "Buscando '$text'..."

    local result
    result=$(__awscwl_search_text "$log_group" "$aws_region" "$text")
    local search_exit=$?

    if [ $search_exit -ne 0 ]; then
      echo "❌ Error al buscar en CloudWatch:"
      echo "$result"
      return 1
    fi

    # Contar eventos encontrados
    local event_count
    event_count=$(echo "$result" | jq 'length')
    echo "  ✓ Encontrados $event_count eventos"

    all_results+=("$result")
  done

  echo ""
  echo "📊 Resultados (ordenados por coincidencias):"
  echo "─────────────────────────────────────────────────────────────────"

  # Crear archivo temporal para procesar resultados
  local temp_file
  temp_file=$(mktemp)

  # Escribir array JSON al archivo temporal
  printf '%s\n' "${all_results[@]}" | jq -s '.' > "$temp_file"

  # Procesar resultados con jq
  local final_result
  final_result=$(__awscwl_process_results "$temp_file" "$total_searches")
  local jq_exit=$?

  # Limpiar archivo temporal
  rm -f "$temp_file"

  # Mostrar resultados
  if [ $jq_exit -eq 0 ]; then
    if [ -n "$final_result" ]; then
      echo "$final_result"
      echo ""
      echo "✅ Búsqueda completada"
    else
      echo "ℹ️  No se encontraron resultados en ninguna búsqueda"
    fi
  else
    echo "❌ Error al procesar resultados con jq"
    echo "$final_result"
    return 1
  fi
}
