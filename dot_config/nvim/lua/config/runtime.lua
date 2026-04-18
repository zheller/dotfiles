local M = {}

function M.setup()
	vim.opt.packpath = vim.opt.runtimepath:get()

	-- Bootstrap lazy.nvim
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not vim.uv.fs_stat(lazypath) then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable",
			lazypath,
		})
	end
	vim.opt.rtp:prepend(lazypath)

	-- Set before plugins load: Python-dependent plugins (vim-isort) need this.
	vim.g.python3_host_prog = vim.fn.expand("~/.local/share/nvim/py3/bin/python")
end

return M
