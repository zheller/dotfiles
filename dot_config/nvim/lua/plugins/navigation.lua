return {
	-- ── Navigation / UI ──────────────────────────────────────────────────
	{
		"junegunn/fzf",
		build = function()
			vim.fn["fzf#install"]()
		end,
	},
	{
		"junegunn/fzf.vim",
		dependencies = { "junegunn/fzf" },
		init = function()
			vim.g.fzf_layout = { up = "40%" }
			vim.g.fzf_history_dir = "~/.local/share/fzf-history"
			-- Override shell FZF_DEFAULT_OPTS with nvim-specific settings
			vim.env.FZF_DEFAULT_OPTS = "--preview 'bat --color=always --style=numbers {}' --preview-window right:60%:wrap"
		end,
	},
	{
		"nvim-tree/nvim-web-devicons",
		opts = {
			default = true,
		},
	},
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local ignored_names = {
				env = true,
				[".git"] = true,
				["__pycache__"] = true,
				htmlcov = true,
				[".DS_Store"] = true,
				[".pytest_cache"] = true,
				coverage = true,
				node_modules = true,
			}

			require("nvim-tree").setup({
				view = {
					adaptive_size = true,
				},
				filters = {
					dotfiles = false,
					custom = function(path)
						local name = vim.fs.basename(path)

						return ignored_names[name]
							or name:match("%.egg%-info$")
							or name:match("%.pyc$")
							or name:match("prof$")
							or name:match("^%.coverage")
					end,
				},
				actions = {
					open_file = {
						quit_on_open = true,
					},
				},
			})
		end,
	},
}
