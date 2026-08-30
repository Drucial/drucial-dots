return {
	-- Load all theme plugins but don't apply them
	-- This ensures all colorschemes are available for hot-reloading
	--
	-- Omarchy 4 generates most theme specs from default/themed/neovim.lua.tpl on
	-- top of aether, so the single-theme plugins below (ethereal, vantablack,
	-- white, monokai-pro, miasma) are only reached by Omarchy 3.8, which ships a
	-- neovim.lua per theme. Keep them until 3.8 is out of support.
	{
		"ribru17/bamboo.nvim",
		lazy = true,
		priority = 1000,
	},
	-- Name and branch must match Omarchy 4's generated theme spec
	-- (default/themed/neovim.lua.tpl). lazy merges specs by url and lets an
	-- explicit name rename the merged plugin, so a bare "bjarneo/aether.nvim"
	-- here builds the cache into lazy/aether.nvim while every aether-themed
	-- Omarchy 4 install renames it to lazy/aether at runtime -- a directory the
	-- package never shipped. That cost a network clone on first launch, and the
	-- theme fell back to tokyonight until nvim was restarted.
	{
		"bjarneo/aether.nvim",
		branch = "v3",
		name = "aether",
		lazy = true,
		priority = 1000,
	},
	{
		"bjarneo/ethereal.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"bjarneo/hackerman.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"bjarneo/vantablack.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"bjarneo/white.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		priority = 1000,
	},
	{
		"neanias/everforest-nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"kepano/flexoki-neovim",
		lazy = true,
		priority = 1000,
	},
	{
		"ellisonleao/gruvbox.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"rebelot/kanagawa.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"tahayvr/matteblack.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"gthelding/monokai-pro.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"EdenEast/nightfox.nvim",
		lazy = true,
		priority = 1000,
	},
	-- ZenTerm's catalog names these three and Omarchy never did, so they arrive with
	-- zen-theme.nvim rather than with a theme switcher.
	{
		"shaunsingh/nord.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"Mofiqul/dracula.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"maxmx03/solarized.nvim",
		lazy = true,
		priority = 1000,
	},
	-- Families ZenTerm's catalog added alongside zen-theme.nvim.
	-- Zenbones is Lush-based, but lush.nvim is optional: compat mode uses the precompiled
	-- colorschemes instead, which is all we need since ZenTerm names them directly.
	{
		"zenbones-theme/zenbones.nvim",
		lazy = true,
		priority = 1000,
		init = function()
			vim.g.zenbones_compat = 1
		end,
	},
	{
		"projekt0n/github-nvim-theme",
		lazy = true,
		priority = 1000,
	},
	{
		"webhooked/kanso.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"sainnhe/gruvbox-material",
		lazy = true,
		priority = 1000,
	},
	{
		"cocopon/iceberg.vim",
		lazy = true,
		priority = 1000,
	},
	{
		"nanotech/jellybeans.vim",
		lazy = true,
		priority = 1000,
	},
	{
		"bluz71/vim-moonfly-colors",
		name = "moonfly",
		lazy = true,
		priority = 1000,
	},
	{
		"savq/melange-nvim",
		name = "melange",
		lazy = true,
		priority = 1000,
	},
	{
		"nyoom-engineering/oxocarbon.nvim",
		-- Its rockspec pulls fennel to compile fnl/, but the repo ships the
		-- built lua/ and colors/. Skip the luarocks build lazy infers from it.
		build = false,
		lazy = true,
		priority = 1000,
	},
	{
		"datsfilipe/vesper.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = true,
		priority = 1000,
	},
	{
		"ficcdaf/ashen.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"folke/tokyonight.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"OldJobobo/miasma.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"OldJobobo/retro-82.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"omacom-io/lumon.nvim",
		lazy = true,
		priority = 1000,
	},
}
