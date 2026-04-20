#!/usr/bin/env bash
set -euo pipefail

echo "### RUN.SH PYLONTECH RS232 HAOS START ###"

if [ -f /usr/lib/bashio/bashio.sh ]; then
  # shellcheck disable=SC1091
  source /usr/lib/bashio/bashio.sh
  HAS_BASHIO="true"
  logi(){ bashio::log.info "$1"; }
  logw(){ bashio::log.warning "$1"; }
  loge(){ bashio::log.error "$1"; }
else
  HAS_BASHIO="false"
  logi(){ echo "[INFO] $1"; }
  logw(){ echo "[WARN] $1"; }
  loge(){ echo "[ERROR] $1"; }
fi

logi "Pylontech RS232 HAOS: init..."

OPTS="/data/options.json"
FLOWS="/data/flows.json"
FLOWS_CRED="/data/flows_cred.json"
TMP="/data/flows.tmp.json"
ADDON_FLOWS="/addon/flows.json"
ADDON_FLOWS_VERSION_FILE="/addon/flows_version.txt"
DATA_FLOWS_VERSION_FILE="/data/flows_version.txt"
INSTALL_ID_FILE="/data/pylontech_rs232_install_id"

mkdir -p /data
mkdir -p /share
mkdir -p /config
mkdir -p /config/dashboards
mkdir -p /data/pylontech-rs232-haos

# ============================================================
# Helpers
# ============================================================
trim() {
  local s="${1:-}"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

sanitize_transport() {
  local v
  v="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$v" in
    serial) echo "serial" ;;
    gateway|tcp) echo "tcp" ;;
    *) echo "serial" ;;
  esac
}

normalize_bool() {
  local v="${1:-false}"
  case "$v" in
    true|True|TRUE|1|yes|Yes|YES|on|ON) echo "true" ;;
    *) echo "false" ;;
  esac
}

normalize_dashboard_language() {
  local v="${1:-fr}"
  case "$v" in
    fr|FR) echo "fr" ;;
    en|EN) echo "en" ;;
    *) echo "fr" ;;
  esac
}

