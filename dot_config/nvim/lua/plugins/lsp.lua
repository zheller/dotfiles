return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"saghen/blink.cmp",
		},
		config = function()
			local mason_servers = {
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

			-- sourcekit is provided by Xcode and cannot be installed via Mason
			local all_servers = vim.list_extend(vim.list_slice(mason_servers), { "sourcekit" })

			require("mason").setup()
			require("mason-lspconfig").setup({ ensure_installed = mason_servers })

			-- Global capabilities for all servers (Neovim 0.11+ API).
			vim.lsp.config("*", {
				capabilities = require("blink.cmp").get_lsp_capabilities(),
			})

			local function sourcekit_root(bufnr)
				local start = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
				if not start or start == "" then
					return vim.fn.getcwd()
				end

				-- Prefer top-level build-server workspaces (Xcode projects), then SwiftPM.
				local build_server = vim.fs.find("buildServer.json", { path = start, upward = true })[1]
				if build_server then
					return vim.fs.dirname(build_server)
				end

				local package_swift = vim.fs.find("Package.swift", { path = start, upward = true })[1]
				if package_swift then
					return vim.fs.dirname(package_swift)
				end

				local git_dir = vim.fs.find(".git", { path = start, upward = true })[1]
				if git_dir then
					return vim.fs.dirname(git_dir)
				end

				return vim.fn.getcwd()
			end

			local sourcekit_caps = require("blink.cmp").get_lsp_capabilities()
			if sourcekit_caps.textDocument then
				-- Work around SourceKitService instability seen with semantic token requests.
				sourcekit_caps.textDocument.semanticTokens = nil
			end

			-- sourcekit-lsp: use Xcode toolchain binary.
			vim.lsp.config("sourcekit", {
				cmd = { "xcrun", "sourcekit-lsp" },
				capabilities = sourcekit_caps,
				root_dir = function(bufnr, on_dir)
					on_dir(sourcekit_root(bufnr))
				end,
			})

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

			-- Enable after per-server config so overrides apply on first attach.
			vim.lsp.enable(all_servers)
		end,
	},
}
