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
      -- Lua
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
      -- Tailwind CSS
      tailwindcss = {
        -- Explicit filetypes keeps it snappy and avoids false positives
        filetypes = {
          "html",
          "css",
          "scss",
          "sass",
          "less",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
          "svelte",
          "astro",
          "heex",
          "elixir",
          "templ",
          "php",
          "twig",
          "blade",
        },
        -- If your project has a tailwind.config.* the server will pick it up automatically.
        -- These settings just make completions great in JS/TS + class helpers.
        settings = {
          tailwindCSS = {
            includeLanguages = {
              javascript = "javascriptreact",
              typescript = "typescriptreact",
            },
            -- Add any class extraction helpers you use:
            experimental = {
              classRegex = {
                "tw`([^`]*)`", -- twin.macro / tw`...`
                'tw$begin:math:text$"([^"]*)"%?\\$end:math:text$', -- tw("...")
                "cva$begin:math:text$([^)]*)\\$end:math:text$", -- cva(...)
                "clsx$begin:math:text$([^)]*)\\$end:math:text$", -- clsx(...)
                "classnames$begin:math:text$([^)]*)\\$end:math:text$", -- classnames(...)
                -- Tailwind v4-style @apply-in-CSS is picked up via CSS filetypes
              },
            },
            validate = true,
          },
        },
        root_dir = function(fname)
          -- Prefer project roots that actually have Tailwind/config/build files
          return require("lspconfig.util").root_pattern(
            "tailwind.config.js",
            "tailwind.config.cjs",
            "tailwind.config.ts",
            "postcss.config.js",
            "postcss.config.cjs",
            "postcss.config.ts",
            "package.json",
            ".git"
          )(fname)
        end,
      },
    })

    -- setup (preserve your table if you add handlers later)
    opts.setup = opts.setup or {
      -- ["*"] = function(server, server_opts) end,
    }

    return opts
  end,
}
