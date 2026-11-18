// Shared parsing and comment classification for the TypeScript and JavaScript tools, driven by the target repo's own typescript package.
import { createRequire } from "node:module";
import { execFileSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative, resolve } from "node:path";

export const SOURCE = /\.(ts|tsx|mts|cts|js|jsx|mjs|cjs)$/;
const SKIPPED_DIRS = new Set(["node_modules", "dist", "build", "out", "coverage", ".next", ".turbo", ".vercel", "vendor"]);

const DIRECTIVE =
  /@ts-(expect-error|ignore|nocheck|check)\b|eslint-(disable|enable|env)|^\/\*\s*(global|globals|exported)\s|biome-ignore|prettier-ignore|oxlint-(disable|enable)|deno-lint-ignore|dprint-ignore|tslint:|istanbul ignore|[cv]8 ignore|@vite-ignore|webpack[A-Z]\w*\s*:|@(jsx|jsxFrag|jsxImportSource|jsxRuntime)\b|[#@]__(PURE|NO_SIDE_EFFECTS)__|@(vitest|jest)-environment|@refresh\b|@license\b|@preserve\b|^\/\*!|^\/\/\/\s*<(reference|amd)|@flow\b/;
const JSDOC_TYPES = /@(type|param|returns?|typedef|template|satisfies|import|callback|enum|property|prop|extends|augments|implements|this|overload)\b/;
const GENERATED = /@generated|auto-generated|Code generated|DO NOT EDIT/i;

/** Loads typescript from the repo at root, or exits with a message naming the fix. */
export function loadTypeScript(root) {
  try {
    return createRequire(resolve(root, "package.json"))("typescript");
  } catch {
    console.error(`typescript is not resolvable from ${root}. Install dependencies there first.`);
    process.exit(2);
  }
}

export function repoRoot(start = process.cwd()) {
  try {
    return execFileSync("git", ["-C", start, "rev-parse", "--show-toplevel"], { encoding: "utf8" }).trim();
  } catch {
    return resolve(start);
  }
}

export function splitArgs(args) {
  return args.flatMap((a) => a.split(/\s+/)).filter(Boolean);
}

export function isTest(file) {
  return /(^|[/.])(test|spec)s?\.[cm]?[jt]sx?$|__tests__\/|(^|\/)(e2e|tests?)\//.test(file);
}

export function isGenerated(text) {
  return GENERATED.test(text.split("\n", 6).join("\n"));
}

export function isDirective(text, file) {
  if (DIRECTIVE.test(text)) return true;
  return /\.[cm]?jsx?$/.test(file) && text.startsWith("/**") && JSDOC_TYPES.test(text);
}

export function listSources(root) {
  let files;
  try {
    files = execFileSync("git", ["-C", root, "ls-files", "--cached", "--others", "--exclude-standard"], { encoding: "utf8" })
      .split("\n")
      .filter(Boolean);
  } catch {
    files = walk(root).map((f) => relative(root, f));
  }
  return files.filter((f) => SOURCE.test(f) && !/\.min\.[cm]?js$/.test(f) && !f.split("/").some((part) => SKIPPED_DIRS.has(part)) && existsSync(join(root, f)));
}

function walk(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    if (name.startsWith(".") || SKIPPED_DIRS.has(name)) continue;
    const p = join(dir, name);
    if (statSync(p).isDirectory()) out.push(...walk(p));
    else out.push(p);
  }
  return out;
}

export function parse(ts, file, text) {
  const kind = file.endsWith(".tsx")
    ? ts.ScriptKind.TSX
    : /\.[cm]?jsx$/.test(file)
      ? ts.ScriptKind.JSX
      : /\.[cm]?js$/.test(file)
        ? ts.ScriptKind.JS
        : ts.ScriptKind.TS;
  return ts.createSourceFile(file, text, ts.ScriptTarget.Latest, true, kind);
}

const kindNames = new WeakMap();

