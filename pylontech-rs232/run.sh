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
tmp="/data/flows.tmp.json"

mkdir -p /data
mkdir -p /share
mkdir -p /config/dashboards
mkdir -p /data/pylontech-rs232-haos

# ============================================================
# Helpers
# ============================================================
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

update_serial_config_by_name() {
  local node_name="$1"
  local serial_value="$2"

  local exists
  exists="$(jq -r --arg name "$node_name" '.[] | select(.type=="serial-port" and .name==$name) | .name' /data/flows.json 2>/dev/null || echo "")"

  if [ -z "$exists" ]; then
    logw "Noeud serial-port name '$node_name' introuvable dans flows.json"
    return 0
  fi

  jq --arg name "$node_name" --arg port "$serial_value" '
    map(
      if .type=="serial-port" and .name == $name
      then .serialport = $port
      else .
      end
    )
  ' /data/flows.json > "$tmp" && mv "$tmp" /data/flows.json
}

patch_mqtt_broker_by_name() {
  local broker_name="$1"
  local host="$2"
  local port="$3"
  local user="$4"

  if ! jq -e --arg name "$broker_name" '.[] | select(.type=="mqtt-broker" and .name==$name)' /data/flows.json >/dev/null 2>&1; then
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
    ' /data/flows.json > "$tmp" && mv "$tmp" /data/flows.json
}

build_flows_cred_for_broker() {
  local broker_name="$1"
  local mqtt_user="$2"
  local mqtt_pass="$3"

  local broker_id
  broker_id="$(jq -r --arg name "$broker_name" '.[] | select(.type=="mqtt-broker" and .name==$name) | .id' /data/flows.json)"

  if [ -z "$broker_id" ] || [ "$broker_id" = "null" ]; then
    loge "Impossible de récupérer l'ID du node mqtt-broker '$broker_name'"
    exit 1
  fi

  rm -f /data/flows_cred.json

  jq -n \
    --arg id "$broker_id" \
    --arg user "$mqtt_user" \
    --arg pass "$mqtt_pass" \
    '{($id): {"user": $user, "password": $pass}}' \
    > /data/flows_cred.json
}

# ============================================================
# Build /data/options.json from add-on config
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

jq -n \
  --arg link "${LINK}" \
  --arg serial_port "${SERIAL_PORT}" \
  --arg gateway_host "${GATEWAY_HOST}" \
  --argjson gateway_port "${GATEWAY_PORT}" \
  --arg mqtt_host "${MQTT_HOST}" \
  --argjson mqtt_port "${MQTT_PORT}" \
  --arg mqtt_user "${MQTT_USER}" \
  --arg mqtt_pass "${MQTT_PASS}" \
  --arg mqtt_base_topic "${MQTT_BASE_TOPIC}" \
  --arg mqtt_client_id "${MQTT_CLIENT_ID}" \
  --arg premium_key "${PREMIUM_KEY}" \
  --argjson dashboard_custom_cards_installed "${DASHBOARD_CUSTOM_CARDS_INSTALLED}" \
  --argjson send_bip "${SEND_BIP}" \
  --argjson communication_debug "${COMM_DEBUG}" \
  --arg timezone_mode "${TIMEZONE_MODE}" \
  --arg timezone_custom "${TIMEZONE_CUSTOM}" \
'{
  pylontech_path: $serial_port,
  use_gateway: ($link == "gateway"),
  gateway_ip: $gateway_host,
  gateway_port: $gateway_port,
  communication_debug: $communication_debug,

  mqttadresse: $mqtt_host,
  mqttport: $mqtt_port,
  mqttuser: $mqtt_user,
  mqttpass: $mqtt_pass,
  mqtt_client_id: $mqtt_client_id,
  mqtt_base_topic: $mqtt_base_topic,

  Send_bip: $send_bip,

  premium_license: $premium_key,

  dashboard_custom_cards_installed: $dashboard_custom_cards_installed,

  timezone_mode: $timezone_mode,
  timezone_custom: $timezone_custom
}' > "$OPTS"

if [ ! -f "$OPTS" ]; then
  loge "Impossible de générer /data/options.json"
  exit 1
fi

# ============================================================
# PREMIUM
# ============================================================
INSTANCE_FILE="/data/pylontech_rs232_instance_id"

if [ ! -f "$INSTANCE_FILE" ]; then
  cat /proc/sys/kernel/random/uuid > "$INSTANCE_FILE"
  logi "Premium: nouvel instance_id généré"
fi

PYLONTECH_RS232_INSTANCE_ID="$(tr -d '\n\r' < "$INSTANCE_FILE")"
PYLONTECH_RS232_PREMIUM_KEY="$(jq -r '.premium_license // ""' "$OPTS")"

export PYLONTECH_RS232_INSTANCE_ID
export PYLONTECH_RS232_PREMIUM_KEY

# compat éventuelle avec une future logique proche Smart Voltronic
export SMARTPHOTON_INSTANCE_ID="$PYLONTECH_RS232_INSTANCE_ID"
export SMARTPHOTON_PREMIUM_KEY="$PYLONTECH_RS232_PREMIUM_KEY"

