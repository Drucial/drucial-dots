# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration built on top of LazyVim, a modular Neovim starter template. The configuration uses lazy.nvim as the plugin manager and follows LazyVim's architectural patterns.

## Key Architecture

### Plugin Management

- **lazy.nvim**: Plugin manager bootstrapped in `lua/config/lazy.lua`
- **LazyVim**: Base framework providing sensible defaults and plugin configurations
- **Plugin Structure**: Custom plugins are organized in `lua/plugins/` with each file returning a plugin specification table

### Configuration Structure

- `init.lua`: Entry point that bootstraps the lazy.nvim system
- `lua/config/`: Core configuration files (options, keymaps, autocmds)
- `lua/plugins/`: Custom plugin configurations that extend or override LazyVim defaults
- `lua/plugins/snacks/`: Specialized snacks.nvim configurations

### Key Patterns

- Plugin files return Lua tables with plugin specifications
- LazyVim plugins are imported via `{ "LazyVim/LazyVim", import = "lazyvim.plugins" }`
- Custom plugins override defaults through the import system: `{ import = "plugins" }`

## Code Style and Formatting

### Lua Formatting

- **StyLua**: Code formatter configured via `stylua.toml`
- **Settings**: 2-space indentation, 120 character line width
- **Command**: `stylua .` (formats all Lua files)

## Common Commands

### Development

- **Format code**: `stylua .`
- **Check syntax**: Use Neovim's built-in Lua syntax checking (`:luafile %`)

### Plugin Management

- **Sync plugins**: `:Lazy sync` (updates all plugins to match lazy-lock.json)
- **Install plugins**: `:Lazy install`
- **Update plugins**: `:Lazy update`
- **Check plugin status**: `:Lazy`

## Important Configuration Details

### Colorscheme

- **Primary**: Rose Pine Moon variant (`rose-pine-moon`)
- **Location**: `lua/plugins/colorscheme.lua`
- Custom highlight groups for transparency and Snacks/Avante integration

### Key Customizations

- **Keymaps**: macOS-style shortcuts (Cmd+P for file finder, Cmd+S for save)
- **Integration**: Kitty terminal navigator for seamless pane switching
- **UI**: Snacks.nvim for modern UI components (dashboard, file explorer)
- **AI**: Avante.nvim and Copilot integration for AI-assisted coding

### Plugin Highlights

- **File Management**: Yazi file manager integration, Mini Files, Snacks explorer
- **Editor Enhancement**: nvim-surround, scrollview, custom buffer navigation
- **Python**: Dedicated Python configuration in `lua/plugins/python.lua`
- **Completion**: Cursor-specific completion enhancements

### Performance Notes

- Lazy loading disabled by default (`lazy = false`)
- Several default Neovim plugins disabled for performance (gzip, tar, zip plugins)
- Plugin checker enabled for automatic updates

## File Organization

When modifying plugins:

1. Check if LazyVim already provides the functionality
2. Create new files in `lua/plugins/` for new plugins
3. Use existing patterns from other plugin files
4. Follow the return table structure for plugin specifications

Lock file (`lazy-lock.json`) maintains exact plugin versions for reproducible installations.

