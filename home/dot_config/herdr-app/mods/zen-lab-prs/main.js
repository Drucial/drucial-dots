// Right-panel list of the person's open pull requests, ones awaiting their review and unanswered mentions; a click opens zen-octo on that PR.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, run, setShared, shared, theme, window } from "herdr";

const REFRESH = 60000;
const RETURN_REFRESH = 15000;
const WAKE_CHECK = 5000;
const GROUPS = [
  { key: "mine", title: "My PRs", search: "author:@me" },
  { key: "review", title: "To review", search: "review-requested:@me" },
  { key: "mentioned", title: "Mentioned", search: "mentions:@me", unansweredOnly: true },
];
const LIST_QUERY = `query {
  viewer { login }
${GROUPS.map((g) => `  ${g.key}: search(query: "is:pr is:open ${g.search} sort:updated-desc", type: ISSUE, first: 30) { nodes { ...pr } }`).join("\n")}
}
fragment pr on PullRequest {
  id updatedAt number title url isDraft mergeable mergeStateStatus reviewDecision
  repository { name nameWithOwner }
  comments { totalCount }
  reviewThreads(first: 100) { totalCount nodes { isResolved } }
  commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
}`;
const conversationQuery = (ids) => `query {
  nodes(ids: ${JSON.stringify(ids)}) {
    ... on PullRequest {
      id author { login } body createdAt
      comments(last: 50) { nodes { author { login } body createdAt } }
      reviews(last: 30) { nodes { author { login } body createdAt } }
      reviewThreads(last: 50) { nodes { comments(last: 30) { nodes { author { login } body createdAt } } } }
    }
  }
}`;

// Mentioned after the person last commented or reviewed; only the latest 50 comments, 30 reviews and 50 threads are read.
function unanswered(pr, login) {
  const posts = [
    { author: pr.author, body: pr.body, createdAt: pr.createdAt },
    ...pr.comments.nodes,
    ...pr.reviews.nodes,
    ...pr.reviewThreads.nodes.flatMap((t) => t.comments.nodes),
  ];
  const mention = new RegExp(`@${login}(?![\\w-])`, "i");
  const latest = (list) => list.reduce((at, p) => (p.createdAt > at ? p.createdAt : at), "");
  const mine = (p) => p.author?.login?.toLowerCase() === login.toLowerCase();
  const lastMention = latest(posts.filter((p) => !mine(p) && mention.test(p.body ?? "")));
  return lastMention > latest(posts.filter(mine));
}

async function graphql(query) {
  const r = await exec("gh", ["api", "graphql", "-f", `query=${query}`]);
  if (r.code !== 0) throw new Error(r.stderr.trim() || "gh api failed");
  return JSON.parse(r.stdout).data;
}

// Rereads a conversation only when its PR's updatedAt moved; `replies` (id -> {updatedAt, needsReply}) carries over between calls.
async function fetchAll(replies) {
  const data = await graphql(LIST_QUERY);
  const login = data.viewer.login;
  const all = new Map(GROUPS.flatMap((g) => data[g.key].nodes.filter((n) => n.id)).map((n) => [n.id, n]));
  const stale = [...all.values()].filter((n) => replies.get(n.id)?.updatedAt !== n.updatedAt).map((n) => n.id);
  for (let i = 0; i < stale.length; i += 100) {
    const { nodes } = await graphql(conversationQuery(stale.slice(i, i + 100)));
    for (const c of nodes) if (c) replies.set(c.id, { updatedAt: all.get(c.id).updatedAt, needsReply: unanswered(c, login) });
  }
  for (const id of replies.keys()) if (!all.has(id)) replies.delete(id);
  const needsReply = (n) => replies.get(n.id)?.needsReply ?? false;
  const listed = new Set();
  const firstListing = (n) => !listed.has(n.id) && listed.add(n.id);
  const keep = (g) => (n) => n.id && (!g.unansweredOnly || needsReply(n)) && firstListing(n);
  return Object.fromEntries(GROUPS.map((g) => [g.key, data[g.key].nodes.filter(keep(g)).sort((a, b) => a.isDraft - b.isDraft).map((n) => ({
    ...n,
    checks: n.commits.nodes[0]?.commit.statusCheckRollup?.state ?? null,
    comments: n.comments.totalCount + n.reviewThreads.totalCount,
    unresolved: n.reviewThreads.nodes.filter((r) => !r.isResolved).length,
    needsReply: needsReply(n),
  }))]));
}

