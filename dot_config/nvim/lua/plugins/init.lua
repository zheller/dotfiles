local M = {}

function M.setup()
	local specs = {}

	vim.list_extend(specs, require("plugins.lsp"))
	vim.list_extend(specs, require("plugins.completion"))
	vim.list_extend(specs, require("plugins.languages"))
	vim.list_extend(specs, require("plugins.navigation"))
	vim.list_extend(specs, require("plugins.editing"))
	vim.list_extend(specs, require("plugins.core"))

	require("lazy").setup(specs, {
		install = { colorscheme = { "sonokai", "habamax" } },
	})
end

return M
