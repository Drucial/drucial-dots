#!/usr/bin/env node
// Command-line entry for strip, same and audit over TypeScript and JavaScript sources.
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import {
  classify,
  comments,
  isDirective,
  isGenerated,
  listSources,
  loadTypeScript,
  parse,
  read,
  repoRoot,
  splitArgs,
  tokens,
} from "./lib.mjs";

const [command, ...rest] = process.argv.slice(2);
const commands = { strip, same, audit };
if (!commands[command]) {
  console.error("usage: cli.mjs strip <file>... | same <repo> <base-ref> [file...] | audit [--json file] [--list violations|in-body|all|none] [--match regexp] <root>");
  process.exit(2);
}
commands[command](rest);

function strip(args) {
  const files = splitArgs(args).map((f) => resolve(f));
  if (files.length === 0) {
    console.error("usage: cli.mjs strip <file>...");
    process.exit(2);
  }
  const ts = loadTypeScript(repoRoot(dirname(files[0])));
  for (const path of files) {
    const text = readFileSync(path, "utf8");
    if (isGenerated(text)) {
      console.log(`skipped (generated): ${path}`);
      continue;
    }
    const sf = parse(ts, path, text);
    const emptyJsx = [];
    const visit = (node) => {
      if (node.kind === ts.SyntaxKind.JsxExpression && !node.expression && !node.dotDotDotToken) {
        emptyJsx.push([node.getStart(sf), node.getEnd()]);
      }
      ts.forEachChild(node, visit);
    };
    visit(sf);
    const doomed = comments(ts, sf)
      .filter((c) => !isDirective(c.text, path))
      .map((c) => ({ ...c, jsx: emptyJsx.some(([s, e]) => c.pos > s && c.end < e) }))
      .sort((a, b) => b.pos - a.pos);
    writeFileSync(path, remove(text, doomed));
    console.log(`stripped ${doomed.length} comments: ${path}`);
  }
}

function remove(text, doomed) {
  const lines = text.split("\n");
  const offsets = [];
  let at = 0;
  for (const l of lines) {
    offsets.push(at);
    at += l.length + 1;
  }
  const locate = (pos) => {
    let lo = 0;
    let hi = offsets.length - 1;
    while (lo < hi) {
      const mid = (lo + hi + 1) >> 1;
      if (offsets[mid] <= pos) lo = mid;
      else hi = mid - 1;
    }
    return [lo, pos - offsets[lo]];
  };

  const gone = new Array(lines.length).fill(false);
  const touched = new Array(lines.length).fill(false);
  for (const c of doomed) {
    const [sl, sc] = locate(c.pos);
    const [el, ec] = locate(c.end);
    const before = lines[sl].slice(0, sc);
    const after = lines[el].slice(ec);
    if (!before.trim() && !after.trim()) {
      for (let l = sl; l <= el; l++) gone[l] = true;
      if (sl > 0) touched[sl - 1] = true;
      if (el + 1 < lines.length) touched[el + 1] = true;
      continue;
    }
    if (sl === el) {
      const joined = before.trimEnd() + (before.trim() && after.trim() ? " " : "") + after;
      if (c.jsx && /^\s*\{\s*\}\s*$/.test(joined)) {
        gone[sl] = true;
        if (sl > 0) touched[sl - 1] = true;
        if (sl + 1 < lines.length) touched[sl + 1] = true;
      } else {
        lines[sl] = joined;
      }
      continue;
    }
    lines[sl] = before.trimEnd();
    for (let l = sl + 1; l < el; l++) gone[l] = true;
    lines[el] = after;
  }

  const out = [];
  lines.forEach((l, i) => {
    if (gone[i]) return;
    if (!l.trim() && touched[i]) {
      const prev = out.length ? out[out.length - 1].trim() : "";
      const next = lines.slice(i + 1).find((x, j) => !gone[i + 1 + j])?.trim() ?? "";
      if (!prev || /[{([]$/.test(prev) || /^[})\]]/.test(next)) return;
    }
    out.push(l);
  });
  return out.join("\n");
}

function same(args) {
  if (args.length < 2) {
    console.error("usage: cli.mjs same <repo> <base-ref> [file...]");
    process.exit(2);
  }
  const repo = resolve(args[0]);
  const base = args[1];
  const ts = loadTypeScript(repo);
  let files = splitArgs(args.slice(2));
  if (files.length === 0) {
    files = execFileSync("git", ["-C", repo, "diff", "--name-only", base], { encoding: "utf8" })
      .split("\n")
      .filter((f) => /\.(ts|tsx|mts|cts|js|jsx|mjs|cjs)$/.test(f));
  }
  files = files.map((f) => (f.startsWith("/") ? relative(repo, f) : f));

  let bad = 0;
  for (const file of files) {
    const verdict = compare(ts, repo, base, file);
    console.log(`${verdict}: ${file}`);
    if (verdict !== "comments only" && verdict !== "unchanged") bad++;
  }
  console.log(`${files.length} files, ${bad} failing`);
  process.exit(bad ? 1 : 0);
}