// GitHub's own verdict under the repo's rules; BLOCKED doesn't say which rule, so the reasons are the likely ones.
function mergeState(pr) {
  if (pr.mergeable === "CONFLICTING" || pr.mergeStateStatus === "DIRTY") return { tone: "bad", why: "Merge conflicts" };
  switch (pr.mergeStateStatus) {
    case "CLEAN":
    case "HAS_HOOKS":
      return { tone: "good", why: "Ready to merge" };
    case "UNSTABLE":
      return { tone: "good", why: "Mergeable; optional checks failing" };
    case "BEHIND":
      return { tone: "warn", why: "Behind the base branch" };
    case "BLOCKED": {
      const reasons = [];
      if (pr.reviewDecision === "REVIEW_REQUIRED") reasons.push("Needs approval");
      if (pr.reviewDecision === "CHANGES_REQUESTED") reasons.push("Changes requested");
      if (pr.unresolved > 0) reasons.push(`${pr.unresolved} unresolved conversation${pr.unresolved === 1 ? "" : "s"}`);
      if (pr.checks && pr.checks !== "SUCCESS") reasons.push("Required checks");
      return { tone: "warn", why: `Blocked: ${reasons.length ? reasons.join(", ") : "repository rules"}` };
    }
    default:
      return null;
  }
}

function checksMark(state, t) {
  if (state === "SUCCESS") return svg("mods/workspace-chrome/check.svg").size(13).flex_none().text_color(t.ansi2);
  if (state === "FAILURE" || state === "ERROR") return svg("mods/workspace-chrome/x.svg").size(13).flex_none().text_color(t.ansi1);
  if (state === "PENDING" || state === "EXPECTED") return svg("mods/workspace-chrome/spinner.svg").size(11).flex_none().text_color(t.ansi3).spin(900);
  return null;
}

function mergeMark(pr, t) {
  const state = mergeState(pr);
  if (!state) return null;
  const color = { good: t.ansi2, warn: t.ansi3, bad: t.ansi1 }[state.tone];
  return div().id(`merge-${pr.url}`).flex_none().tooltip(state.why)
    .child(svg("mods/zen-lab-prs/merge.svg").size(12).text_color(color));
}

export default class PullRequests extends View {
  init(_props, cx) {
    this.prs = {};
    this.error = null;
    this.loading = true;
    this.folded = new Set(JSON.parse(localStorage.getItem("prs.folded") ?? "[]"));
    this.replies = new Map();
    this.fetchedAt = 0;
    this.wasActive = true;
    this.refresh(cx);
    cx.timer.every(WAKE_CHECK, (cx) => this.maybeRefresh(cx));
  }

  maybeRefresh(cx) {
    const active = Boolean(window().active);
    const age = Date.now() - this.fetchedAt;
    if (active && (age >= REFRESH || (!this.wasActive && age >= RETURN_REFRESH))) this.refresh(cx);
    this.wasActive = active;
  }

  refresh(cx) {
    if (this.refreshing) return;
    this.refreshing = true;
    this.fetchedAt = Date.now();
    cx.spawn(async (cx) => {
      try {
        this.prs = await fetchAll(this.replies);
        this.error = null;
      } catch (e) {
        this.error = String(e.message ?? e);
      }
      this.loading = false;
      this.refreshing = false;
      cx.notify();
    });
  }

  openPR(url) {
    setShared("floats.target", { ...(shared("floats.target") ?? {}), "zen-octo-pr": url });
    run("drucial-floats.zen-octo-pr");
  }

  toggleGroup(key, cx) {
    this.folded.has(key) ? this.folded.delete(key) : this.folded.add(key);
    localStorage.setItem("prs.folded", JSON.stringify([...this.folded]));
    cx.notify();
  }

