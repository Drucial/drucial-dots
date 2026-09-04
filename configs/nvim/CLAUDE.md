# Neovim Config

Hand-built config on Neovim 0.12.5. Ports to macOS as well as Linux.

Known problems and planned work live in [docs/issues.md](docs/issues.md). Read it
before starting anything — a surprise you hit is likely already described there.
Add an entry when you find something worth fixing later, and delete the entry in
the same commit that fixes it.

## Non-negotiables

**No distro.** LazyVim is deliberately absent. `lua/plugins/lazyvim-disable.lua`
disables the spec rather than removing it, because Omarchy's theme file names its
colorscheme through a `LazyVim/LazyVim` marker entry. Do not add the distro back
to satisfy that marker.

**`lua/plugins/theme.lua` is a symlink**, not a file. It points at
`~/.local/state/omarchy/current/theme/neovim.lua`. Lazy's change detector only
watches files under `lua/plugins/`, so the symlink living there is what fires
`User LazyReload` on a theme switch. Replacing it with a regular file silently
kills theme hot-reload. It is also generated — never format or edit it.

It is gitignored and created by `lua/config/lazy.lua` at bootstrap, only when the
Omarchy target exists. Do not commit it: off Omarchy (the Mac) the link dangles
and the whole `plugins` import fails. There, zen-theme.nvim follows ZenTerm
instead and `lazy.lua` falls back to `rose-pine-moon`.

**Never edit `/usr/share/omarchy/`.** Reading it is fine and often useful.

## LSP

Neovim 0.11+ native API only: `vim.lsp.config()` and `vim.lsp.enable()`. Do not
use `lspconfig.setup()`.

Server overrides go through `vim.lsp.config(name, {...})`, **not** a
`lsp/<name>.lua` file in this repo. Runtimepath `lsp/*.lua` merging is last-wins
and nvim-lspconfig sorts after the user config, so a local override there is
silently defeated. This was a real bug once.

Built-in 0.11+ keymaps are global and already exist: `gra` `grn` `grr` `gri`
`grt` `grx` `gO` `K`. `gd`/`gD` are not defaults and are set in `LspAttach`.

**TypeScript is `vtsls` only.** Never run `ts_ls` alongside it — they are the
same tsserver twice, and both attach to every buffer. Dropping `ts_ls` from the
config is not enough: `mason-lspconfig` enables whatever is installed, so the
mason package must be uninstalled too. This shipped broken for a day.

Two `vtsls` settings are load-bearing on large monorepos, both measured against
craftwork: `autoUseWorkspaceTsdk` (repos pin their own TypeScript; the bundled
copy drifts) and `maxTsServerMemory` (one server indexes craftwork to ~4.5 GB,
and tsserver's 3 GB default aborts with `SIGABRT` in a restart loop).

Repos may ship a `.vscode/settings.json` that nvim never reads. It is worth
checking when a repo behaves worse here than for colleagues on VSCode.

## Keymaps

**Leader is for things Vim has no concept of** — pickers, LSP actions,
formatters, toggles. Built-in prefixes own motions, windows and list navigation.
Do not add a leader mapping that duplicates a built-in; which-key already makes
`<C-w>`, `g`, `z`, `[` and `]` browsable, so the leader copy buys nothing.

Groups: `<leader>b` buffer, `<leader>c` code, `<leader>d` diagnostics,
`<leader>f` find.

To fix an ugly description on a **built-in** mapping, add a `desc` entry to
which-key's `opts.spec`. Do not remap the key just to relabel it.

Anything needing an attached language server belongs in `LspAttach` as a
buffer-local mapping, not in `lua/config/keymaps.lua`.

## Tooling

Ruby runs through `bundle exec` — rubocop and ruby-lsp are Gemfile-pinned.
Prettier must resolve project-locally or `prettier-plugin-tailwindcss` and
`prettier-plugin-organize-imports` stop working. Swift tooling is absent on
Linux; that config is inert here and live on the Mac.

`conform.nvim`'s `opts` must stay a **function**. It calls
`require("conform.util")`, which is not on the runtimepath at spec-load time.

New runtime globals (e.g. `Snacks`) need a lazydev `library` entry with `words`,
or lua_ls reports `Undefined global`.

## Verification

Verify at runtime, not by reading. Headless probes miss things: `VeryLazy` never
fires without a UI, and rapid `:edit` cycling samples diagnostics before lua_ls
has indexed. Drive a real session with `script -qec` or tmux, and to check
which-key menus capture the rendered popup.

Target is 0 lua_ls diagnostics across all tracked Lua files.

## Conventions

`stylua` formats everything except the generated `theme.lua`. No comments by
default — top-of-file and contract docs only.

`docs/issues.md` uses one `###` heading per task: a short title and two or three
lines of context, enough to pick up cold.
