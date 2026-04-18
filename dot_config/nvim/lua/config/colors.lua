local M = {}

local function apply_sonokai_highlights()
	vim.cmd([[
        highlight! link pyDebug debugBreakpoint
        highlight! link jsStorageClass Red
        highlight! link jsBlockLabel Label
        highlight! link jsObjectKey Label
        highlight! link jsDebug debugBreakpoint
        highlight! link typescriptObjectLabel Label
        highlight! link typescriptDebugger debugBreakpoint
        highlight! link typescriptIdentifier BlueItalic
        highlight! link typescriptMember Function
        highlight! link typescriptIdentifierName Function
        highlight! link IncSearch DiffText
        highlight! link Search DiffText
        highlight! ColorColumn ctermbg=235
        highlight! DiagnosticUnderlineError cterm=undercurl guisp=darkred
        highlight! DiagnosticUnderlineError gui=undercurl term=underline
    ]])
end

function M.setup()
	vim.opt.termguicolors = true
	vim.cmd("set t_Co=256")
	vim.cmd([[let &t_ZH="\e[3m"]])
	vim.cmd([[let &t_ZR="\e[23m"]])

	local group = vim.api.nvim_create_augroup("SonokaiCustom", { clear = true })

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		pattern = "sonokai",
		callback = apply_sonokai_highlights,
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "BufEnter" }, {
		group = group,
		callback = apply_sonokai_highlights,
	})

	vim.cmd("colorscheme sonokai")
	apply_sonokai_highlights()
end

return M
