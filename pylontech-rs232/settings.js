module.exports = {
    /* --------------------------------------------------
     * Node-RED UI
     * -------------------------------------------------- */
    uiPort: process.env.PORT || 1893,
    uiHost: "0.0.0.0",

    /* --------------------------------------------------
     * Security
     * -------------------------------------------------- */
    adminAuth: null,
    httpNodeAuth: null,
    httpStaticAuth: null,

    /* --------------------------------------------------
     * Projects disabled
     * -------------------------------------------------- */
    editorTheme: {
        projects: {
            enabled: false
        }
    },

    /* --------------------------------------------------
     * Flow file
     * With --userDir /data this resolves to /data/flows.json
     * -------------------------------------------------- */
    flowFile: "flows.json",

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
     * Context storage
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
     * Allow modules in function nodes
     * -------------------------------------------------- */
    functionExternalModules: true,

    functionGlobalContext: {
        crypto: require("crypto"),
        fs: require("fs"),
        path: require("path"),
        os: require("os"),
        Buffer: Buffer
    },

    /* --------------------------------------------------
     * Reconnect timings
     * -------------------------------------------------- */
    mqttReconnectTime: 15000,
    serialReconnectTime: 15000,

    /* --------------------------------------------------
     * Diagnostics
     * -------------------------------------------------- */
    diagnostics: {
        enabled: false
    },

    /* --------------------------------------------------
     * Runtime state
     * -------------------------------------------------- */
    runtimeState: {
        enabled: false,
        ui: false
    },

    /* --------------------------------------------------
     * External modules / palette
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
     * Dashboard path
     * -------------------------------------------------- */
    ui: {
        path: "ui"
    },

    /* --------------------------------------------------
     * Environment defaults
     * -------------------------------------------------- */
    env: {},

    /* --------------------------------------------------
     * Flow formatting
     * -------------------------------------------------- */
    flowFilePretty: false,

    /* --------------------------------------------------
     * Buffer
     * -------------------------------------------------- */
    nodeMessageBufferMaxLength: 0
};
