// Shows the accent focus border only when the shown tab has more than one visible pane.
// A lone (or zoomed) pane gets the plain border color. Draws nothing.

import { View, div } from "gpui-kit";
import { focused, layout, panes, run } from "herdr";

const BLOCK = "main";

function findNode(node, id) {
  if (!node || typeof node !== "object") return null;
  if (node.id === id) return node;
  for (const child of node.children ?? []) {
    const hit = findNode(child, id);
    if (hit) return hit;
  }
  return null;
}

export default class ZenFocus extends View {
  init() {
    this.pending = null;
  }

  render(cx) {
    const tab = focused()?.tab;
    const shown = panes().filter((p) => p.tab === tab);
    const split = shown.length > 1 && !shown.some((p) => p.zoomed);
    const want = split ? "accent" : "border";

    const tree = layout();
    const have = findNode(tree, BLOCK)?.content?.pane?.focus?.color;
    if (have === want) this.pending = null;
    else if (have && this.pending !== want) {
      this.pending = want;
      cx.spawn(async () => {
        try {
          const next = JSON.parse(JSON.stringify(layout()));
          const p = findNode(next, BLOCK).content.pane;
          p.focus = { ...(p.focus ?? { width: 1 }), color: want };
          run("layout.set", { layout: next });
        } catch {
        }
      });
    }
    return div();
  }
}
