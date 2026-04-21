local M = {}

function M.setup()
	local opt = vim.opt

	opt.ambiwidth = "double"
	opt.autoindent = true
	opt.autoread = true
	opt.clipboard = "unnamed"
	opt.backspace = { "indent", "eol", "start" }
	opt.expandtab = true
	opt.tabstop = 4
	opt.foldlevelstart = 99
	opt.laststatus = 2
	opt.mouse = "a"
	opt.backup = false
	opt.swapfile = false
	opt.number = true
	opt.textwidth = 100
	opt.wildignore = {
		"*.pyc",
		"env/**",
		"venv/**",
		"bower_components/**",
		"node_modules/**",
	}
	opt.fixeol = true
	opt.updatetime = 100
	opt.encoding = "utf-8"
	opt.signcolumn = "yes"
	opt.showcmd = false
	opt.colorcolumn = "100"

	vim.cmd("scriptencoding utf-8")
	vim.cmd("filetype plugin indent on")
	vim.cmd("syntax enable")

	-- Keep legacy runtimepath-managed plugins behaving the same.
	vim.g.ragtag_global_maps = 1
end

return M
