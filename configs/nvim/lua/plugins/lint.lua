return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      for _, ft in ipairs({
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
      }) do
        opts.linters_by_ft[ft] = { "eslint_d" }
      end
    end,
  },

  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "eslint_d" } },
  },
}
