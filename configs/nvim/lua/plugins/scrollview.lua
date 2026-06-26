return {
  "dstein64/nvim-scrollview",
  event = "BufReadPost",
  opts = {
    current_only = true,
    signs_on_startup = { "diagnostics" },
  },
}
