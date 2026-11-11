// Tool windows toggled by command: transient tools start fresh each time, kept ones hide and keep running.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { closeOverlay, exec, focused, hc, home, nextCommand, notify, openOverlay, props, run, setShared, shared, spaces, terminals, theme } from "herdr";

const OPEN = "floats.open";
const KEPT = "floats.kept";
const TITLE_BAR = 28;

function floats() {
  const bin = `${home()}/.local/bin`;
  return {
    lazygit: { title: "Lazygit", argv: ["lazygit"], repo: true, kept: false },
    "zen-review": { title: "Zen Review", argv: [`${bin}/zen-review`], repo: true, kept: false },
    "zen-octo": { title: "Zen Octo", argv: [`${bin}/zen-octo`], repo: false, kept: true },
    "zen-linear": { title: "Zen Linear", argv: [`${bin}/zen-linear`], repo: false, kept: true },
  };
}

function record(key) {
  return shared(key) ?? {};
}

function patch(key, name, value) {
  const next = { ...record(key) };
  if (value == null) delete next[name];
  else next[name] = value;
  setShared(key, next);
}

function alive(address) {
  return Boolean(address) && terminals().some((t) => t.address === address && t.state !== "exited");
}

async function workingFolder(machine) {
  const dir = focused()?.cwd ?? null;
  if (!dir) return { dir: null, root: null };
  const git = await exec("git", ["rev-parse", "--show-toplevel"], { cwd: dir, on: machine }).catch(() => null);
  return { dir, root: git?.code === 0 ? git.stdout.trim() : null };
}

async function start(name, float) {
  const space = spaces().find((s) => s.id === focused()?.space);
  const machine = float.kept ? null : space?.machine ?? null;
  const { dir, root } = float.kept ? { dir: home(), root: null } : await workingFolder(machine);
  if (float.repo && !root) {
    notify({ title: `${float.title} needs a git repository`, body: dir ?? "No focused folder", level: "warning" });
    return null;
  }
  const args = ["run", "--bg", "--json", "--no-parent", "--no-notify", "--rm", "--cwd", root ?? dir ?? home()];
  if (machine) args.push("--on", machine);
  const result = await hc([...args, "--", ...float.argv]);
  if (result.code !== 0) {
    notify({ title: `${float.title} didn't start`, body: result.stderr.trim(), level: "error" });
    return null;
  }
  return JSON.parse(result.stdout).address;
}

async function toggle(name) {
  const float = floats()[name];
  if (!float) return;
  const open = record(OPEN)[name];
  if (open && alive(open.terminal)) {
    closeOverlay(open.overlay);
    patch(OPEN, name, null);
    return;
  }
  const kept = record(KEPT)[name];
  const terminal = float.kept && alive(kept) ? kept : await start(name, float);
  if (!terminal) return;
  if (float.kept) patch(KEPT, name, terminal);
  const overlay = openOverlay({
    kind: "dialog",
    key: `float-${name}`,
    width: 0.8,
    height: 0.8,
    layout: {
      type: "column",
      children: [
        { type: "block", size: { px: TITLE_BAR }, content: { mod: "drucial-floats", props: { float: name, terminal } } },
        { type: "block", content: { terminal } },
      ],
    },
  });
  patch(OPEN, name, { overlay, terminal });
}

export default class Floats extends View {
  init(_props, cx) {
    if (props()?.float) return;
    cx.spawn(async () => {
      for (;;) {
        const command = await nextCommand();
        await toggle(command);
      }
    });
  }

  async close() {
    const { float: name, terminal } = props() ?? {};
    if (!name) return;
    patch(OPEN, name, null);
    if (!floats()[name]?.kept) run("terminal.kill", { terminal });
  }

  render() {
    const t = theme();
    const name = props()?.float;
    if (!name) return div();
    return h_flex()
      .size_full()
      .pl(12)
      .pr(4)
      .items_center()
      .justify_between()
      .bg(t.chrome)
      .text_size(12)
      .text_color(t.muted)
      .child(div().truncate().child(floats()[name]?.title ?? name))
      .child(
        div()
          .id("float-close")
          .size(20)
          .flex()
          .items_center()
          .justify_center()
          .rounded(4)
          .text_color(t.dim)
          .hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
          .on_click(() => toggle(name))
          .child(svg("mods/pane/close.svg").size(14)),
      );
  }
}
