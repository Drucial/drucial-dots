return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    opts.diagnostics.virtual_text = false

    opts.inlay_hints = opts.inlay_hints or {}
    opts.inlay_hints.enabled = false

    opts.servers = opts.servers or {}
    opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
      settings = {
        typescript = {
          disableAutomaticTypeAcquisition = true,
          tsserver = {
            maxTsServerMemory = 8192,
            useSyntaxServer = "auto",
            watchOptions = {
              watchFile = "useFsEventsOnParentDirectory",
              watchDirectory = "useFsEvents",
              fallbackPolling = "dynamicPriority",
              synchronousWatchDirectory = false,
              excludeDirectories = {
                "**/node_modules",
                "**/.git",
                "**/.next",
                "**/.turbo",
                "**/.cache",
                "**/dist",
                "**/build",
                "**/coverage",
                "**/.expo",
                "**/test-results",
              },
            },
          },
          inlayHints = {
            enumMemberValues = { enabled = false },
            functionLikeReturnTypes = { enabled = false },
            parameterNames = { enabled = "none" },
            parameterTypes = { enabled = false },
            propertyDeclarationTypes = { enabled = false },
            variableTypes = { enabled = false },
          },
        },
        vtsls = {
          experimental = {
            useVsCodeWatcher = true,
          },
        },
      },
    })

    opts.servers.eslint = vim.tbl_deep_extend("force", opts.servers.eslint or {}, {
      enabled = false,
    })
  end,
}
