-- Rex worktree settings: where worktrees live and which git-ignored paths each repo carries into a new one.
-- Carry paths are relative to the repo; tracked paths and paths leaving the repo are skipped.
return {
  root = "~/.rex-worktrees",
  repos = {
    ["~/Dev/zen-term"] = {
      carry = { "Sources/TerminalKit/Resources/ghostty-resources", "Frameworks/GhosttyKit.xcframework" },
    },
    ["~/Dev/craftwork"] = {
      carry = {
        ".env.local",
        "apps/rails/.overmind.env.local",
        "apps/rails/config/credentials/development.key",
        "apps/rails/config/credentials/production.key",
      },
    },
    ["~/Dev/cohaus"] = {
      carry = { ".env.local", "apps/mobile-app/.env.local" },
    },
    ["~/Dev/drucial-dot-dev"] = {
      carry = { ".env.local", "node_modules" },
    },
  },
}
