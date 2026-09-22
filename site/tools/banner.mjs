#!/usr/bin/env node
// Regenerate the ASCII banner in site/index.html.
//   node site/tools/banner.mjs               → "macarchy" in figlet's Standard font
//   node site/tools/banner.mjs "text" Slant  → any text, any figlet font
// Uses figlet-cli through npx (no install step); the result is written between
// the <!-- banner:start --> / <!-- banner:end --> markers inside <pre class="ascii">.
import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const text = process.argv[2] || "macarchy";
const font = process.argv[3] || "Standard";
const page = resolve(dirname(fileURLToPath(import.meta.url)), "../index.html");

const raw = execFileSync("npx", ["-y", "figlet-cli", "-f", font, text], { encoding: "utf8" });
const lines = raw.replace(/\s+$/, "").split("\n");
const indent = Math.min(...lines.filter(l => l.trim()).map(l => l.match(/^ */)[0].length));
const art = lines.map(l => l.slice(indent).replace(/\s+$/, "")).join("\n");
const escaped = art.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

const html = readFileSync(page, "utf8");
const re = /(<!-- banner:start -->)[\s\S]*?(<!-- banner:end -->)/;
if (!re.test(html)) { console.error("markers not found in " + page); process.exit(1); }
const width = Math.max(...art.split("\n").map(l => l.length));
let out = html.replace(re, `$1${escaped}$2`);
out = out.replace(/(<pre class="ascii"[^>]*?)( style="--banner-cols:\d+")?>/, `$1 style="--banner-cols:${width}">`);
writeFileSync(page, out);
console.log(`banner: "${text}" in ${font}, ${art.split("\n").length} rows × ${width} cols → ${page}`);
