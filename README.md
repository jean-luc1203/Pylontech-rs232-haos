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

# Installation

Add `https://github.com/jean-luc1203/Pylontech-rs232-haos` to the add-on repositories of Home Assistant, then install **Pylontech RS232 HAOS**.

- [Documentation](pylontech-rs232/DOCS.md)
- [Changelog](pylontech-rs232/CHANGELOG.md)
- [Safety](pylontech-rs232/SAFETY.md)

This add-on is part of the SmartPhoton ecosystem, with the [JK-BMS add-on](https://github.com/jean-luc1203/jkbms-rs485-addon).