function compare(ts, repo, base, file) {
  let old;
  try {
    old = execFileSync("git", ["-C", repo, "show", `${base}:${file}`], { encoding: "utf8", maxBuffer: 1 << 28 });
  } catch {
    return "CODE CHANGED (not in base)";
  }
  if (!existsSync(join(repo, file))) return "CODE CHANGED (deleted)";
  const cur = read(repo, file);
  if (old === cur) return "unchanged";

  const a = shape(ts, file, old);
  const b = shape(ts, file, cur);
  if (a.errors !== b.errors) return "PARSE ERRORS CHANGED";
  if (a.tokens.length !== b.tokens.length || a.tokens.some((t, i) => t !== b.tokens[i])) {
    const i = a.tokens.findIndex((t, j) => t !== b.tokens[j]);
    return `CODE CHANGED near token ${i}: ${JSON.stringify(a.tokens[i])} -> ${JSON.stringify(b.tokens[i])}`;
  }
  const missing = lost(a.directives, b.directives);
  if (missing.length) return `DIRECTIVE REMOVED ${missing.join(", ")}`;
  return "comments only";
}

function shape(ts, file, text) {
  const sf = parse(ts, file, text);
  const toks = tokens(ts, sf)
    .map((t) => {
      if (t.kind === ts.SyntaxKind.JsxText || t.kind === ts.SyntaxKind.JsxTextAllWhiteSpaces) {
        const collapsed = t.getText(sf).replace(/\s+/g, " ").trim();
        return collapsed ? `jsx:${collapsed}` : null;
      }
      return `${t.kind}:${t.getText(sf)}`;
    })
    .filter((t) => t !== null);
  const directives = comments(ts, sf)
    .filter((c) => isDirective(c.text, file))
    .map((c) => c.text.trim());
  return { tokens: toks, directives, errors: sf.parseDiagnostics.length };
}

function lost(before, after) {
  const have = new Map();
  for (const d of after) have.set(d, (have.get(d) ?? 0) + 1);
  const missing = [];
  for (const d of before) {
    if (have.get(d)) have.set(d, have.get(d) - 1);
    else missing.push(d);
  }
  return missing.sort();
}

function audit(args) {
  const opts = { json: "", list: "violations", match: "" };
  const positional = [];
  for (let i = 0; i < args.length; i++) {
    const flag = args[i].replace(/^--?/, "-");
    if (flag === "-json") opts.json = args[++i];
    else if (flag === "-list") opts.list = args[++i];
    else if (flag === "-match") opts.match = args[++i];
    else positional.push(args[i]);
  }
  if (positional.length !== 1) {
    console.error("usage: cli.mjs audit [--json file] [--list violations|in-body|all|none] [--match regexp] <root>");
    process.exit(2);
  }
  const root = resolve(positional[0]);
  const ts = loadTypeScript(repoRoot(root));

  const records = [];
  for (const file of listSources(root)) {
    const text = read(root, file);
    if (isGenerated(text)) continue;
    const sf = parse(ts, file, text);
    for (const g of classify(ts, sf, file)) {
      if (g.directive) continue;
      const { comments: _, directive: __, ...record } = g;
      records.push(record);
    }
  }

  if (opts.json) writeFileSync(opts.json, JSON.stringify(records, null, 2));

  const tally = (key) => {
    const lines = new Map();
    const groups = new Map();
    for (const r of records) {
      const k = key(r);
      lines.set(k, (lines.get(k) ?? 0) + r.lines);
      groups.set(k, (groups.get(k) ?? 0) + 1);
    }
    return [...lines.keys()].map((k) => [k, lines.get(k), groups.get(k)]);
  };
  const total = records.reduce((n, r) => n + r.lines, 0);
  console.log(`== comment lines by directory (total ${total})`);
  for (const [dir, lines, groups] of tally((r) => dirname(r.file)).sort((a, b) => b[1] - a[1])) {
    console.log(`${String(lines).padStart(6)} lines ${String(groups).padStart(5)} groups  ${dir}`);
  }
  console.log("== by kind");
  const kindKey = (r) => (r.kind === "file" ? "file" : `${r.test ? "test" : r.exported ? "exported" : "unexported"} ${r.kind}`);
  for (const [kind, lines, groups] of tally(kindKey).sort((a, b) => a[0].localeCompare(b[0]))) {
    console.log(`${String(lines).padStart(6)} lines ${String(groups).padStart(5)} groups  ${kind}`);
  }

  const re = opts.match ? new RegExp(opts.match) : null;
  const violations = records.filter((r) => r.violation);
  console.log(`== violations: ${violations.length}`);
  if (opts.list === "none") return;
  const picked = records.filter(
    (r) =>
      (opts.list === "all" || (opts.list === "violations" && r.violation) || (opts.list === "in-body" && r.kind === "in-body")) &&
      (!re || re.test(r.text)),
  );
  console.log(`== ${opts.list} (${picked.length})`);
  for (const r of picked) {
    const label = [r.kind + (r.decl ? ` ${r.decl}` : ""), r.violation].filter(Boolean).join(", ");
    console.log(`${r.file}:${r.line} [${label}]`);
    for (const l of r.text.split("\n")) console.log(`    ${l}`);
  }
}
