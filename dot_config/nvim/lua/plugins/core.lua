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
		branch = "master",
		build = ":TSUpdate",
	},
	{ "nvim-lualine/lualine.nvim" },
	{ "nvim-lua/plenary.nvim" },
}
