## 2.0.1

### Fixed
- Docker build: `musl` is upgraded before installing the build tools.
- MQTT: the add-on credentials are now used to connect to the broker.
- MQTT Discovery: unique IDs, device identifiers and object IDs no longer contain the `/` of the base topic.

## 2.0.0

### Changed
- Add-on rebuilt on the JK-BMS model: s6 services, `config.yaml` + `build.yaml`, Node-RED and its nodes installed in the image.
- New Node-RED flow validated in the field: TCP gateway, automatic model detection, richer MQTT Discovery.
- Default base topic is now `pylontech/1` (was `pylontech1`).
- Node-RED data moved to `/config/smartphoton_pylontech/`.

### Added
- `baudrate` and `packs_count` options (`0` = automatic detection).
- HTML dashboard (premium), in French and English, deployed to `/config/www/smart-modular-dashboard/` and added to the shared SmartPhoton menu.
- `DOCS.md`, `SAFETY.md`, French and English translations of the options.

### Fixed
- The base topic is applied to every node of the flow.

### Breaking changes
- Option names changed: the configuration must be filled in again.
- Entity unique IDs change with the base topic: new entities are created and the old ones must be removed by hand.
- 32-bit architectures (armv7, armhf, i386) are no longer supported.
