#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");

const action = process.argv[2] || "upsert";
const filePath = process.argv[3] || "/config/dashboards/smart_pylontech.json";

const token = process.env.SUPERVISOR_TOKEN;
const wsUrl = "ws://supervisor/core/websocket";

if (!token) {
  console.error(JSON.stringify({ ok: false, error: "Supervisor token missing" }));
  process.exit(1);
}

if (typeof WebSocket === "undefined") {
  console.error(JSON.stringify({ ok: false, error: "Global WebSocket not available" }));
  process.exit(1);
}

let input = null;

function deriveSlugFromFile(file) {
  const base = path.basename(String(file || ""), ".json").trim().toLowerCase();

  if (!base) return "smart-pylontech";

  return base.replace(/_/g, "-");
}

function deriveTitleFromSlug(slug) {
  const s = String(slug || "").trim().toLowerCase();

  if (s === "smart-pylontech") return "Smart Pylontech";
  if (s === "smart-voltronic") return "Smart Voltronic";

  return s
    .split("-")
    .filter(Boolean)
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

if (action !== "delete") {
  if (!fs.existsSync(filePath)) {
    console.error(JSON.stringify({ ok: false, error: `Dashboard file not found: ${filePath}` }));
    process.exit(1);
  }

  try {
    input = JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (e) {
    console.error(JSON.stringify({ ok: false, error: `Invalid dashboard JSON in file: ${filePath}` }));
    process.exit(1);
  }
}

const fallbackSlug = deriveSlugFromFile(filePath);
const fallbackTitle = deriveTitleFromSlug(fallbackSlug);
const fallbackIcon = fallbackSlug.includes("pylontech") ? "mdi:battery" : "mdi:solar-power";

const dashboardMeta = input?.dashboard_meta || {};
const dashboardConfig = input?.config || {};

const urlPath = dashboardMeta.url_path || fallbackSlug;
const title = dashboardMeta.title || fallbackTitle;
const icon = dashboardMeta.icon || fallbackIcon;
const showInSidebar = dashboardMeta.show_in_sidebar !== false;
const requireAdmin = !!dashboardMeta.require_admin;

const ws = new WebSocket(wsUrl);
let nextId = 1;
const pending = new Map();
let finished = false;

function finishOk(extra = {}) {
  if (finished) return;
  finished = true;
  console.log(JSON.stringify({
    ok: true,
    action,
    dashboard: urlPath,
    ...extra
  }));
  try { ws.close(); } catch (_) {}
  process.exit(0);
}

function finishErr(error) {
  if (finished) return;
  finished = true;
  console.error(JSON.stringify({
    ok: false,
    action,
    dashboard: urlPath,
    error: String(error || "Unknown error")
  }));
  try { ws.close(); } catch (_) {}
  process.exit(1);
}

function call(type, payload = {}) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ id, type, ...payload }));
  });
}

function isDashboardMissingError(err) {
  const msg = String(err?.message || err || "").toLowerCase();
  return (
    msg.includes("not found") ||
    msg.includes("unknown") ||
    msg.includes("does not exist") ||
    msg.includes("no config") ||
    msg.includes("not configured")
  );
}

async function createOrUpdateDashboard() {
  let createdDashboard = false;

  try {
    await call("lovelace/config/save", {
      url_path: urlPath,
      config: dashboardConfig
    });

    return {
      created_dashboard: false,
      saved: true,
      file: filePath,
      title,
      icon
    };
  } catch (err) {
    if (!isDashboardMissingError(err)) {
      throw err;
    }
  }

  await call("lovelace/dashboards/create", {
    url_path: urlPath,
    title,
    icon,
    show_in_sidebar: showInSidebar,
    require_admin: requireAdmin,
    mode: "storage"
  });

  createdDashboard = true;

  await call("lovelace/config/save", {
    url_path: urlPath,
    config: dashboardConfig
  });

  return {
    created_dashboard: createdDashboard,
    saved: true,
    file: filePath,
    title,
    icon
  };
}

async function deleteDashboard() {
  try {
    await call("lovelace/config/delete", {
      url_path: urlPath
    });

    return {
      deleted: true,
      file: filePath
    };
  } catch (err) {
    const msg = String(err?.message || err || "").toLowerCase();

    if (
      msg.includes("not found") ||
      msg.includes("unknown") ||
      msg.includes("does not exist") ||
      msg.includes("no config") ||
      msg.includes("not configured")
    ) {
      return {
        deleted: false,
        already_missing: true,
        file: filePath
      };
    }

    throw err;
  }
}

ws.onerror = (event) => {
  finishErr(event?.message || "WebSocket error");
};

ws.onmessage = async (event) => {
  let msg;
  try {
    msg = JSON.parse(event.data.toString());
  } catch (e) {
    finishErr("Invalid websocket message");
    return;
  }

  if (msg.type === "auth_required") {
    ws.send(JSON.stringify({
      type: "auth",
      access_token: token
    }));
    return;
  }

  if (msg.type === "auth_invalid") {
    finishErr("Authentication failed");
    return;
  }

  if (msg.type === "auth_ok") {
    try {
      let result;

      if (action === "delete") {
        result = await deleteDashboard();
      } else {
        result = await createOrUpdateDashboard();
      }

      finishOk(result);
    } catch (err) {
      finishErr(err?.message || err);
    }
    return;
  }

  if (Object.prototype.hasOwnProperty.call(msg, "id")) {
    const waiter = pending.get(msg.id);
    if (!waiter) return;

    pending.delete(msg.id);

    if (msg.success === false) {
      waiter.reject(new Error(msg.error?.message || "Home Assistant error"));
    } else {
      waiter.resolve(msg.result);
    }
  }
};
