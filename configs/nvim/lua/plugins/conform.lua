return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    for _, ft in ipairs({
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
    }) do
      opts.formatters_by_ft[ft] = { "eslint_d", "prettier" }
    end
  end,
}
