local M = {}

function M.wipe_registers()
	for i = 34, 122 do
		pcall(vim.fn.setreg, string.char(i), {})
	end
end

function M.open_scratch()
	vim.cmd("enew")

	local buf = vim.api.nvim_get_current_buf()
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].swapfile = false

	vim.api.nvim_buf_set_name(buf, "scratch-" .. os.date("%s"))
end

local function default_session_path()
	local cwd = vim.fn.getcwd()
	if cwd == "" then
		cwd = vim.uv.cwd() or "."
	end

	local basename = vim.fn.fnamemodify(cwd, ":t")
	if basename == "" then
		basename = "root"
	end

	local slug = basename:gsub("[^%w._-]", "_")
	local hash = vim.fn.sha256(cwd):sub(1, 12)

	return table.concat({ vim.fn.stdpath("state"), "sessions", slug .. "-" .. hash .. ".vim" }, "/")
end

function M.session_path(path)
	if path and path ~= "" then
		return vim.fn.fnamemodify(path, ":p")
	end

	return default_session_path()
end

local ignored_session_filetypes = {
	NvimTree = true,
}

local ignored_session_buftypes = {
	acwrite = true,
	nofile = true,
	prompt = true,
	quickfix = true,
}

local function is_session_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
		return false
	end

	local buftype = vim.bo[bufnr].buftype
	if ignored_session_buftypes[buftype] then
		return false
	end

	local filetype = vim.bo[bufnr].filetype
	if ignored_session_filetypes[filetype] then
		return false
	end

	local name = vim.api.nvim_buf_get_name(bufnr)
	return name ~= "" or buftype == "help" or buftype == "terminal"
end

function M.has_session_content()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if is_session_buffer(bufnr) then
			return true
		end
	end

	return false
end

function M.save_session(opts)
	opts = opts or {}
	if opts.skip_empty and not M.has_session_content() then
		if not opts.silent then
			vim.notify("Session not saved: no file buffers")
		end
		return nil
	end

	local path = M.session_path(opts.args)
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

	local previous_sessionoptions = vim.o.sessionoptions
	vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,terminal"
	local ok, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(path))
	vim.o.sessionoptions = previous_sessionoptions

	if not ok then
		vim.notify("Session save failed: " .. tostring(err), vim.log.levels.ERROR)
		return nil
	end

	if not opts.silent then
		vim.notify("Session saved: " .. path)
	end
	return path
end

function M.load_session(opts)
	opts = opts or {}
	local path = M.session_path(opts.args)
	if vim.fn.filereadable(path) ~= 1 then
		if not opts.silent and not opts.missing_ok then
			vim.notify("No session found: " .. path, vim.log.levels.WARN)
		end
		return false
	end

	local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(path))
	if not ok then
		vim.notify("Session load failed: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end

	if not M.has_session_content() then
		vim.g.auto_session_loaded = false
		if not opts.silent then
			vim.notify("Session skipped: no file buffers: " .. path, vim.log.levels.WARN)
		end
		return false
	end

	vim.g.auto_session_loaded = true
	if not opts.silent then
		vim.notify("Session loaded: " .. path)
	end
	return true
end

function M.quit_session(opts)
	M.save_session(opts)
	vim.cmd(opts.bang and "qa!" or "qa")
end

function M.setup()
	vim.api.nvim_create_user_command("WQ", function()
		vim.cmd("wq")
	end, {})

	vim.api.nvim_create_user_command("Wq", function()
		vim.cmd("wq")
	end, {})

	vim.api.nvim_create_user_command("W", function()
		vim.cmd("w")
	end, {})

	vim.api.nvim_create_user_command("Q", function()
		vim.cmd("q")
	end, {})

	vim.api.nvim_create_user_command("Bd", function()
		vim.cmd("bp | bd #")
	end, {})

	vim.api.nvim_create_user_command("WipeReg", M.wipe_registers, {})
	vim.api.nvim_create_user_command("Scratch", M.open_scratch, {})
	vim.api.nvim_create_user_command("SessionPath", function(opts)
		print(M.session_path(opts.args))
	end, { nargs = "?", complete = "file" })
	vim.api.nvim_create_user_command("SessionSave", M.save_session, { nargs = "?", complete = "file" })
	vim.api.nvim_create_user_command("SessionLoad", M.load_session, { nargs = "?", complete = "file" })
	vim.api.nvim_create_user_command("SessionQuit", M.quit_session, { bang = true, nargs = "?", complete = "file" })
end

return M
