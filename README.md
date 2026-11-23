# Pylontech-rs232-haos
Full management of US5000-2000c-Pelio units via an RS232 wired connection

<img width="400" height="300" alt="image" src="https://github.com/user-attachments/assets/c9f92443-dd9b-49ed-8d21-f4ef1a261368" />

<img width="368" height="295" alt="image" src="https://github.com/user-attachments/assets/e4fd184a-0526-4f0e-84fd-7cb76c8d429b" />

# Connect Pylontech to Home Assistant and MQTT Broker

This module will enable you to connect Pylontech via the console port (rj45 - rs232) 
of the  master battery (type US2000c-3000-5000 & Pelio)
and Send all data to Home assistant OS and to an MQTT broker.

- Publication of MQTT topics : `pylontech1/battery/<pack>/state`
- Autodiscovery into Home Assistant
- Node-RED integrated
- RS232 console port or TCP/IP gateway
- Automatic detection of packs and battery model
- HTML dashboard (premium), in French and English

# What's new in 2.x

- New Node-RED flow, validated in the field: TCP/IP gateway, automatic detection of the battery model and of the number of packs.
- HTML dashboard (premium), in French and English, readable on phones. It replaces the former **Smart Pylontech Premium** dashboard, which is removed automatically.
- Daily CSV export (premium) in `/share/pylontech`.
- New premium license format, shared with the JK-BMS add-on.
- The Node-RED editor on port 1893 asks for a login.
- 32-bit systems (armv7, armhf, i386) are no longer supported.

Full list of changes: [CHANGELOG](pylontech-rs232/CHANGELOG.md).

# Updating from 1.x

The option names have changed, so your settings are not kept.

1. Write down your current settings: serial port or gateway, MQTT broker, user and password.
2. Update the add-on.
3. Fill in the **Configuration** tab again and restart.
4. Premium users: request a new license (see below).

Your Home Assistant entities are kept as long as `mqtt_base_topic` stays `pylontech1`, the default value.

# Premium license

Premium unlocks the HTML dashboard and the CSV export. The battery entities in Home Assistant stay free.

**Former premium users:** keys from version 1.x (starting with `SVP|`) no longer work. Your new license is free: mention your previous purchase in your request.

To request a license:

1. Start the add-on and copy your install ID. It is shown in the add-on log, on the line `Premium install_id=...`.
2. Send your request on [ko-fi.com/smartphoton](https://ko-fi.com/smartphoton) (association Simply Home Energy), with your install ID and the name of the module: Pylontech.
3. Paste the key you receive into the `premium_license` option, then restart the add-on.

The key is tied to your install ID. If you uninstall and reinstall the add-on, a new install ID is created and you need a new key.

Details: [Documentation](pylontech-rs232/DOCS.md#premium-license).

# Preparing a US2000B or US2000 Plus

The add-on reads the console port at 115200 bauds. The console port of US2000B and US2000 Plus batteries starts at 1200 bauds, so it must be switched first. Other models do not need this step.

You need a serial terminal that can send raw hexadecimal data, connected to the console port of the master battery.

1. Set the terminal to **1200 bauds, 8N1**.
2. Send these bytes as hexadecimal data:

   ```text
   7E 32 30 30 31 34 36 38 32 43 30 30 34 38 35 32 30 46 43 43 33 0D
   ```

3. Set the terminal to **115200 bauds, 8N1**.
4. Send `0D 0A`.
5. Check that the `pylon>` prompt appears.
6. Optional test: send `pwr` followed by a line feed (`0A`). The battery answers with a table of its packs.

Close the terminal before starting the add-on: the port can only be used by one program. With a TCP gateway, also set the gateway serial port to 115200 bauds, 8N1.

Do not use the administration commands of the console: they are low-level routines and are not needed by the add-on.

Procedure based on a forum post by reimer22.

# Installation

Add `https://github.com/jean-luc1203/Pylontech-rs232-haos` to the add-on repositories of Home Assistant, then install **Pylontech RS232 HAOS**.

- [Documentation](pylontech-rs232/DOCS.md)
- [Changelog](pylontech-rs232/CHANGELOG.md)
- [Safety](pylontech-rs232/SAFETY.md)

This add-on is part of the SmartPhoton ecosystem, with the [JK-BMS add-on](https://github.com/jean-luc1203/jkbms-rs485-addon).
