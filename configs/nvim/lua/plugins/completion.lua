return {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = { "rafamadriz/friendly-snippets" },
  event = "InsertEnter",
  opts = {
    keymap = { preset = "default" },
    completion = {
      list = {
        selection = { preselect = false, auto_insert = false },
      },
      menu = { auto_show = true },
      documentation = { auto_show = false },
      ghost_text = { enabled = false },
    },
    sources = {
      default = { "lazydev", "lsp", "path", "snippets", "buffer" },
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
      },
    },
  },
}