# ============================================================
# DASHBOARD FLAG
# ============================================================
DASHBOARD_CUSTOM_CARDS_INSTALLED="$(jq -r '.dashboard_custom_cards_installed // false' "$OPTS")"
export DASHBOARD_CUSTOM_CARDS_INSTALLED

# ============================================================
# MQTT
# ============================================================
MQTT_HOST="$(jq_str_or '.mqttadresse' '')"
MQTT_PORT="$(jq_int_or '.mqttport' 1883)"
MQTT_USER="$(jq -r '.mqttuser // ""' "$OPTS")"
MQTT_PASS="$(jq -r '.mqttpass // ""' "$OPTS")"

if [ -z "${MQTT_HOST}" ]; then
  loge "mqtt_host vide. Renseigne-le dans la config add-on."
  exit 1
fi

if [ -z "${MQTT_USER}" ] || [ -z "${MQTT_PASS}" ]; then
  loge "mqtt_user ou mqtt_pass vide. Renseigne-les dans la config add-on."
  exit 1
fi

# ============================================================
# Timezone
# ============================================================
TZ_MODE="$(jq -r '.timezone_mode // "UTC"' "$OPTS")"
TZ_CUSTOM="$(jq -r '.timezone_custom // "UTC"' "$OPTS")"

if [ "$TZ_MODE" = "CUSTOM" ]; then
  ADDON_TIMEZONE="$TZ_CUSTOM"
else
  ADDON_TIMEZONE="$TZ_MODE"
fi

if [ -z "${ADDON_TIMEZONE:-}" ] || [ "$ADDON_TIMEZONE" = "null" ]; then
  ADDON_TIMEZONE="UTC"
fi

export ADDON_TIMEZONE

# ============================================================
# Transport
# ============================================================
LINK_MODE_RAW="$(jq -r '.use_gateway // false' "$OPTS")"
if [ "$LINK_MODE_RAW" = "true" ]; then
  TRANSPORT="tcp"
else
  TRANSPORT="serial"
fi

SERIAL_PATH="$(jq -r '.pylontech_path // ""' "$OPTS")"
GATEWAY_HOST_CFG="$(jq -r '.gateway_ip // ""' "$OPTS")"
GATEWAY_PORT_CFG="$(jq_int_or '.gateway_port' 8899)"

if [ "$TRANSPORT" = "serial" ]; then
  if ! is_valid_serial_port "$SERIAL_PATH"; then
    loge "Port série invalide : $SERIAL_PATH"
    exit 1
  fi
else
  if ! is_valid_host "$GATEWAY_HOST_CFG"; then
    loge "gateway_host invalide : $GATEWAY_HOST_CFG"
    exit 1
  fi
  if ! is_valid_port "$GATEWAY_PORT_CFG"; then
    loge "gateway_port invalide : $GATEWAY_PORT_CFG"
    exit 1
  fi
fi

export TRANSPORT
export SERIAL_PATH
export GATEWAY_HOST_CFG
export GATEWAY_PORT_CFG

# ============================================================
# flows.json update
# ============================================================
ADDON_FLOWS_VERSION="$(cat /addon/flows_version.txt 2>/dev/null || echo '0.0.0')"
INSTALLED_VERSION="$(cat /data/flows_version.txt 2>/dev/null || echo '')"

if [ ! -f /data/flows.json ] || [ "$INSTALLED_VERSION" != "$ADDON_FLOWS_VERSION" ]; then
  logi "Mise à jour flows : ${INSTALLED_VERSION:-aucun} -> $ADDON_FLOWS_VERSION"
  cp /addon/flows.json /data/flows.json
  echo "$ADDON_FLOWS_VERSION" > /data/flows_version.txt
else
  logi "flows.json à jour (v$ADDON_FLOWS_VERSION)"
fi

# ============================================================
# Patch serial port node by exact flow node name
# ============================================================
update_serial_config_by_name "Pylontech RS232" "$SERIAL_PATH"

# ============================================================
# MQTT broker patch by exact flow broker name
# ============================================================
patch_mqtt_broker_by_name "HAOS Mosquitto" "$MQTT_HOST" "$MQTT_PORT" "$MQTT_USER"
build_flows_cred_for_broker "HAOS Mosquitto" "$MQTT_USER" "$MQTT_PASS"

# ============================================================
# Summary log
# ============================================================
logi "Config OK | MQTT=${MQTT_HOST}:${MQTT_PORT} | TZ=${ADDON_TIMEZONE} | transport=${TRANSPORT}"

if [ "$DASHBOARD_CUSTOM_CARDS_INSTALLED" != "true" ]; then
  logw "Dashboard: mode standard tant que dashboard_custom_cards_installed=false"
fi

# ============================================================
# Start Node-RED
# ============================================================
logi "Starting Node-RED sur le port 1892..."
exec node-red --userDir /data --settings /addon/settings.js
