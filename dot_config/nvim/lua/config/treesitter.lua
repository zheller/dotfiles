local M = {}

local treesitter_filetypes = {
	"typescript",
	"javascript",
    "c",
    "cpp",
    "make",
	"tsx",
	"json",
	"yaml",
	"python",
	"vim",
	"vimdoc",
	"html",
	"css",
	"swift",
	-- extras (config files we edit regularly)
	"lua",
	"bash",
	"dockerfile",
	"terraform",
	"nginx",
}

function M.setup()
	-- Reuse the bash parser for zsh buffers.
	vim.treesitter.language.register("bash", "zsh")

	require("nvim-treesitter").setup({
		ensure_installed = treesitter_filetypes,
	})
end

return M
