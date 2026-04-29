local M = {}

local function open_scratch(split)
	if split then
		vim.cmd("split")
	end

	require("config.commands").open_scratch()
end

local function fzf_open(cmd)
	if vim.fn.winnr("$") > 1 then
		local filetype = vim.bo.filetype
		if not vim.bo.modifiable or filetype == "NvimTree" or filetype == "qf" then
			vim.cmd("wincmd p")
		end
	end

	vim.cmd(cmd)
end

local function refresh_tree()
	local api = require("nvim-tree.api")
	local current_win = vim.api.nvim_get_current_win()

	api.tree.open()
	api.tree.reload()

	if vim.api.nvim_win_is_valid(current_win) then
		local buffer = vim.api.nvim_win_get_buf(current_win)

		if vim.bo[buffer].filetype ~= "NvimTree" then
			vim.api.nvim_set_current_win(current_win)
		end
	end
end

function M.setup()
	local map = vim.keymap.set

	map("x", "p", [["_dP]])

	map("i", "<M-o>", "<Esc>o")
	map("i", "<C-j>", "<Down>")

	map("n", "<C-S>", function()
		open_scratch(false)
	end, { silent = true, desc = "Open scratch buffer" })

	map("n", "<leader><C-S>", function()
		open_scratch(true)
	end, { silent = true, desc = "Open scratch buffer in split" })

	map("n", "''", "<C-^>", { silent = true })

	map("n", "<C-J>", "<Cmd>bnext<CR>", { silent = true })
	map("n", "<C-H>", "<Cmd>bprevious<CR>", { silent = true })

	map("n", "gl", [["_yiw:s/\(\%#\w\+\)\(\_W\+\)\(\w\+\)/\3\2\1/<CR><C-o>/\w\+\_W\+<CR><C-l>]], { silent = true })

	map("n", "<F10>", "<Cmd>Inspect<CR>", { silent = true })
	map("n", "<CR>", "<Cmd>nohlsearch<CR><CR>", { silent = true })

	map("n", "<leader>ev", function()
		local init_lua = vim.fn.stdpath("config") .. "/init.lua"
		vim.cmd("vsplit " .. vim.fn.fnameescape(init_lua))
	end, { silent = true, desc = "Edit init.lua" })

	map("x", "<C-r>", [["hy:%s/<C-r>h//gc<left><left><left>]])

	map("n", "<C-N>", function()
		require("nvim-tree.api").tree.focus()
	end, { silent = true, desc = "Focus file tree" })
	map("n", "<Leader>R", refresh_tree, { silent = true })

	map({ "n", "x", "o" }, "<C-z>", "<Nop>")

	map("n", "<leader>t", function()
		fzf_open("FZF")
	end, { silent = true })

	map("n", "<leader>g", "<Cmd>Rg<CR>", { silent = true })
	map("n", "<leader>r", "<Cmd>Rg<CR>", { silent = true })
end

return M
