local M = {}

function M.spaces(width)
	vim.bo.expandtab = true
	vim.bo.tabstop = width
	vim.bo.shiftwidth = width
	vim.bo.softtabstop = width
end

return M
