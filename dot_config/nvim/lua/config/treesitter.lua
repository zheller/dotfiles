local M = {}

local treesitter_parsers = {
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
    "markdown",
    "markdown_inline",
}

local treesitter_filetypes = {
	"typescript",
	"typescriptreact",
	"javascript",
	"javascriptreact",
	"c",
	"cpp",
	"make",
	"json",
	"yaml",
	"python",
	"vim",
	"vimdoc",
	"html",
	"css",
	"swift",
	"lua",
	"bash",
	"zsh",
	"dockerfile",
	"terraform",
	"nginx",
}

local treesitter_filetype_set = {}

for _, filetype in ipairs(treesitter_filetypes) do
	treesitter_filetype_set[filetype] = true
end

local function start_treesitter(bufnr)
	bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr

	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
		return
	end

	local filetype = vim.bo[bufnr].filetype

	if not treesitter_filetype_set[filetype] then
		return
	end

	vim.api.nvim_buf_call(bufnr, function()
		pcall(vim.treesitter.start)
	end)
end

function M.setup()
	-- Reuse the bash parser for zsh buffers.
	vim.treesitter.language.register("bash", "zsh")

	require("nvim-treesitter").setup({
		ensure_installed = treesitter_parsers,
	})

	local group = vim.api.nvim_create_augroup("UserTreesitterHighlight", { clear = true })

	vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
		group = group,
		pattern = "*",
		callback = function(args)
			start_treesitter(args.buf)
		end,
	})

	-- FileType can fire before this module is loaded when Neovim starts with file
	-- arguments or a plugin opens buffers during startup. Attach Tree-sitter to any
	-- already-loaded matching buffers so highlighting cannot be left in regex mode.
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		start_treesitter(bufnr)
	end
end

return M
