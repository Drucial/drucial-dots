return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = function()
    return {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        go = { "goimports", "gofumpt" },
        ruby = { "rubocop" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        swift = { "swift_format" },
      },
      formatters = {
        rubocop = {
          command = "bundle",
          prepend_args = { "exec", "rubocop" },
          cwd = require("conform.util").root_file({ "Gemfile" }),
          require_cwd = true,
        },
      },
      format_on_save = { timeout_ms = 3000, lsp_format = "fallback" },
    }
  end,
}
