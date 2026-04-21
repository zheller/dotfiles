local M = {}

local function on_attach(client, bufnr)
	local map = function(mode, keys, fn, desc)
		vim.keymap.set(mode, keys, fn, { buffer = bufnr, desc = desc })
	end

	map("n", "gd", vim.lsp.buf.definition, "Go to definition")
	map("n", "<leader>gd", function()
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	end, "Go to definition (vsplit)")
	map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
	map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
	map("n", "gr", vim.lsp.buf.references, "Go to references")
	map("n", "K", vim.lsp.buf.hover, "Hover documentation")
	map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
	map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
	map("n", "<leader>d", vim.diagnostic.open_float, "Show diagnostics")
	map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
	map("n", "<leader>f", function()
		vim.lsp.buf.format({ async = true })
	end, "Format buffer")
	map("x", "<leader>f", function()
		vim.lsp.buf.format({ async = true })
	end, "Format selection")

	-- Document highlight on CursorHold (replaces coc's highlight autocmd).
	if client:supports_method("textDocument/documentHighlight") then
		local grp = vim.api.nvim_create_augroup("lsp_hl_" .. bufnr, { clear = true })
		vim.api.nvim_create_autocmd("CursorHold", {
			group = grp,
			buffer = bufnr,
			callback = vim.lsp.buf.document_highlight,
		})
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = grp,
			buffer = bufnr,
			callback = vim.lsp.buf.clear_references,
		})
	end

	-- Format on save for python (mirrors coc-settings.json formatOnSave).
	local fmt_on_save = { python = true }
	if client:supports_method("textDocument/formatting") and fmt_on_save[vim.bo[bufnr].filetype] then
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({ bufnr = bufnr, async = false })
			end,
		})
	end
end

local function swift_project_root(bufnr)
	local start = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
	if not start or start == "" then
		return vim.fn.getcwd()
	end

	for _, marker in ipairs({ "justfile", "buildServer.json", ".git" }) do
		local found = vim.fs.find(marker, { path = start, upward = true })[1]
		if found then
			return vim.fs.dirname(found)
		end
	end

	return vim.fn.getcwd()
end

function M.setup()
	-- Minimal LSP info command for Neovim's built-in client.
	if vim.fn.exists(":LspInfo") == 0 then
		vim.api.nvim_create_user_command("LspInfo", function()
			local bufnr = vim.api.nvim_get_current_buf()
			local clients = vim.lsp.get_clients({ bufnr = bufnr })
			if #clients == 0 then
				print("No LSP clients attached to current buffer")
				return
			end
			for _, client in ipairs(clients) do
				print(string.format("%s (id=%d) root=%s", client.name, client.id, tostring(client.config.root_dir)))
			end
		end, { desc = "Show attached LSP clients for current buffer" })
	end

	if vim.fn.exists(":LspRefreshSwift") == 0 then
		vim.api.nvim_create_user_command("LspRefreshSwift", function()
			if vim.fn.executable("just") == 0 then
				vim.notify("`just` is not installed or not in PATH", vim.log.levels.ERROR)
				return
			end

			local root = swift_project_root(vim.api.nvim_get_current_buf())
			vim.notify("Refreshing Swift LSP metadata in " .. root, vim.log.levels.INFO)

			vim.system({ "just", "lsp-refresh" }, { cwd = root, text = true }, function(result)
				vim.schedule(function()
					if result.code == 0 then
						vim.notify("Swift LSP metadata refreshed", vim.log.levels.INFO)
					else
						local err = (result.stderr and #result.stderr > 0) and result.stderr
							or (result.stdout and #result.stdout > 0 and result.stdout)
							or ("exit code " .. tostring(result.code))
						vim.notify("LspRefreshSwift failed:\n" .. err, vim.log.levels.ERROR)
					end
				end)
			end)
		end, { desc = "Run `just lsp-refresh` for current Swift project" })
	end

	-- Register keymaps for every LSP client that attaches to any buffer.
	-- Using LspAttach is the idiomatic Neovim 0.11+ approach and fires
	-- reliably regardless of how a server was started.
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("lsp_attach_config", {
			clear = true,
		}),
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			on_attach(client, args.buf)
		end,
	})
end

return M
