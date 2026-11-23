const fs = require("fs");

module.exports = {
    /* --------------------------------------------------
     * Node-RED UI
     * -------------------------------------------------- */
    uiPort: 1893,
    uiHost: "0.0.0.0",

    /* --------------------------------------------------
     * Security
     * -------------------------------------------------- */
    // Same editor login as the JK-BMS add-on.
    adminAuth: {
        type: "credentials",
        users: [{ username: "pi", password: "$2a$08$uGLFsGppdWnckZpomdNQveucw.zh8bkSWDO0Gnzj4Z0asqj91KKge", permissions: "*" }]
    },
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
     * User directory, flow and credentials
     * -------------------------------------------------- */
    userDir: "/config/smartphoton_pylontech",
    flowFile: "flows.json",
    credentialSecret: fs.readFileSync("/data/credential_secret", "utf8").trim(),

    /* --------------------------------------------------
     * Extra nodes
     * -------------------------------------------------- */
    nodesDir: "/config/smartphoton_pylontech/nodes",

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
        net: require("net"),
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
    flowFilePretty: true,

    /* --------------------------------------------------
     * Buffer
     * -------------------------------------------------- */
    nodeMessageBufferMaxLength: 0
};
