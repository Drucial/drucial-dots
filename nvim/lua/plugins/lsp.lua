return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- Keep whatever LazyVim sets, then layer your changes on top

    -- Ensure folds table exists so LazyVim doesn't crash
    opts.folds = opts.folds or { enabled = false }

    -- diagnostics
    opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, {
      underline = true,
      update_in_insert = false,
      virtual_text = false, -- VSCode-style: no inline text
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
          [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
          [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
          [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
        },
      },
      float = {
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })

    -- inlay hints
    opts.inlay_hints = vim.tbl_deep_extend("force", { enabled = false, exclude = { "vue" } }, opts.inlay_hints or {})

    -- codelens
    opts.codelens = vim.tbl_deep_extend("force", { enabled = false }, opts.codelens or {})

    -- capabilities
    opts.capabilities = vim.tbl_deep_extend("force", opts.capabilities or {}, {
      workspace = {
        fileOperations = {
          didRename = true,
          willRename = true,
        },
      },
    })

    -- format
    opts.format = vim.tbl_deep_extend("force", opts.format or {}, {
      formatting_options = nil,
      timeout_ms = nil,
    })

    -- servers
    opts.servers = vim.tbl_deep_extend("force", opts.servers or {}, {
      lua_ls = {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            codeLens = { enable = true },
            completion = { callSnippet = "Replace" },
            doc = { privateName = { "^_" } },
            hint = {
              enable = true,
              setType = false,
              paramType = true,
              paramName = "Disable",
              semicolon = "Disable",
              arrayIndex = "Disable",
            },
          },
        },
      },
    })

    -- setup (preserve your table if you add handlers later)
    opts.setup = opts.setup or {
      -- ["*"] = function(server, server_opts) end,
    }

    return opts
  end,
}
