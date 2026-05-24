return {
	-- ── Theme / core deps ─────────────────────────────────────────────────
	{
		"sainnhe/sonokai",
		init = function()
			vim.g.sonokai_better_performance = 1
			vim.g.sonokai_style = "shusia"
			vim.g.sonokai_enable_italic = 1
			vim.g.sonokai_disable_italic_comment = 1
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
	},
	{ "nvim-lualine/lualine.nvim" },
	{
		"NvChad/nvim-colorizer.lua",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			filetypes = { "*" },
			user_default_options = {
				RGB = true,
				RRGGBB = true,
				RRGGBBAA = true,
				AARRGGBB = true,
				rgb_fn = true,
				hsl_fn = true,
				css = true,
				css_fn = true,
				mode = "background",
				names = false,
			},
		},
	},
	{ "nvim-lua/plenary.nvim" },
}