function kindName(ts, kind) {
  let names = kindNames.get(ts.SyntaxKind);
  if (!names) {
    names = new Map();
    for (const [name, value] of Object.entries(ts.SyntaxKind)) {
      if (typeof value === "number" && !/^(First|Last)/.test(name) && !names.has(value)) names.set(value, name);
    }
    kindNames.set(ts.SyntaxKind, names);
  }
  return names.get(kind);
}

function isJSDocNode(ts, node) {
  return node.kind >= ts.SyntaxKind.FirstJSDocNode && node.kind <= ts.SyntaxKind.LastJSDocNode;
}

function isJsxText(ts, node) {
  return node.kind === ts.SyntaxKind.JsxText || node.kind === ts.SyntaxKind.JsxTextAllWhiteSpaces;
}

/** Every token in source order, JSDoc excluded, with empty JSX expressions like `{}` dropped. */
export function tokens(ts, sf) {
  const out = [];
  const visit = (node) => {
    if (isJSDocNode(ts, node)) return;
    if (node.kind === ts.SyntaxKind.JsxExpression && !node.expression && !node.dotDotDotToken) return;
    const children = node.getChildren(sf);
    if (children.length === 0) {
      if (node.kind !== ts.SyntaxKind.SyntaxList) out.push(node);
      return;
    }
    children.forEach(visit);
  };
  visit(sf);
  return out;
}

/** Every comment range in the file, sorted, each once. */
export function comments(ts, sf) {
  const text = sf.getFullText();
  const seen = new Map();
  const add = (ranges) => {
    for (const r of ranges ?? []) {
      if (!seen.has(r.pos)) seen.set(r.pos, { pos: r.pos, end: r.end, text: text.slice(r.pos, r.end) });
    }
  };
  const all = [];
  const visit = (node) => {
    if (isJSDocNode(ts, node)) return;
    const children = node.getChildren(sf);
    if (children.length === 0) {
      if (node.kind !== ts.SyntaxKind.SyntaxList) all.push(node);
      return;
    }
    children.forEach(visit);
  };
  visit(sf);
  all.forEach((tok, i) => {
    if (!isJsxText(ts, tok)) add(ts.getLeadingCommentRanges(text, tok.getFullStart()));
    const next = all[i + 1];
    if (!isJsxText(ts, tok) && !(next && isJsxText(ts, next))) add(ts.getTrailingCommentRanges(text, tok.getEnd()));
  });
  return [...seen.values()].sort((a, b) => a.pos - b.pos);
}

const FUNCTION_LIKE = new Set([
  "FunctionDeclaration",
  "FunctionExpression",
  "ArrowFunction",
  "MethodDeclaration",
  "Constructor",
  "GetAccessor",
  "SetAccessor",
  "ClassStaticBlockDeclaration",
]);

const DECLARATION = new Set([
  "FunctionDeclaration",
  "ClassDeclaration",
  "InterfaceDeclaration",
  "TypeAliasDeclaration",
  "EnumDeclaration",
  "ModuleDeclaration",
  "VariableStatement",
  "ExportAssignment",
  "ExportDeclaration",
  "ImportDeclaration",
  "MethodDeclaration",
  "PropertyDeclaration",
  "Constructor",
  "GetAccessor",
  "SetAccessor",
  "MethodSignature",
  "PropertySignature",
  "IndexSignature",
  "CallSignature",
  "EnumMember",
  "ClassStaticBlockDeclaration",
  "PropertyAssignment",
  "ShorthandPropertyAssignment",
]);

