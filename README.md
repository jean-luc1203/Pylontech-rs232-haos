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
