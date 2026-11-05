## 2.0.6

### Removed
- The former **Smart Pylontech Premium** dashboard: only the HTML dashboard is kept. It is removed from Home Assistant at start-up.
- The `dashboard_custom_cards_installed` option, which only served that dashboard.

### Fixed
- English translation of the dashboard state tab.

## 2.0.5

### Changed
- The default base topic is back to `pylontech1`: existing entities and dashboards are kept.

## 2.0.4

### Changed
- Premium licenses now use the SmartPhoton `SPV2` format, as on the JK-BMS add-on. Old `SVP|` keys are no longer accepted.

### Security
- The license secret is removed from the flow.

### Fixed
- The system MQTT Discovery is sent after the broker connection and repeated every 5 minutes.

## 2.0.3

### Fixed
- The premium install ID is shown in the add-on log at start-up (missing from 2.0.2).

## 2.0.2

### Fixed
- The premium install ID is shown again in the add-on log at start-up.

### Added
- `DOCS.md`: where to find the install ID for a premium license.

## 2.0.1

### Fixed
- Docker build: `musl` is upgraded before installing the build tools.
- MQTT: the add-on credentials are now used to connect to the broker.
- MQTT Discovery: unique IDs, device identifiers and object IDs no longer contain the `/` of the base topic.

## 2.0.0

### Changed
- Add-on rebuilt on the JK-BMS model: s6 services, `config.yaml` + `build.yaml`, Node-RED and its nodes installed in the image.
- New Node-RED flow validated in the field: TCP gateway, automatic model detection, richer MQTT Discovery.
- Node-RED data moved to `/config/smartphoton_pylontech/`.

### Added
- `baudrate` and `packs_count` options (`0` = automatic detection).
- HTML dashboard (premium), in French and English, deployed to `/config/www/smart-modular-dashboard/` and added to the shared SmartPhoton menu.
- `DOCS.md`, `SAFETY.md`, French and English translations of the options.

### Fixed
- The base topic is applied to every node of the flow.

### Breaking changes
- Option names changed: the configuration must be filled in again.
- 32-bit architectures (armv7, armhf, i386) are no longer supported.