  header(group, count, first, t) {
    const folded = this.folded.has(group.key);
    return h_flex().id(`prs-head-${group.key}`).h(first ? 26 : 42).pt(first ? 0 : 16).flex_none().px(8).gap(7).items_center()
      .text_size(13).text_color(t.muted).cursor_pointer().hover((s) => s.text_color(t.foreground))
      .on_click((_e, cx) => this.toggleGroup(group.key, cx))
      .child(svg("mods/workspace-chrome/git-compare.svg").size(14).flex_none())
      .child(div().flex_1().truncate().child(group.title))
      .when(count > 0, (el) => el.child(div().flex_none().text_size(11.5).text_color(t.dim).child(`${count}`)))
      .child(svg(`mods/workspace-chrome/chevron-${folded ? "right" : "down"}.svg`).size(14).flex_none());
  }

  row(group, pr, t) {
    const checks = checksMark(pr.checks, t);
    const merge = mergeMark(pr, t);
    return v_flex().id(`pr-${group.key}-${pr.url}`).px(8).h(44).flex_none().rounded(8).justify_center().gap(2)
      .hover((s) => s.bg(t.hover))
      .tooltip(`${pr.repository.nameWithOwner}#${pr.number} ${pr.title}`)
      .on_click(() => this.openPR(pr.url))
      .child(h_flex().items_center().gap(6)
        .child(div().flex_1().min_w(0).truncate().text_size(12.5).text_color(t.muted).child(pr.title))
        .when(Boolean(checks), (el) => el.child(checks))
        .when(Boolean(merge), (el) => el.child(merge)))
      .child(h_flex().items_center().gap(6).text_size(11).text_color(t.dim)
        .child(div().min_w(0).truncate().child(pr.repository.name))
        .child(div().flex_none().child(`#${pr.number}`))
        .child(div().flex_none().child(pr.isDraft ? "draft" : "ready"))
        .when(pr.comments > 0 || pr.needsReply, (el) => el.child(h_flex().id(`talk-${pr.url}`).flex_none().items_center().gap(3)
          .when(pr.needsReply, (b) => b.text_color(t.ansi3).tooltip("You were mentioned and haven't replied"))
          .child(svg("mods/zen-lab-prs/message.svg").size(11))
          .when(pr.comments > 0, (b) => b.child(`${pr.comments}`)))));
  }

  note(id, text, t) {
    return div().id(id).h(28).flex_none().px(8).flex().items_center().text_size(12).text_color(t.dim).truncate().child(text);
  }

  sections(t) {
    if (this.error && !Object.keys(this.prs).length) return [this.header(GROUPS[0], 0, true, t), this.note("prs-error", this.error, t)];
    const shown = this.shownGroups();
    if (!shown.length) return [this.note("prs-none", "No open pull requests", t)];
    return shown.flatMap((g, i) => {
      const list = this.prs[g.key] ?? [];
      const head = this.header(g, list.length, i === 0, t);
      if (this.folded.has(g.key)) return [head];
      if (this.loading) return [head, this.note(`prs-loading-${g.key}`, "Loading…", t)];
      return [head, ...list.map((pr) => this.row(g, pr, t))];
    });
  }

  shownGroups() {
    return GROUPS.filter((g) => this.loading || this.prs[g.key]?.length);
  }

  heading(t) {
    const total = GROUPS.reduce((n, g) => n + (this.prs[g.key]?.length ?? 0), 0);
    return h_flex().h(30).flex_none().px(10).gap(8).items_center().border_b(1).border_color(t.border).text_size(12)
      .child(div().flex_1().font_medium().text_color(t.foreground).child("Pull requests"))
      .when(total > 0, (el) => el.child(div().text_size(10.5).text_color(t.muted).child(`${total} open`)));
  }

  render() {
    const t = theme();
    return v_flex().size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(this.heading(t))
      .child(v_flex().id("prs-list").flex_1().min_h(0).p(6).pb(14).overflow_y_scroll()
        .children(this.sections(t)));
  }
}
