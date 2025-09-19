return {
  "folke/snacks.nvim",
  event = "VeryLazy",
  opts = {
    explorer = {
      enabled = false,
    },
    picker = {
      hidden = true,
      backdrop = false,
      win = {
        styles = {
          position = "float",
          backdrop = false,
          height = 0.9,
          width = 0.9,
          zindex = 50,
        },
      },
    },
    zen = {
      enabled = true,
      win = {
        styles = "minimal",
      },
    },
  },
}
