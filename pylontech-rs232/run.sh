#!/usr/bin/env bash
set -euo pipefail

echo "### RUN.SH PYLONTECH RS232 HAOS START ###"

if [ -f /usr/lib/bashio/bashio.sh ]; then
  # shellcheck disable=SC1091
  source /usr/lib/bashio/bashio.sh
  logi(){ bashio::log.info "$1"; }
  logw(){ bashio::log.warning "$1"; }
  loge(){ bashio::log.error "$1"; }
else
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
ADDON_FLOWS_VERSION="/addon/flows_version.txt"
DATA_FLOWS_VERSION="/data/flows_version.txt"

mkdir -p /data
mkdir -p /share
mkdir -p /config/dashboards
mkdir -p /data/pylontech-rs232-haos

# ============================================================
# Helpers
# ============================================================
jq_str_or() {
  local jq_expr="$1"
  local fallback="$2"
  jq -r "($jq_expr // \"\") | if (type==\"string\" and length>0) then . else \"$fallback\" end" "$OPTS"
}

jq_int_or() {
  local jq_expr="$1"
  local fallback="$2"
  jq -r "($jq_expr // $fallback) | tonumber" "$OPTS" 2>/dev/null || echo "$fallback"
}

sanitize_transport() {
  local v="$1"
  case "$v" in
    serial) echo "serial" ;;
    gateway|tcp) echo "tcp" ;;
    *) echo "serial" ;;
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
}

# ============================================================
# Read add-on config
# ============================================================
LINK="$(bashio::config 'link')"
SERIAL_PORT="$(bashio::config 'serial_port')"
GATEWAY_HOST="$(bashio::config 'gateway_host')"
GATEWAY_PORT="$(bashio::config 'gateway_port')"

MQTT_HOST="$(bashio::config 'mqtt_host')"
MQTT_PORT="$(bashio::config 'mqtt_port')"
MQTT_USER="$(bashio::config 'mqtt_user')"
MQTT_PASS="$(bashio::config 'mqtt_pass')"
MQTT_BASE_TOPIC="$(bashio::config 'mqtt_base_topic')"
MQTT_CLIENT_ID="$(bashio::config 'mqtt_client_id')"

PREMIUM_KEY="$(bashio::config 'premium_key')"

DASHBOARD_CUSTOM_CARDS_INSTALLED="$(bashio::config 'dashboard_custom_cards_installed')"

SEND_BIP="$(bashio::config 'send_bip')"
COMM_DEBUG="$(bashio::config 'communication_debug')"

TIMEZONE_MODE="$(bashio::config 'timezone_mode')"
TIMEZONE_CUSTOM="$(bashio::config 'timezone_custom')"

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

if [ -z "${MQTT_HOST}" ]; then
  loge "mqtt_host vide. Renseigne-le dans la config add-on."
  exit 1
fi

if [ -z "${MQTT_USER}" ] || [ -z "${MQTT_PASS}" ]; then
  loge "mqtt_user ou mqtt_pass vide. Renseigne-les dans la config add-on."
  exit 1
fi

# ============================================================
# Build /data/options.json expected by the flow
# ============================================================
jq -n \
  --arg pylontech_path "${SERIAL_PORT}" \
  --argjson use_gateway "$([ "$TRANSPORT" = "tcp" ] && echo true || echo false)" \
  --arg gateway_ip "${GATEWAY_HOST}" \
  --argjson gateway_port "${GATEWAY_PORT}" \
  --argjson communication_debug "${COMM_DEBUG}" \
  --arg mqttadresse "${MQTT_HOST}" \
  --argjson mqttport "${MQTT_PORT}" \
  --arg mqttuser "${MQTT_USER}" \
  --arg mqttpass "${MQTT_PASS}" \
  --arg mqtt_client_id "${MQTT_CLIENT_ID}" \
  --arg mqtt_base_topic "${MQTT_BASE_TOPIC}" \
  --argjson Send_bip "${SEND_BIP}" \
  --arg premium_license "${PREMIUM_KEY}" \
  --argjson dashboard_custom_cards_installed "${DASHBOARD_CUSTOM_CARDS_INSTALLED}" \
  --arg timezone_mode "${TIMEZONE_MODE}" \
  --arg timezone_custom "${TIMEZONE_CUSTOM}" \
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
INSTALL_ID_FILE="/data/pylontech_rs232_install_id"

if [ ! -f "$INSTALL_ID_FILE" ]; then
  cat /proc/sys/kernel/random/uuid | tr -d '-' > "$INSTALL_ID_FILE"
  logi "Premium: nouvel install_id généré"
fi

PYLONTECH_RS232_INSTALL_ID="$(tr -d '\n\r' < "$INSTALL_ID_FILE")"
PYLONTECH_RS232_PREMIUM_KEY="$(jq -r '.premium_license // ""' "$OPTS")"

export PYLONTECH_RS232_INSTALL_ID
export PYLONTECH_RS232_PREMIUM_KEY

# compat éventuelle
export SMARTPHOTON_INSTALL_ID="$PYLONTECH_RS232_INSTALL_ID"
export SMARTPHOTON_PREMIUM_KEY="$PYLONTECH_RS232_PREMIUM_KEY"

logi "Premium install_id=${PYLONTECH_RS232_INSTALL_ID}"

# ============================================================
# Dashboard flag
# ============================================================
export DASHBOARD_CUSTOM_CARDS_INSTALLED

# ============================================================
# Timezone
# ============================================================
if [ "$TIMEZONE_MODE" = "CUSTOM" ]; then
  ADDON_TIMEZONE="$TIMEZONE_CUSTOM"
else
  ADDON_TIMEZONE="$TIMEZONE_MODE"
fi

if [ -z "${ADDON_TIMEZONE:-}" ] || [ "$ADDON_TIMEZONE" = "null" ]; then
  ADDON_TIMEZONE="UTC"
fi

export ADDON_TIMEZONE

# ============================================================
# flows.json versioning
# ============================================================
ADDON_VERSION="$(cat "$ADDON_FLOWS_VERSION" 2>/dev/null || echo '0.0.0')"
INSTALLED_VERSION="$(cat "$DATA_FLOWS_VERSION" 2>/dev/null || echo '')"

if [ ! -f "$FLOWS" ] || [ "$INSTALLED_VERSION" != "$ADDON_VERSION" ]; then
  logi "Mise à jour flows : ${INSTALLED_VERSION:-aucun} -> $ADDON_VERSION"
  cp "$ADDON_FLOWS" "$FLOWS"
  echo "$ADDON_VERSION" > "$DATA_FLOWS_VERSION"
else
  logi "flows.json à jour (v$ADDON_VERSION)"
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
logi "Config OK | MQTT=${MQTT_HOST}:${MQTT_PORT} | TZ=${ADDON_TIMEZONE} | transport=${TRANSPORT}"

if [ "$DASHBOARD_CUSTOM_CARDS_INSTALLED" != "true" ]; then
  logw "Dashboard: mode standard tant que dashboard_custom_cards_installed=false"
fi

# ============================================================
# Start Node-RED
# ============================================================
logi "Starting Node-RED sur le port 1893..."
exec node-red --userDir /data --settings /addon/settings.js --port 1893
