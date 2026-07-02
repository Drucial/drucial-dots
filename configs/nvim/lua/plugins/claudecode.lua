-- Claude Code IDE integration. Related pieces of the setup:
--   ~/Dev/scripts/dev          — launches `claude --ide` after waiting for the
--                                lockfile this plugin writes to ~/.claude/ide/.
--   kitty/kitty.conf           — needs `allow_remote_control yes` for kitty @ launch.
--   nvim/lua/config/autocmds.lua — fs watcher that reloads buffers when Claude
--                                  edits a file from its own kitty pane.
return {
  {
    "coder/claudecode.nvim",
    -- Eager-load so the IDE WebSocket lockfile exists at nvim startup. The dev
    -- script races this on launch; lazy-loading on keys would lose the race.
    lazy = false,
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal_cmd = vim.fn.expand("~/.local/bin/claude"),
      terminal = {
        -- External so Claude renders natively in kitty. An internal nvim
        -- terminal (snacks/native split) corrupts its grid when diffs open
        -- in a new tab — :redraw! can't fix it because the grid itself
        -- desyncs from Claude's TUI on tab switch.
        provider = "external",
        provider_opts = {
          -- Function form (not a string template) so the IDE env vars get
          -- emitted as `--env KEY=val` argv to kitty. `kitty @ launch` is IPC
          -- to the kitty server, so jobstart's env never reaches the spawned
          -- window — the string form silently drops the integration.
          external_terminal_cmd = function(cmd_string, env_table)
            local cmd = {
              "kitty",
              "@",
              "launch",
              "--type=window",
              "--location=vsplit",
              "--cwd=current",
              "--bias=30",
              "--title=Claude",
            }
            for k, v in pairs(env_table or {}) do
              table.insert(cmd, "--env")
              table.insert(cmd, k .. "=" .. tostring(v))
            end
            vim.list_extend(cmd, vim.split(cmd_string, " ", { trimempty = true }))
            return cmd
          end,
        },
      },
      diff_opts = {
        open_in_new_tab = true,
        keep_terminal_focus = true,
      },
    },
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<C-;>", "<cmd>ClaudeCode<cr>", mode = { "n", "i", "v", "t" }, desc = "Toggle Claude" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude Model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file from tree",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
      },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
}