is_valid_serial_port() {
  local p="$1"
  [ -n "$p" ] || return 1
  case "$p" in
    *CHANGE-ME*) return 1 ;;
    /dev/serial/*|/dev/tty*) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_host() {
  local h="$1"
  [ -n "$h" ] || return 1
  case "$h" in
    *CHANGE-ME*) return 1 ;;
    *) return 0 ;;
  esac
}

is_valid_port() {
  local p="$1"
  [[ "$p" =~ ^[0-9]+$ ]] || return 1
  [ "$p" -ge 1 ] && [ "$p" -le 65535 ]
}

cfg() {
  local key="$1"
  local fallback="${2:-}"

  if [ "$HAS_BASHIO" = "true" ]; then
    local value
    value="$(bashio::config "$key" 2>/dev/null || true)"
    if [ -n "${value:-}" ] && [ "$value" != "null" ]; then
      echo "$value"
    else
      echo "$fallback"
    fi
  else
    echo "$fallback"
  fi
}

timezone_exists() {
  local tz="$1"
  [ -n "$tz" ] && [ -f "/usr/share/zoneinfo/$tz" ]
}

normalize_timezone() {
  local raw tz upper offset sign hours

  raw="$(trim "${1:-}")"
  [ -z "$raw" ] && { echo "UTC"; return; }

  tz="$raw"
  upper="$(printf '%s' "$tz" | tr '[:lower:]' '[:upper:]')"

  case "$upper" in
    UTC|ETC/UTC|GMT) echo "UTC"; return ;;
    EUROPE/FRANCE|FRANCE) echo "Europe/Paris"; return ;;
    BELGIUM) echo "Europe/Brussels"; return ;;
    GERMANY) echo "Europe/Berlin"; return ;;
    SPAIN) echo "Europe/Madrid"; return ;;
    ITALY) echo "Europe/Rome"; return ;;
    UK|ENGLAND|BRITAIN|GREAT\ BRITAIN) echo "Europe/London"; return ;;
    SOUTH\ AFRICA|AFRICA/SOUTH\ AFRICA|JOHANNESBURG) echo "Africa/Johannesburg"; return ;;
    MOROCCO) echo "Africa/Casablanca"; return ;;
    NEW\ YORK|US/EASTERN|EST) echo "America/New_York"; return ;;
    CHICAGO|US/CENTRAL|CST) echo "America/Chicago"; return ;;
    LOS\ ANGELES|US/PACIFIC|PST) echo "America/Los_Angeles"; return ;;
    MONTREAL) echo "America/Montreal"; return ;;
    DUBAI|UAE) echo "Asia/Dubai"; return ;;
    TOKYO|JAPAN) echo "Asia/Tokyo"; return ;;
    SYDNEY) echo "Australia/Sydney"; return ;;
  esac

  if printf '%s' "$upper" | grep -Eq '^(UTC|GMT)[[:space:]]*[+-][0-9]{1,2}(:00)?$'; then
    offset="$(printf '%s' "$upper" | sed -E 's/^(UTC|GMT)[[:space:]]*([+-][0-9]{1,2})(:00)?$/\2/')"
    sign="${offset:0:1}"
    hours="${offset:1}"
    hours="$(printf '%d' "$hours" 2>/dev/null || echo "")"
    if [ -n "$hours" ] && [ "$hours" -ge 0 ] && [ "$hours" -le 14 ]; then
      if [ "$sign" = "+" ]; then
        echo "Etc/GMT-$hours"
      else
        echo "Etc/GMT+$hours"
      fi
      return
    fi
  fi

  if printf '%s' "$upper" | grep -Eq '^[+-][0-9]{1,2}$'; then
    sign="${upper:0:1}"
    hours="${upper:1}"
    hours="$(printf '%d' "$hours" 2>/dev/null || echo "")"
    if [ -n "$hours" ] && [ "$hours" -ge 0 ] && [ "$hours" -le 14 ]; then
      if [ "$sign" = "+" ]; then
        echo "Etc/GMT-$hours"
      else
        echo "Etc/GMT+$hours"
      fi
      return
    fi
  fi

  echo "$tz"
}

validate_timezone_or_fallback() {
  local tz="$1"
  if timezone_exists "$tz"; then
    echo "$tz"
  else
    echo "UTC"
  fi
}

install_build_tools_if_needed() {
  if command -v gcc >/dev/null 2>&1 && command -v g++ >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
    logi "Build tools déjà présents"
    return 0
  fi

  logw "Build tools absents, tentative d'installation runtime..."
  if apk add --no-cache python3 make g++; then
    logi "Build tools installés avec succès"
    return 0
  fi

  logw "Impossible d'installer les build tools runtime, on continue sans fallback compilation"
  return 1
}

install_node_red_nodes() {
  export HOME="/data"
  export npm_config_cache="/data/.npm"
  export npm_config_update_notifier="false"
  export npm_config_fund="false"
  export npm_config_audit="false"

  mkdir -p /data
  cd /data

  if [ ! -f package.json ]; then
    logi "Initialisation package.json dans /data"
    npm init -y >/dev/null 2>&1
  fi

  local required_nodes=(
    "node-red-node-serialport"
  )

  local node
  for node in "${required_nodes[@]}"; do
    if [ -d "/data/node_modules/$node" ]; then
      logi "Node déjà installé: $node"
      continue
    fi

    logi "Installation du node Node-RED: $node"
    if npm install --unsafe-perm --no-audit --no-fund "$node"; then
      logi "Node installé avec succès: $node"
      continue
    fi

    logw "Échec installation simple pour $node, tentative avec build tools"
    install_build_tools_if_needed || true

    if npm install --unsafe-perm --no-audit --no-fund "$node"; then
      logi "Node installé avec succès après fallback: $node"
    else
      loge "Échec installation node: $node"
      exit 1
    fi
  done
}

patch_serial_node_by_name() {
  local node_name="$1"
  local serial_value="$2"

  local exists
  exists="$(jq -r --arg name "$node_name" '.[] | select(.type=="serial-port" and .name==$name) | .name' "$FLOWS" 2>/dev/null || true)"

  if [ -z "$exists" ]; then
    logw "Noeud serial-port '$node_name' introuvable dans flows.json"
    return 0
  fi

  jq --arg name "$node_name" --arg port "$serial_value" '
    map(
      if .type=="serial-port" and .name==$name
      then .serialport=$port
      else .
      end
    )
  ' "$FLOWS" > "$TMP" && mv "$TMP" "$FLOWS"

  logi "Port série mis à jour: ${node_name} -> ${serial_value}"
}

patch_mqtt_broker_by_name() {
  local broker_name="$1"
  local host="$2"
  local port="$3"
  local user="$4"

  local exists
  exists="$(jq -r --arg name "$broker_name" '.[] | select(.type=="mqtt-broker" and .name==$name) | .name' "$FLOWS" 2>/dev/null || true)"

  if [ -z "$exists" ]; then
    loge "Aucun mqtt-broker nommé '$broker_name' trouvé dans flows.json"
    exit 1
  fi

  jq \
    --arg name "$broker_name" \
    --arg host "$host" \
    --arg port "$port" \
    --arg user "$user" \
    '
    map(
      if .type=="mqtt-broker" and .name==$name
      then
        .broker=$host
        | .port=$port
        | .user=$user
      else .
      end
    )
  ' "$FLOWS" > "$TMP" && mv "$TMP" "$FLOWS"

  logi "Broker MQTT patché: ${broker_name} -> ${host}:${port}"
}

build_flows_cred_for_broker() {
  local broker_name="$1"
  local mqtt_user="$2"
  local mqtt_pass="$3"

  local broker_id
  broker_id="$(jq -r --arg name "$broker_name" '.[] | select(.type=="mqtt-broker" and .name==$name) | .id' "$FLOWS" 2>/dev/null || true)"

  if [ -z "$broker_id" ] || [ "$broker_id" = "null" ]; then
    loge "Impossible de récupérer l'ID du node mqtt-broker '$broker_name'"
    exit 1
  fi

  rm -f "$FLOWS_CRED"

  jq -n \
    --arg id "$broker_id" \
    --arg user "$mqtt_user" \
    --arg pass "$mqtt_pass" \
    '{($id): {"user": $user, "password": $pass}}' \
    > "$FLOWS_CRED"

  logi "flows_cred.json créé pour broker '${broker_name}'"
}

# ============================================================
# Read add-on config
# ============================================================
LINK="$(cfg 'link' 'serial')"
SERIAL_PORT="$(cfg 'serial_port' '/dev/serial/by-id/CHANGE-ME')"
GATEWAY_HOST="$(cfg 'gateway_host' '')"
GATEWAY_PORT="$(cfg 'gateway_port' '8899')"

MQTT_HOST="$(cfg 'mqtt_host' 'core-mosquitto')"
MQTT_PORT="$(cfg 'mqtt_port' '1883')"
MQTT_USER="$(cfg 'mqtt_user' '')"
MQTT_PASS="$(cfg 'mqtt_pass' '')"
MQTT_BASE_TOPIC="$(cfg 'mqtt_base_topic' 'pylontech1')"
MQTT_CLIENT_ID="$(cfg 'mqtt_client_id' 'nodered_pylontech')"

PREMIUM_KEY="$(cfg 'premium_key' '')"

DASHBOARD_CUSTOM_CARDS_INSTALLED_RAW="$(cfg 'dashboard_custom_cards_installed' 'false')"
DASHBOARD_CUSTOM_CARDS_INSTALLED="$(normalize_bool "$DASHBOARD_CUSTOM_CARDS_INSTALLED_RAW")"
DASHBOARD_LANGUAGE_RAW="$(cfg 'dashboard_language' 'fr')"
DASHBOARD_LANGUAGE="$(normalize_dashboard_language "$DASHBOARD_LANGUAGE_RAW")"

SEND_BIP_RAW="$(cfg 'send_bip' 'true')"
SEND_BIP="$(normalize_bool "$SEND_BIP_RAW")"
COMM_DEBUG_RAW="$(cfg 'communication_debug' 'false')"
COMM_DEBUG="$(normalize_bool "$COMM_DEBUG_RAW")"

TIMEZONE_MODE_RAW="$(cfg 'timezone_mode' 'Europe/Paris')"
TIMEZONE_CUSTOM_RAW="$(cfg 'timezone_custom' '')"

TRANSPORT="$(sanitize_transport "$LINK")"

# ============================================================
# Basic validation
# ============================================================
if [ "$TRANSPORT" = "serial" ]; then
  if ! is_valid_serial_port "$SERIAL_PORT"; then
    loge "Port série invalide : $SERIAL_PORT"
    exit 1
  fi
else
  if ! is_valid_host "$GATEWAY_HOST"; then
    loge "gateway_host invalide : $GATEWAY_HOST"
    exit 1
  fi
  if ! is_valid_port "$GATEWAY_PORT"; then
    loge "gateway_port invalide : $GATEWAY_PORT"
    exit 1
  fi
fi

if [ -z "$MQTT_HOST" ]; then
  loge "mqtt_host vide. Renseigne-le dans la config add-on."
  exit 1
fi

if [ -z "$MQTT_USER" ] || [ -z "$MQTT_PASS" ]; then
  loge "mqtt_user ou mqtt_pass vide. Renseigne-les dans la config add-on."
  exit 1
fi

# ============================================================
# Timezone
# ============================================================
if [ "$TIMEZONE_MODE_RAW" = "CUSTOM" ]; then
  TZ_REQUESTED="$TIMEZONE_CUSTOM_RAW"
else
  TZ_REQUESTED="$TIMEZONE_MODE_RAW"
fi

TZ_REQUESTED="$(trim "$TZ_REQUESTED")"
TZ_NORMALIZED="$(normalize_timezone "$TZ_REQUESTED")"
ADDON_TIMEZONE="$(validate_timezone_or_fallback "$TZ_NORMALIZED")"

TIMEZONE_VALID="true"
if [ "$ADDON_TIMEZONE" != "$TZ_NORMALIZED" ]; then
  TIMEZONE_VALID="false"
fi

if [ -z "${ADDON_TIMEZONE:-}" ] || [ "$ADDON_TIMEZONE" = "null" ]; then
  ADDON_TIMEZONE="UTC"
  TIMEZONE_VALID="false"
fi

export TZ="$ADDON_TIMEZONE"
export ADDON_TIMEZONE
export ADDON_TIMEZONE_REQUESTED="${TZ_REQUESTED:-UTC}"
export ADDON_TIMEZONE_NORMALIZED="$TZ_NORMALIZED"
export ADDON_TIMEZONE_VALID="$TIMEZONE_VALID"

logi "Timezone requested: ${ADDON_TIMEZONE_REQUESTED}"
logi "Timezone normalized: ${ADDON_TIMEZONE_NORMALIZED}"
if [ "$ADDON_TIMEZONE_VALID" = "true" ]; then
  logi "Timezone active: ${ADDON_TIMEZONE}"
else
  logw "Timezone invalide ou inconnue -> fallback UTC (requested=${ADDON_TIMEZONE_REQUESTED}, normalized=${ADDON_TIMEZONE_NORMALIZED})"
  logi "Timezone active: ${ADDON_TIMEZONE}"
fi

# ============================================================
# Build /data/options.json expected by the flow
# ============================================================
jq -n \
  --arg pylontech_path "$SERIAL_PORT" \
  --argjson use_gateway "$([ "$TRANSPORT" = "tcp" ] && echo true || echo false)" \
  --arg gateway_ip "$GATEWAY_HOST" \
  --argjson gateway_port "$GATEWAY_PORT" \
  --argjson communication_debug "$COMM_DEBUG" \
  --arg mqttadresse "$MQTT_HOST" \
  --argjson mqttport "$MQTT_PORT" \
  --arg mqttuser "$MQTT_USER" \
  --arg mqttpass "$MQTT_PASS" \
  --arg mqtt_client_id "$MQTT_CLIENT_ID" \
  --arg mqtt_base_topic "$MQTT_BASE_TOPIC" \
  --argjson Send_bip "$SEND_BIP" \
  --arg premium_license "$PREMIUM_KEY" \
  --argjson dashboard_custom_cards_installed "$DASHBOARD_CUSTOM_CARDS_INSTALLED" \
  --arg dashboard_language "$DASHBOARD_LANGUAGE" \
  --arg timezone_mode "$TIMEZONE_MODE_RAW" \
  --arg timezone_custom "$TIMEZONE_CUSTOM_RAW" \
'{
  pylontech_path: $pylontech_path,
  use_gateway: $use_gateway,
  gateway_ip: $gateway_ip,
  gateway_port: $gateway_port,
  communication_debug: $communication_debug,

  mqttadresse: $mqttadresse,
  mqttport: $mqttport,
  mqttuser: $mqttuser,
  mqttpass: $mqttpass,
  mqtt_client_id: $mqtt_client_id,
  mqtt_base_topic: $mqtt_base_topic,

  Send_bip: $Send_bip,

  premium_license: $premium_license,

  dashboard_custom_cards_installed: $dashboard_custom_cards_installed,
  dashboard_language: $dashboard_language,

  timezone_mode: $timezone_mode,
  timezone_custom: $timezone_custom
}' > "$OPTS"

if [ ! -f "$OPTS" ]; then
  loge "Impossible de générer /data/options.json"
  exit 1
fi

# ============================================================
# Premium env
# ============================================================
if [ ! -f "$INSTALL_ID_FILE" ]; then
  cat /proc/sys/kernel/random/uuid | tr -d '-' > "$INSTALL_ID_FILE"
  logi "Premium: nouvel install_id généré"
fi

PYLONTECH_RS232_INSTALL_ID="$(tr -d '\n\r' < "$INSTALL_ID_FILE")"
PYLONTECH_RS232_PREMIUM_KEY="$(jq -r '.premium_license // ""' "$OPTS")"

export PYLONTECH_RS232_INSTALL_ID
export PYLONTECH_RS232_PREMIUM_KEY

# Compat éventuelle
export SMARTPHOTON_INSTALL_ID="$PYLONTECH_RS232_INSTALL_ID"
export SMARTPHOTON_PREMIUM_KEY="$PYLONTECH_RS232_PREMIUM_KEY"

logi "Premium install_id=${PYLONTECH_RS232_INSTALL_ID}"
if [ -n "$PYLONTECH_RS232_PREMIUM_KEY" ]; then
  logi "Premium key: configured"
else
  logi "Premium key: not configured"
fi

# ============================================================
# Dashboard env
# ============================================================
export DASHBOARD_CUSTOM_CARDS_INSTALLED
export DASHBOARD_LANGUAGE
logi "Dashboard custom cards installed: $DASHBOARD_CUSTOM_CARDS_INSTALLED"
logi "Dashboard language: $DASHBOARD_LANGUAGE"

# ============================================================
# Node-RED modules install
# ============================================================
install_node_red_nodes

# ============================================================
# flows.json versioning
# ============================================================
ADDON_FLOWS_VERSION="$(cat "$ADDON_FLOWS_VERSION_FILE" 2>/dev/null || echo '0.0.0')"
INSTALLED_VERSION="$(cat "$DATA_FLOWS_VERSION_FILE" 2>/dev/null || echo '')"

if [ ! -f "$FLOWS" ] || [ "$INSTALLED_VERSION" != "$ADDON_FLOWS_VERSION" ]; then
  logi "Mise à jour flows : ${INSTALLED_VERSION:-aucun} -> $ADDON_FLOWS_VERSION"
  cp "$ADDON_FLOWS" "$FLOWS"
  echo "$ADDON_FLOWS_VERSION" > "$DATA_FLOWS_VERSION_FILE"
else
  logi "flows.json à jour (v$ADDON_FLOWS_VERSION)"
fi

# ============================================================
# Patch serial node
# ============================================================
patch_serial_node_by_name "Pylontech RS232" "$SERIAL_PORT"

# ============================================================
# Patch MQTT broker + credentials
# ============================================================
patch_mqtt_broker_by_name "HAOS Mosquitto" "$MQTT_HOST" "$MQTT_PORT" "$MQTT_USER"
build_flows_cred_for_broker "HAOS Mosquitto" "$MQTT_USER" "$MQTT_PASS"

# ============================================================
# Summary
# ============================================================
logi "Config OK | MQTT=${MQTT_HOST}:${MQTT_PORT} | TZ=${ADDON_TIMEZONE} | transport=${TRANSPORT} | dashboard_lang=${DASHBOARD_LANGUAGE}"

if [ "$DASHBOARD_CUSTOM_CARDS_INSTALLED" != "true" ]; then
  logw "Dashboard: mode fallback natif Home Assistant (dashboard_custom_cards_installed=false)"
else
  logi "Dashboard: mode premium custom cards activé"
fi

# ============================================================
# Start Node-RED
# ============================================================
export HOME="/data"
export NODE_PATH="/data/node_modules"
export TZ="$ADDON_TIMEZONE"

logi "Starting Node-RED sur le port 1893..."
exec node-red --userDir /data --settings /addon/settings.js --port 1893
