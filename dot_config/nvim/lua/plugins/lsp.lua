return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"saghen/blink.cmp",
		},
		config = function()
			local servers = {
				"ts_ls",
				"clangd",
				"jsonls",
				"yamlls",
				"basedpyright",
				"vimls",
				"html",
				"eslint",
				"ruff",
				"lua_ls",
			}

			require("mason").setup()
			require("mason-lspconfig").setup({ ensure_installed = servers })

			-- Global capabilities for all servers (Neovim 0.11+ API).
			vim.lsp.config("*", {
				capabilities = require("blink.cmp").get_lsp_capabilities(),
			})

			vim.lsp.enable(servers)

			-- Pyright: custom root patterns + settings from coc config.
			vim.lsp.config("basedpyright", {
				root_dir = function(bufnr, on_dir)
					local root = vim.fs.root(bufnr, {
						"pyproject.toml",
						".venv",
						".git",
						".env",
						"env",
						"venv",
						"setup.cfg",
						"setup.py",
						"pyrightconfig.json",
					})
					on_dir(root or vim.fn.getcwd())
				end,
				settings = {
					basedpyright = {
						inlayHints = {
							functionReturnTypes = false,
							variableTypes = false,
							parameterTypes = false,
						},
					},
				},
			})
		end,
	},
}