/** Groups the file's prose comments and classifies each against the comment rules. */
export function classify(ts, sf, file) {
  const text = sf.getFullText();
  const lineOf = (pos) => sf.getLineAndCharacterOfPosition(pos).line + 1;
  const test = isTest(file);

  const groups = [];
  for (const c of comments(ts, sf)) {
    const prev = groups.at(-1);
    const between = prev ? text.slice(prev.end, c.pos) : "";
    const adjacent = prev && prev.line && c.text.startsWith("//") && prev.last.startsWith("//") && /^[ \t]*\r?\n[ \t]*$/.test(between);
    if (adjacent) {
      prev.end = c.end;
      prev.comments.push(c);
      prev.last = c.text;
      continue;
    }
    groups.push({ pos: c.pos, end: c.end, comments: [c], last: c.text, line: c.text.startsWith("//") });
  }

  const functionBodies = [];
  const declarations = [];
  const visit = (node, exportedParent) => {
    const name = kindName(ts, node.kind);
    if (FUNCTION_LIKE.has(name) && node.body) functionBodies.push([node.body.getStart(sf), node.body.getEnd()]);
    let exported = false;
    if (DECLARATION.has(name)) {
      exported = isExported(ts, node, exportedParent);
      declarations.push({ node, start: node.getStart(sf), line: lineOf(node.getStart(sf)), name, decl: declName(ts, node, sf), exported });
    }
    ts.forEachChild(node, (child) => visit(child, exported || (exportedParent && !DECLARATION.has(name))));
  };
  visit(sf, file.endsWith(".d.ts"));

  const firstStatement = sf.statements[0]?.getStart(sf) ?? text.length;

  return groups.map((g) => {
    const startLine = lineOf(g.pos);
    const endLine = lineOf(g.end);
    const rawText = g.comments.map((c) => c.text).join("\n");
    const directive = g.comments.every((c) => isDirective(c.text, file));
    const lineStart = text.lastIndexOf("\n", g.pos - 1) + 1;
    const trailing = text.slice(lineStart, g.pos).trim() !== "";
    const inBody = functionBodies.some(([s, e]) => g.pos > s && g.end < e);

    let kind = "floating";
    let decl = "";
    let exported = false;
    if (inBody) {
      kind = "in-body";
    } else {
      const owner = declarations
        .filter((d) => d.start >= g.end && d.line <= endLine + 1)
        .sort((a, b) => a.start - b.start || b.node.getEnd() - a.node.getEnd())[0];
      const onLine = trailing && declarations.filter((d) => d.start < g.pos && d.node.getEnd() >= g.pos).at(-1);
      if (owner) {
        kind = owner.name;
        decl = owner.decl;
        exported = owner.exported && !test;
      } else if (onLine) {
        kind = "trailing";
        decl = onLine.decl;
      } else if (g.end <= firstStatement) {
        kind = "file";
      }
    }
    const lines = endLine - startLine + 1;
    const limit = exported ? 3 : 1;
    let violation = "";
    if (!directive) {
      if (kind === "in-body") violation = "inside a function body";
      else if (kind === "floating") violation = "not attached to a declaration";
      else if (lines > limit) violation = "over its length limit";
    }
    return { file, line: startLine, lines, kind, decl, exported, test, directive, violation, text: rawText, comments: g.comments };
  });
}

function isExported(ts, node, exportedParent) {
  const flags = ts.getCombinedModifierFlags(node);
  if (flags & ts.ModifierFlags.Private) return false;
  if (node.name && ts.isPrivateIdentifier?.(node.name)) return false;
  if (flags & ts.ModifierFlags.Export || node.kind === ts.SyntaxKind.ExportAssignment) return true;
  const memberKinds = ["MethodDeclaration", "PropertyDeclaration", "Constructor", "GetAccessor", "SetAccessor", "MethodSignature", "PropertySignature", "IndexSignature", "CallSignature", "EnumMember"];
  return Boolean(exportedParent) && memberKinds.includes(kindName(ts, node.kind));
}

function declName(ts, node, sf) {
  if (node.name) return node.name.getText(sf);
  if (ts.isVariableStatement(node)) return node.declarationList.declarations.map((d) => d.name.getText(sf)).join(", ");
  if (ts.isExportAssignment(node)) return "default";
  return kindName(ts, node.kind);
}

export function read(root, file) {
  return readFileSync(join(root, file), "utf8");
}
