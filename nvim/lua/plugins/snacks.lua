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
    dashboard = {
      preset = {
        pick = function(cmd, opts)
          return LazyVim.pick(cmd, opts)()
        end,
        header = [[
      ___                   ___          ___      
     /\__\                 /\  \        /\  \     
    /:/ _/_               /::\  \      _\:\  \    
   /:/ /\__\             /:/\:\  \    /\ \:\  \   
  /:/ /:/  /__     ___  /:/  \:\  \  _\:\ \:\  \  
 /:/_/:/  /\  \   /\__\/:/__/ \:\__\/\ \:\ \:\__\ 
 \:\/:/  /\:\  \ /:/  /\:\  \ /:/  /\:\ \:\/:/  / 
  \::/__/  \:\  /:/  /  \:\  /:/  /  \:\ \::/  /  
   \:\  \   \:\/:/  /    \:\/:/  /    \:\/:/  /   
    \:\__\   \::/  /      \::/  /      \::/  /    
     \/__/    \/__/     ___\/__/        \/__/     
     /\__\             /\  \             /\__\    
    /:/ _/_      ___  /::\  \      ___  /:/ _/_   
   /:/ /\  \    /\__\/:/\:\  \    /\__\/:/ /\__\  
  /:/ /::\  \  /:/  /:/ /::\  \  /:/  /:/ /:/ _/_ 
 /:/_/:/\:\__\/:/__/:/_/:/\:\__\/:/__/:/_/:/ /\__\
 \:\/:/ /:/  /::\  \:\/:/  \/__/::\  \:\/:/ /:/  /
  \::/ /:/  /:/\:\  \::/__/   /:/\:\  \::/_/:/  / 
   \/_/:/  /\/__\:\  \:\  \   \/__\:\  \:\/:/  /  
     /:/  /      \:\__\:\__\       \:\__\::/  /   
     \/__/        \/__/\/__/        \/__/\/__/    
]],
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = "", key = "y", desc = "File Browser", action = "<CMD>Oil<CR>" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          -- { icon = ' ', key = 'x', desc = 'Lazy Extras', action = ':LazyExtras' },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
  },
}
