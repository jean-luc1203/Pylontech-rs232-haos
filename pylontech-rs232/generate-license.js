#!/usr/bin/env node

const crypto = require("crypto");

const LICENSE_SECRET = "SVP_2026_9f7c2e51b4d84f38a1e9c7b6d5e4f301_ULTRA_LONG_SECRET";

function usage() {
    console.log(`
Usage:
  node generate-license.js <install_id>

Example:
  node generate-license.js 1f5b50469d60864da3b3501c82f8a7e512
`);
}

function normalizeInstallId(value) {
    return String(value || "")
        .trim()
        .replace(/-/g, "")
        .toLowerCase();
}

function signInstallId(installId) {
    return crypto
        .createHmac("sha256", LICENSE_SECRET)
        .update(String(installId))
        .digest("hex");
}

const rawInstallId = process.argv[2];

if (!rawInstallId) {
    usage();
    process.exit(1);
}

const installId = normalizeInstallId(rawInstallId);

if (!/^[a-f0-9]{32}$/.test(installId)) {
    console.error("Error: install_id must be 32 hex characters (UUID without dashes).");
    process.exit(1);
}

const signature = signInstallId(installId);
const license = `SVP|premium|${installId}|${signature}`;

console.log("Install ID :", installId);
console.log("Signature  :", signature);
console.log("License    :");
console.log(license);
