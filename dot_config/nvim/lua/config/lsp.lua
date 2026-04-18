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
	if client.supports_method("textDocument/documentHighlight") then
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
	if client.supports_method("textDocument/formatting") and fmt_on_save[vim.bo[bufnr].filetype] then
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({ bufnr = bufnr, async = false })
			end,
		})
	end
end

function M.setup()
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
