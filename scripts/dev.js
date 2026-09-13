import "dotenv/config";
import { spawn } from "node:child_process";
import net from "node:net";

// One command to run the full backend stack: `npm run dev:all`
// Starts the local Prisma Postgres server, waits for it to accept
// connections, then launches the API with watch mode.

const DB_PORT = 51214;
const DB_ARGS = [
  "prisma",
  "dev",
  "--name",
  "matjar",
  "-p",
  "51213",
  "--db-port",
  "51214",
  "--shadow-db-port",
  "51215",
];

let exiting = false;
const db = spawn("npx", DB_ARGS, {
  stdio: "inherit",
  shell: process.platform === "win32",
});
const api = { proc: null };

function isPortOpen(port, host = "127.0.0.1") {
  return new Promise((resolve) => {
    const socket = net.createConnection({ port, host });
    const done = (ok) => {
      socket.destroy();
      resolve(ok);
    };
    socket.once("connect", () => done(true));
    socket.once("error", () => done(false));
  });
}

async function waitForPort(port, { timeoutMs = 120_000, intervalMs = 500 } = {}) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (await isPortOpen(port)) return true;
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  return false;
}

function killWindows(pid) {
  try {
    spawn("taskkill", ["/pid", String(pid), "/T", "/F"], {
      detached: true,
      stdio: "ignore",
      shell: process.platform === "win32",
    });
  } catch {
    // best effort
  }
}

function cleanup() {
  for (const child of [db, api.proc]) {
    if (child?.pid) {
      try {
        child.kill("SIGTERM");
      } catch {
        // best effort
      }
      if (process.platform === "win32") killWindows(child.pid);
    }
  }
}

db.on("exit", (code) => {
  if (!exiting) {
    console.error(`[dev] database exited early (code ${code}); stopping`);
    exiting = true;
    cleanup();
    process.exit(code ?? 1);
  }
});

for (const sig of ["SIGINT", "SIGTERM"]) {
  process.on(sig, () => {
    exiting = true;
    cleanup();
    process.exit(0);
  });
}

const ready = await waitForPort(DB_PORT);
if (!ready) {
  console.error(`[dev] timeout waiting for database on 127.0.0.1:${DB_PORT}`);
  exiting = true;
  cleanup();
  process.exit(1);
}

console.log("[dev] database ready — starting API");
api.proc = spawn("node", ["--watch", "src/server.js"], { stdio: "inherit" });
api.proc.on("exit", (code) => {
  if (!exiting) {
    console.log(`[dev] API exited (code ${code}); stopping database`);
    exiting = true;
    cleanup();
    process.exit(code ?? 0);
  }
});