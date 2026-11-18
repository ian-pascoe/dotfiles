// Resize mode, the Herdr app's counterpart of Rex's `resize` mode
// (~/.config/rex/init.lua): prefix+r opens it; h/j/k/l or the arrows move the
// focused pane's border that way, shift moves it further, = balances the
// tab, and Esc, Enter or prefix+r again leaves.
//
// Herdr has no pane.resize command, but a tab's splits are layout nodes:
// layout.resize {id, weight} sizes a pane or split against its siblings. The
// split tree and its weights come from herdr-core's "herdr-app" document,
// read once when the mode opens and kept in step with each resize after.
//
// The document comes from herdr-core's API (doc.get over `hc connect`), not
// its state folder, which moves with the OS. Mods can't feed a program's
// stdin, so a shell redirects it from doc-get.jsonl beside this file.

import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { props, closeOverlay, focused, run, exec, appHome, window, theme, notify } from "herdr";

// Share of the split moved per key, as Rex's 1 and 15 cells roughly are.
const STEP = 0.03;
const BIG_STEP = 0.12;
// No pane shrinks below this share of its split.
const MIN_SHARE = 0.05;

const DIRECTIONS = {
  h: "left",
  left: "left",
  j: "down",
  down: "down",
  k: "up",
  up: "up",
  l: "right",
  right: "right",
};

const weightOf = (node) => node?.size?.weight ?? 1;

// Nodes from `node` down to the one with `id`, or null.
function pathTo(node, id) {
  if (!node) return null;
  if (node.id === id) return [node];
  for (const child of node.children ?? []) {
    const rest = pathTo(child, id);
    if (rest) return [node, ...rest];
  }
  return null;
}

function* walk(node) {
  yield node;
  for (const child of node.children ?? []) yield* walk(child);
}

// The app's layout document: every space, its tabs and their split trees.
async function readLayout() {
  const cwd = appHome() + "/mods/resize-mode";
  const command = "hc connect < doc-get.jsonl";
  const r =
    window().platform === "windows"
      ? await exec("cmd", ["/d", "/c", command], { cwd })
      : await exec("sh", ["-c", command], { cwd });
  for (const line of r.stdout.split("\n")) {
    let reply;
    try {
      reply = JSON.parse(line);
    } catch {
      continue;
    }
    if (reply?.id !== 1) continue;
    if (reply.error) throw new Error(reply.error.message ?? "doc.get failed");
    return reply.result?.value ?? null;
  }
  throw new Error(r.stderr.trim() || "hc connect gave no reply");
}

async function loadTab(tabId) {
  const doc = await readLayout();
  for (const space of doc?.spaces ?? []) {
    for (const tab of space.tabs ?? []) {
      if (tab.id === tabId) return tab.root;
    }
  }
  return null;
}

function setWeight(node, weight) {
  node.size = { weight };
  run("layout.resize", { id: node.id, weight });
}

export default class ResizeMode extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.timer.after(150, () => this.handle.focus());
    this.root = null;
    this.tab = null;
  }

  leave() {
    closeOverlay(props().overlay);
  }

  async tree() {
    const f = focused();
    if (!f?.tab || !f.pane) return null;
    if (this.tab !== f.tab || !this.root) {
      this.tab = f.tab;
      this.root = await loadTab(f.tab);
    }
    return this.root ? { root: this.root, pane: f.pane } : null;
  }

  // Moves the divider beside the focused pane: left/right in the nearest
  // row around it, up/down in the nearest column, as tmux's resize-pane does.
  async resize(direction, step) {
    const t = await this.tree();
    if (!t) return;
    const path = pathTo(t.root, t.pane);
    if (!path) {
      // The tab changed under us (a split, a close): read it again.
      this.root = null;
      return;
    }
    const axis = direction === "left" || direction === "right" ? "row" : "column";
    const forward = direction === "right" || direction === "down";
    for (let k = path.length - 2; k >= 0; k--) {
      const split = path[k];
      const kids = split.children ?? [];
      if (split.type !== axis || kids.length < 2) continue;
      const i = kids.indexOf(path[k + 1]);
      const pair = forward
        ? i < kids.length - 1
          ? [i, i + 1]
          : [i - 1, i]
        : i > 0
          ? [i - 1, i]
          : [i, i + 1];
      const [a, b] = pair.map((n) => kids[n]);
      const total = kids.reduce((sum, n) => sum + weightOf(n), 0);
      const both = weightOf(a) + weightOf(b);
      const min = MIN_SHARE * total;
      const delta = (forward ? 1 : -1) * step * total;
      const wa = Math.min(Math.max(weightOf(a) + delta, min), both - min);
      if (both - 2 * min <= 0) return;
      setWeight(a, wa);
      setWeight(b, both - wa);
      return;
    }
  }

  async balance() {
    const t = await this.tree();
    if (!t) return;
    for (const node of walk(t.root)) {
      if (node !== t.root) setWeight(node, 1);
    }
  }

  // Keys it doesn't use go on, so prefix+r and the app's shortcuts still work.
  key(e, cx) {
    const m = e.modifiers;
    if (m.control || m.alt || m.platform) return;
    const key = e.key.toLowerCase();
    const fail = (err) => notify({ title: "Resize", body: String(err), level: "error" });
    if (key === "escape" || key === "enter") {
      this.leave();
    } else if (key === "=" || e.key_char === "=") {
      this.balance().catch(fail);
    } else if (DIRECTIONS[key]) {
      this.resize(DIRECTIONS[key], m.shift ? BIG_STEP : STEP).catch(fail);
    } else {
      return;
    }
    cx.stop_propagation();
  }

  render() {
    const t = theme();
    const hint = (keys, what) =>
      h_flex()
        .gap(5)
        .items_center()
        .child(div().text_color(t.foreground).font_semibold().child(keys))
        .child(div().text_color(t.dim).child(what));
    return h_flex()
      .id("resize-mode")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .gap(14)
      .px(14)
      .py(8)
      .items_center()
      .rounded(8)
      .bg(t.popover)
      .border_1()
      .border_color(t.accent)
      .text_size(12)
      .child(div().text_color(t.accent).font_semibold().child("RESIZE"))
      .child(hint("h j k l", "move border"))
      .child(hint("⇧", "further"))
      .child(hint("=", "balance"))
      .child(hint("esc", "done"));
  }
}
