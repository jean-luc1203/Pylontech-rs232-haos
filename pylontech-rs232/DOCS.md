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
| `packs_count` | Packs to poll, 1 to 15. `0` (default) detects them automatically. |
| `use_gateway` | Use a TCP gateway instead of the local serial port. |
| `gateway_ip_port` | Gateway address, e.g. `192.168.1.100:5000`. |
| `communication_debug` | Detailed communication logs. |
| `mqttadresse_port` | Broker address and port. Default `core-mosquitto:1883`. |
| `mqttuser`, `mqttpass` | MQTT credentials. |
| `mqtt_base_topic` | Topic root. Default `pylontech1`. Changing it creates new entities. |
| `Send_bip` | Anonymous start-up beep. |
| `premium_license` | Premium license key, if you have one. |
| `dashboard_language` | `fr` or `en`. |

### YAML example

```yaml
pylontech_path: /dev/serial/by-id/usb-xxxx_USB_Serial-abcdefghij
packs_count: 0
use_gateway: false
gateway_ip_port: ""
communication_debug: false
mqttadresse_port: core-mosquitto:1883
mqttuser: mqtt_user
mqttpass: mqtt_password
mqtt_base_topic: pylontech1
Send_bip: true
premium_license: ""
dashboard_language: fr
```

The console port is read at 115200 bauds, 8N1. US2000B and US2000 Plus batteries start at 1200 bauds: see [Preparing a US2000B or US2000 Plus](../README.md#preparing-a-us2000b-or-us2000-plus).

## Node-RED

The editor is available on port `1893`. The flow shipped with the add-on replaces `/config/smartphoton_pylontech/flows.json` at every start: changes made in the editor are lost, and the previous flow is kept as `flows.backup`.

The editor has no password: keep this port on your local network and never expose it to the internet.

## MQTT topics

With the default base topic `pylontech1`:

| Topic | Content |
| --- | --- |
| `pylontech1/status` | Availability (`online` / `offline`) |
| `pylontech1/bank/state` | Bank aggregates |
| `pylontech1/battery/<NN>/state` | Pack state |
| `pylontech1/battery/<NN>/stat` | Cycles, SOH and statuses |
| `pylontech1/battery/<NN>/info` | Pack information |
| `pylontech1/battery/<NN>/cell/<CC>/state` | Cell state |
| `pylontech1/system/model` | Detected model |
| `pylontech1/health/transport` | Serial or gateway link health |

Home Assistant devices are named `Pylontech Battery Bank` and `Pylontech Battery <n>`.

## Premium license

A license key is tied to the install ID of your add-on. You will find this ID:

- in the add-on log, on the line `Premium install_id=...` at each start;
- in the **Install ID** sensor of the `pylontech1 System` device, under **Diagnostic**;
- in the MQTT topic `pylontech1/system/info`.

Provide this ID to get your key, then paste the key into `premium_license` and restart the add-on.

Keys use the SmartPhoton `SPV2` format, as on the JK-BMS add-on, and are issued for the `smartphoton-pylontech` product. A JK-BMS key does not work here. Old keys starting with `SVP|` are no longer accepted.

The result is shown in the **Premium status** sensor: `valid` when the key is accepted. `install_id_mismatch` means the key was created for another installation, and `invalid_product` that it was created for another module.

## Dashboards

With a premium license, the add-on publishes the **Smart Pylontech HTML** dashboard in the sidebar. It is stored in `/config/www/smart-modular-dashboard/pylontech.html`.

The former **Smart Pylontech Premium** dashboard is no longer provided: it is removed automatically at start-up, with any change you made to it.

## Files

- `/config/smartphoton_pylontech/`: Node-RED user directory.
- `/config/dashboards/`: generated dashboards.
- `/share/pylontech/`: premium CSV exports.

## Updating from 1.x

- Option names changed: fill in the **Configuration** tab again.
- Keep `mqtt_base_topic` set to `pylontech1` (the default): changing it changes the entity unique IDs, which creates new entities.
- 32-bit systems (armv7, armhf, i386) are no longer supported.

## Safety

See [SAFETY.md](SAFETY.md).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Support

- [Issues](https://github.com/jean-luc1203/Pylontech-rs232-haos/issues)
