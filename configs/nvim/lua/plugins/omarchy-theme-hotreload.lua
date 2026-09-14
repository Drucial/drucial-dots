return {
  {
    name = "theme-hotreload",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    priority = 1000,
    config = function()
      local transparency_file = vim.fn.stdpath("config") .. "/plugin/after/transparency.lua"

      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyReload",
        callback = function()
          vim.schedule(function()
            local theme_plugins, colorscheme = require("config.omarchy_theme").read()
            if not colorscheme then
              return
            end

            -- Find the theme plugin and unload it
            local theme_plugin_name = nil
            for _, spec in ipairs(theme_plugins) do
              if spec[1] then
                theme_plugin_name = spec.name or require("lazy.core.plugin").Spec.get_name(spec[1])
                break
              end
            end

            -- Clear all highlight groups before applying new theme
            vim.cmd("highlight clear")
            if vim.fn.exists("syntax_on") == 1 then
              vim.cmd("syntax reset")
            end

            -- Reset background to default so colorscheme can set it properly (light themes will set to light)
            vim.o.background = "dark"

            -- Unload theme plugin modules to force full reload
            if theme_plugin_name then
              local plugin = require("lazy.core.config").plugins[theme_plugin_name]
              if plugin then
                -- Unload all lua modules from the plugin directory
                local plugin_dir = plugin.dir .. "/lua"
                require("lazy.core.util").walkmods(plugin_dir, function(modname)
                  package.loaded[modname] = nil
                  package.preload[modname] = nil
                end)
              end
            end

            -- Load the colorscheme plugin. If it's already loaded (old and new
            -- theme sharing the same plugin, e.g. generic themes on aether.nvim),
            -- lazy won't rerun setup() on a spec reload and keeps the old
            -- resolved opts in the plugin's property cache, so fully reload it
            -- to reapply setup() with the new theme's opts.
            local theme_plugin = theme_plugin_name and require("lazy.core.config").plugins[theme_plugin_name]
            if theme_plugin and theme_plugin._.loaded then
              require("lazy.core.loader").reload(theme_plugin)
            else
              require("lazy.core.loader").colorscheme(colorscheme)
            end

            vim.defer_fn(function()
              -- Apply the colorscheme (it will set background itself)
              pcall(vim.cmd.colorscheme, colorscheme)

              -- Force redraw to update all UI elements
              vim.cmd("redraw!")

              if vim.fn.filereadable(transparency_file) == 1 then
                vim.cmd.source(transparency_file)
              end

              vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
              vim.cmd("redraw!")
            end, 5)
          end)
        end,
      })
    end,
  },
}
