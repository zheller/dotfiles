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
			vim.env.FZF_DEFAULT_OPTS =
				"--preview 'bat --color=always --style=numbers {}' --preview-window right:60%:wrap"
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
			local last_focused_winid

			local function is_tree_target_window(winid)
				if not winid or not vim.api.nvim_win_is_valid(winid) then
					return false
				end

				local config = vim.api.nvim_win_get_config(winid)
				if config.relative ~= "" then
					return false
				end

				local bufnr = vim.api.nvim_win_get_buf(winid)
				return vim.bo[bufnr].filetype ~= "NvimTree"
			end

			local function remember_focused_window(winid)
				if is_tree_target_window(winid) then
					last_focused_winid = winid
				end
			end

			local function get_last_focused_window()
				if is_tree_target_window(last_focused_winid) then
					return last_focused_winid
				end

				for _, winid in ipairs(vim.api.nvim_list_wins()) do
					if is_tree_target_window(winid) then
						last_focused_winid = winid
						return winid
					end
				end

				return -1
			end

			remember_focused_window(vim.api.nvim_get_current_win())

			vim.api.nvim_create_autocmd("WinEnter", {
				group = vim.api.nvim_create_augroup("nvim-tree-last-focused-window", { clear = true }),
				callback = function()
					remember_focused_window(vim.api.nvim_get_current_win())
				end,
			})

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

			local git_diff_tree = require("custom.git_diff_tree")

			require("nvim-tree").setup({
				on_attach = function(bufnr)
					local api = require("nvim-tree.api")
					api.map.on_attach.default(bufnr)

					vim.keymap.set("n", "gD", git_diff_tree.toggle, {
						buffer = bufnr,
						silent = true,
						desc = "Toggle git diff tree",
					})
				end,
				view = {
					adaptive_size = true,
				},
				renderer = {
					highlight_git = "name",
					icons = {
						show = {
							git = false,
						},
					},
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
							or git_diff_tree.should_filter_path(path)
					end,
				},
				actions = {
					open_file = {
						quit_on_open = false,
						window_picker = {
							enable = true,
							picker = get_last_focused_window,
						},
					},
				},
			})
		end,
	},
}
