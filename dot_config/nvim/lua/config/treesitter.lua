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
	-- extras (config files we edit regularly)
	"lua",
	"bash",
	"dockerfile",
	"terraform",
	"nginx",
}

function M.setup()
	local install_dir = vim.fs.normalize(vim.fn.stdpath("data") .. "/site")
	local treesitter = require("nvim-treesitter")
	local treesitter_config = require("nvim-treesitter.configs")
	local get_install_dir = treesitter_config.get_install_dir

	-- Reuse the bash parser for zsh buffers.
	vim.treesitter.language.register("bash", "zsh")

	treesitter.setup({
		install_dir = install_dir,
        ensure_installed = treesitter_filetypes,
        highlight = { enable = true, },
	})

	-- nvim-treesitter health compares get_install_dir("") against the
	-- exact strings from nvim_list_runtime_paths().
	treesitter_config.get_install_dir = function(dir_name)
		local dir = get_install_dir(dir_name)
		if dir_name == "" then
			return vim.fs.normalize(dir)
		end
		return dir
	end


	for _, filetype in ipairs(vim.list_extend(vim.deepcopy(treesitter_filetypes), { "zsh" })) do
		vim.api.nvim_create_autocmd("FileType", {
			pattern = filetype,
			callback = function(args)
				pcall(vim.treesitter.start, args.buf)
			end,
		})
	end
end

return M
