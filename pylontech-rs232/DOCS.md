# Smartphoton Pylontech RS232 Add-on for Home Assistant

Reads Pylontech batteries (US2000C, US3000, US5000, Pelio) through the RS232 console port of the master battery, or through a TCP/IP gateway, and publishes the data to MQTT with Home Assistant MQTT Discovery. The logic runs in Node-RED, inside the add-on.

An MQTT broker is required (for example the Mosquitto add-on).

## Installation

1. In Home Assistant, open **Settings > Add-ons > Add-on store**, then **Repositories**, and add `https://github.com/jean-luc1203/Pylontech-rs232-haos`.
2. Install **Pylontech RS232 HAOS**.
3. Fill in the **Configuration** tab, then start the add-on.

The batteries appear under **Settings > Devices > MQTT** after the first detection, which can take a few minutes.

## Configuration

| Option | Description |
| --- | --- |
| `pylontech_path` | by-id path of the serial adapter, e.g. `/dev/serial/by-id/usb-xxxx`. Not used in gateway mode. |
| `baudrate` | Console port speed. Default `115200`. |
| `packs_count` | Packs to poll, 1 to 15. `0` (default) detects them automatically. |
| `use_gateway` | Use a TCP gateway instead of the local serial port. |
| `gateway_ip_port` | Gateway address, e.g. `192.168.1.100:5000`. |
| `communication_debug` | Detailed communication logs. |
| `mqttadresse_port` | Broker address and port. Default `core-mosquitto:1883`. |
| `mqttuser`, `mqttpass` | MQTT credentials. |
| `mqtt_base_topic` | Topic root. Default `pylontech/1`. |
| `Send_bip` | Anonymous start-up beep. |
| `premium_license` | Premium license key, if you have one. |
| `dashboard_custom_cards_installed` | Custom cards are installed in Home Assistant. |
| `dashboard_language` | `fr` or `en`. |

### YAML example

```yaml
pylontech_path: /dev/serial/by-id/usb-xxxx_USB_Serial-abcdefghij
baudrate: "115200"
packs_count: 0
use_gateway: false
gateway_ip_port: ""
communication_debug: false
mqttadresse_port: core-mosquitto:1883
mqttuser: mqtt_user
mqttpass: mqtt_password
mqtt_base_topic: pylontech/1
Send_bip: true
premium_license: ""
dashboard_custom_cards_installed: false
dashboard_language: fr
```

## Node-RED

The editor is available on port `1893`. The flow shipped with the add-on replaces `/config/smartphoton_pylontech/flows.json` at every start: changes made in the editor are lost, and the previous flow is kept as `flows.backup`.

The editor has no password: keep this port on your local network and never expose it to the internet.

## MQTT topics

With the default base topic `pylontech/1`:

| Topic | Content |
| --- | --- |
| `pylontech/1/status` | Availability (`online` / `offline`) |
| `pylontech/1/bank/state` | Bank aggregates |
| `pylontech/1/battery/<NN>/state` | Pack state |
| `pylontech/1/battery/<NN>/stat` | Cycles, SOH and statuses |
| `pylontech/1/battery/<NN>/info` | Pack information |
| `pylontech/1/battery/<NN>/cell/<CC>/state` | Cell state |
| `pylontech/1/system/model` | Detected model |
| `pylontech/1/health/transport` | Serial or gateway link health |

Home Assistant devices are named `Pylontech Battery Bank` and `Pylontech Battery <n>`.

## Premium license

A license key is tied to the install ID of your add-on. You will find this ID:

- in the add-on log, on the line `Premium install_id=...` at each start;
- in the **Install ID** sensor of the `pylontech_1 System` device, under **Diagnostic**;
- in the MQTT topic `pylontech/1/system/info`.

Provide this ID to get your key, then paste the key into `premium_license` and restart the add-on.

## Dashboards

With a premium license, the add-on publishes two dashboards in the sidebar:

- **Smart Pylontech**: native Home Assistant dashboard.
- **Smart Pylontech HTML**: HTML dashboard stored in `/config/www/smart-modular-dashboard/pylontech.html`. It also appears in the shared SmartPhoton menu when `index.html` already exists in that folder.

## Files

- `/config/smartphoton_pylontech/`: Node-RED user directory.
- `/config/dashboards/`: generated dashboards.
- `/share/pylontech/`: premium CSV exports.

## Updating from 1.x

- Option names changed: fill in the **Configuration** tab again.
- The default base topic moves from `pylontech1` to `pylontech/1`, which also changes the entity unique IDs. New entities are created, and the old ones must be removed by hand. Your automations may need updating.
- 32-bit systems (armv7, armhf, i386) are no longer supported.

## Safety

See [SAFETY.md](SAFETY.md).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Support

- [Issues](https://github.com/jean-luc1203/Pylontech-rs232-haos/issues)
