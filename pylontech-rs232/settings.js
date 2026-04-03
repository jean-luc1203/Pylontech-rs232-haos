module.exports = {

/* --------------------------------------------------
 * Node-RED UI
 * -------------------------------------------------- */

uiPort: process.env.PORT || 1880,
uiHost: "0.0.0.0",

/* --------------------------------------------------
 * Security
 * -------------------------------------------------- */

adminAuth: null,

httpNodeAuth: null,

httpStaticAuth: null,

/* --------------------------------------------------
 * Projects disabled (avoid warnings)
 * -------------------------------------------------- */

editorTheme: {
    projects: {
        enabled: false
    }
},

/* --------------------------------------------------
 * Flow file
 * -------------------------------------------------- */

flowFile: 'flows.json',

/* --------------------------------------------------
 * Logging
 * -------------------------------------------------- */

logging: {

    console: {
        level: "info",
        metrics: false,
        audit: false
    }
},

/* --------------------------------------------------
 * Context storage (IMPORTANT)
 * Needed for persistent states
 * -------------------------------------------------- */

contextStorage: {

    default: {
        module: "memory"
    },

    persistent: {
        module: "localfilesystem"
    }
},

/* --------------------------------------------------
 * Allow modules inside function nodes
 * -------------------------------------------------- */

functionExternalModules: true,

functionGlobalContext: {

    crypto: require('crypto'),

    fs: require('fs'),

    path: require('path'),

    os: require('os'),

    Buffer: Buffer
},

/* --------------------------------------------------
 * MQTT reconnect stability
 * -------------------------------------------------- */

mqttReconnectTime: 15000,

serialReconnectTime: 15000,

/* --------------------------------------------------
 * Disable diagnostics
 * -------------------------------------------------- */

diagnostics: {
    enabled: false
},

/* --------------------------------------------------
 * Runtime options
 * -------------------------------------------------- */

runtimeState: {
    enabled: false,
    ui: false
},

/* --------------------------------------------------
 * Palette
 * -------------------------------------------------- */

externalModules: {
    autoInstall: false,
    autoInstallRetry: 30,
    palette: {
        allowInstall: true,
        allowUpload: false
    }
},

/* --------------------------------------------------
 * HTTP settings
 * -------------------------------------------------- */

httpNodeCors: {
    origin: "*",
    methods: "GET,PUT,POST,DELETE"
},

/* --------------------------------------------------
 * Dashboard
 * -------------------------------------------------- */

ui: {
    path: "ui"
},

/* --------------------------------------------------
 * Environment safe defaults
 * -------------------------------------------------- */

env: {

},

/* --------------------------------------------------
 * Disable flow file pretty formatting
 * -------------------------------------------------- */

flowFilePretty: false,

/* --------------------------------------------------
 * Node timeout
 * -------------------------------------------------- */

nodeMessageBufferMaxLength: 0

};
