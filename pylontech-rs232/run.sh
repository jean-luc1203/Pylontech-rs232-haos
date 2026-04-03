#!/usr/bin/with-contenv bashio
set -euo pipefail

bashio::log.info "Starting Pylontech RS232 HAOS..."

USER_DIR="/data/node-red"
CONFIG_PATH="/data/options.json"
BUNDLED_FLOWS="/addon/flows.json"
ACTIVE_FLOWS="${USER_DIR}/flows.json"
BUNDLED_FLOWS_VERSION="/addon/flows_version.txt"
ACTIVE_FLOWS_VERSION="/data/flows_version.txt"
SETTINGS_FILE="/addon/settings.js"

mkdir -p "${USER_DIR}"
mkdir -p /data
mkdir -p /share

# --------------------------------------------------
# Read add-on options
# --------------------------------------------------
PYLONTECH_PATH="$(bashio::config 'pylontech_path')"
USE_GATEWAY="$(bashio::config 'use_gateway')"
GATEWAY_IP="$(bashio::config 'gateway_ip')"
GATEWAY_PORT="$(bashio::config 'gateway_port')"
COMM_DEBUG="$(bashio::config 'communication_debug')"

MQTT_HOST="$(bashio::config 'mqttadresse')"
MQTT_PORT="$(bashio::config 'mqttport')"
MQTT_USER="$(bashio::config 'mqttuser')"
MQTT_PASS="$(bashio::config 'mqttpass')"
MQTT_CLIENT_ID="$(bashio::config 'mqtt_client_id')"
MQTT_BASE_TOPIC="$(bashio::config 'mqtt_base_topic')"

SEND_BIP="$(bashio::config 'Send_bip')"

# --------------------------------------------------
# Basic validation
# --------------------------------------------------
if bashio::var.true "${USE_GATEWAY}"; then
    if [[ -z "${GATEWAY_IP}" ]]; then
        bashio::log.fatal "Gateway mode is enabled but gateway_ip is empty."
        exit 1
    fi
    bashio::log.info "Transport mode: gateway (${GATEWAY_IP}:${GATEWAY_PORT})"
else
    if [[ -z "${PYLONTECH_PATH}" ]]; then
        bashio::log.fatal "Serial mode is enabled but pylontech_path is empty."
        exit 1
    fi
    bashio::log.info "Transport mode: serial (${PYLONTECH_PATH})"
fi

if [[ -z "${MQTT_HOST}" ]]; then
    bashio::log.fatal "mqttadresse is empty."
    exit 1
fi

# --------------------------------------------------
# Build /data/options.json for Node-RED flow
# --------------------------------------------------
jq -n \
  --arg pylontech_path "${PYLONTECH_PATH}" \
  --argjson use_gateway "${USE_GATEWAY}" \
  --arg gateway_ip "${GATEWAY_IP}" \
  --argjson gateway_port "${GATEWAY_PORT}" \
  --argjson communication_debug "${COMM_DEBUG}" \
  --arg mqttadresse "${MQTT_HOST}" \
  --argjson mqttport "${MQTT_PORT}" \
  --arg mqttuser "${MQTT_USER}" \
  --arg mqttpass "${MQTT_PASS}" \
  --arg mqtt_client_id "${MQTT_CLIENT_ID}" \
  --arg mqtt_base_topic "${MQTT_BASE_TOPIC}" \
  --argjson Send_bip "${SEND_BIP}" \
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
  Send_bip: $Send_bip
}' > "${CONFIG_PATH}"

bashio::log.info "Generated ${CONFIG_PATH}"

# --------------------------------------------------
# Flow versioning
# --------------------------------------------------
COPY_FLOWS="false"

if [[ ! -f "${ACTIVE_FLOWS}" ]]; then
    bashio::log.info "No flows found in /data -> installing bundled flows.json"
    COPY_FLOWS="true"
elif [[ -f "${BUNDLED_FLOWS_VERSION}" ]]; then
    BUNDLED_VERSION="$(cat "${BUNDLED_FLOWS_VERSION}" 2>/dev/null || true)"
    ACTIVE_VERSION="$(cat "${ACTIVE_FLOWS_VERSION}" 2>/dev/null || true)"

    if [[ "${BUNDLED_VERSION}" != "${ACTIVE_VERSION}" ]]; then
        bashio::log.info "Flow version changed (${ACTIVE_VERSION} -> ${BUNDLED_VERSION})"
        COPY_FLOWS="true"
    fi
fi

if [[ "${COPY_FLOWS}" == "true" ]]; then
    cp -f "${BUNDLED_FLOWS}" "${ACTIVE_FLOWS}"

    if [[ -f "${BUNDLED_FLOWS_VERSION}" ]]; then
        cp -f "${BUNDLED_FLOWS_VERSION}" "${ACTIVE_FLOWS_VERSION}"
    fi
fi

# --------------------------------------------------
# Supervisor token
# --------------------------------------------------
if bashio::supervisor.ping; then
    export SUPERVISOR_TOKEN="$(bashio::supervisor.token)"
    bashio::log.info "Supervisor API available"
else
    bashio::log.warning "Supervisor API unavailable"
fi

export TZ="${TZ:-UTC}"
export NODE_RED_ENABLE_PROJECTS=false

bashio::log.info "Starting Node-RED on port 1880..."

exec node-red \
    --userDir "${USER_DIR}" \
    --settings "${SETTINGS_FILE}" \
    --port 1880
