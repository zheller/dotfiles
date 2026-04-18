local M = {}

local function has_errors()
	return #vim.diagnostic.get(0, {
		severity = vim.diagnostic.severity.ERROR,
	}) > 0
end

local function diagnostics_icon()
	if has_errors() then
		return "❌"
	end

	return "✅"
end

local function modified_status()
	if vim.bo.modified then
		return "[+]"
	end

	return ""
end

local function resized_filename()
	local filename = vim.fn.expand("%")
	local winwidth = vim.fn.winwidth(0)

	if filename == "" then
		return "[No Name]"
	end

	if vim.fn.strchars(filename) > winwidth then
		filename = vim.fn.pathshorten(filename)
	end

	if vim.fn.strchars(filename) > winwidth then
		filename = vim.fn.expand("%:t")
	end

	return filename
end

local function fugitive_head()
	if vim.fn.exists("*FugitiveHead") == 0 then
		return ""
	end

	return vim.fn.pathshorten(vim.fn.FugitiveHead())
end

local function to_hex(color)
	if color == nil then
		return "NONE"
	end

	return string.format("#%06x", color)
end

local function section_color(group)
	local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
	return {
		fg = to_hex(hl.fg),
		bg = to_hex(hl.bg),
	}
end

local function color_with_bg(group, bg)
	local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
	return {
		fg = to_hex(hl.fg),
		bg = bg,
		gui = "bold",
	}
end

local function lualine_theme()
	local active = section_color("StatusLine")
	local inactive = section_color("StatusLineNC")

	return {
		normal = {
			a = color_with_bg("Keyword", active.bg),
			b = active,
			c = active,
		},
		insert = {
			a = color_with_bg("String", active.bg),
			b = active,
			c = active,
		},
		visual = {
			a = color_with_bg("Type", active.bg),
			b = active,
			c = active,
		},
		replace = {
			a = color_with_bg("Constant", active.bg),
			b = active,
			c = active,
		},
		command = {
			a = color_with_bg("Function", active.bg),
			b = active,
			c = active,
		},
		inactive = { a = inactive, b = inactive, c = inactive },
	}
end

function M.setup()
	local ok, lualine = pcall(require, "lualine")
	if not ok then
		return
	end

	lualine.setup({
		options = {
			icons_enabled = false,
			theme = lualine_theme(),
			component_separators = "",
			section_separators = "",
		},
		sections = {
			lualine_a = {
				{
					"mode",
				},
				diagnostics_icon,
			},
			lualine_b = {
				resized_filename,
				modified_status,
			},
			lualine_c = {
				{
					function()
						return "»"
					end,
				},
				{
					fugitive_head,
					cond = function()
						return fugitive_head() ~= ""
					end,
				},
			},
			lualine_x = {
				{
					"lsp_status",
					icon = "",
					show_name = true,
					symbols = {
						spinner = {
							"⠋",
							"⠙",
							"⠹",
							"⠸",
							"⠼",
							"⠴",
							"⠦",
							"⠧",
							"⠇",
							"⠏",
						},
						done = "✓",
						separator = " ",
					},
				},
				"filetype",
			},
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
		inactive_sections = {
			lualine_a = {},
			lualine_b = { resized_filename },
			lualine_c = {},
			lualine_x = { "filetype" },
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
	})
end

return M
