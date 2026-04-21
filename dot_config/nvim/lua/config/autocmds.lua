local M = {}

function M.setup()
	local augroup = vim.api.nvim_create_augroup
	local autocmd = vim.api.nvim_create_autocmd
	local commands = require("config.commands")

	vim.o.autoread = true
	local autoread_group = augroup("autoread", { clear = true })
	local uv = vim.uv
	M._fs_watchers = M._fs_watchers or {}

	if M._autoread_scan_timer and not M._autoread_scan_timer:is_closing() then
		M._autoread_scan_timer:stop()
		M._autoread_scan_timer:close()
		M._autoread_scan_timer = nil
	end

	local function stop_watch(bufnr)
		local entry = M._fs_watchers[bufnr]
		if not entry then
			return
		end

		local watcher = entry.handle or entry
		if watcher and not watcher:is_closing() then
			watcher:stop()
			watcher:close()
		end

		M._fs_watchers[bufnr] = nil
	end

	local function maybe_checktime(bufnr)
		if vim.fn.getcmdwintype() ~= "" then
			return
		end

		if vim.api.nvim_get_mode().mode:sub(1, 1) == "c" then
			return
		end

		if bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
			if vim.bo[bufnr].modified then
				return
			end

			vim.cmd(("silent! checktime %d"):format(bufnr))
			vim.api.nvim_buf_call(bufnr, function()
				vim.cmd("silent! checktime")
			end)
			return
		end

		vim.cmd("silent! checktime")
	end

	local function stat_mtime(path)
		if not uv or not uv.fs_stat then
			return nil
		end

		local st = uv.fs_stat(path)
		if not st or not st.mtime then
			return nil
		end

		local sec = st.mtime.sec or 0
		local nsec = st.mtime.nsec or 0
		return ("%d:%d"):format(sec, nsec)
	end

	local function start_watch(bufnr)
		stop_watch(bufnr)

		if not uv or not uv.new_fs_event or not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		if vim.bo[bufnr].buftype ~= "" then
			return
		end

		local path = vim.api.nvim_buf_get_name(bufnr)
		if path == "" then
			return
		end

		local dir = vim.fn.fnamemodify(path, ":h")
		local target = vim.fn.fnamemodify(path, ":t")
		if dir == "" or target == "" then
			return
		end

		local watcher = uv.new_fs_event()
		if not watcher then
			return
		end

		local ok = pcall(function()
			watcher:start(dir, {}, vim.schedule_wrap(function(err, filename)
				if err then
					return
				end

				if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
					stop_watch(bufnr)
					return
				end

				local matches_target = false
				if not filename then
					matches_target = true
				elseif filename == target or filename == path then
					matches_target = true
				elseif type(filename) == "string" and filename:sub(-#target) == target then
					matches_target = true
				end

				if not matches_target then
					return
				end

				maybe_checktime(bufnr)
				vim.defer_fn(function()
					maybe_checktime(bufnr)
				end, 150)
				vim.defer_fn(function()
					maybe_checktime(bufnr)
				end, 700)
			end))
		end)

		if ok then
			M._fs_watchers[bufnr] = {
				handle = watcher,
				dir = dir,
				target = target,
				path = path,
				mtime = stat_mtime(path),
			}
		else
			if not watcher:is_closing() then
				watcher:close()
			end
		end
	end

	local function scan_watches()
		for bufnr, entry in pairs(M._fs_watchers) do
			if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
				stop_watch(bufnr)
			else
				local current_path = vim.api.nvim_buf_get_name(bufnr)
				if current_path == "" or vim.bo[bufnr].buftype ~= "" then
					stop_watch(bufnr)
				elseif current_path ~= entry.path then
					start_watch(bufnr)
				else
					local mtime = stat_mtime(entry.path)
					if mtime and entry.mtime and mtime ~= entry.mtime then
						entry.mtime = mtime
						maybe_checktime(bufnr)
					elseif mtime and not entry.mtime then
						entry.mtime = mtime
					end
				end
			end
		end
	end

	if uv and uv.new_timer then
		M._autoread_scan_timer = uv.new_timer()
		if M._autoread_scan_timer then
			M._autoread_scan_timer:start(3000, 3000, vim.schedule_wrap(scan_watches))
		end
	end

	autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermLeave", "TermClose" }, {
		group = autoread_group,
		callback = function()
			maybe_checktime()
		end,
	})

	autocmd({ "BufReadPost", "BufFilePost", "BufWritePost" }, {
		group = autoread_group,
		callback = function(args)
			start_watch(args.buf)
		end,
	})

	autocmd({ "BufUnload", "BufWipeout", "BufDelete" }, {
		group = autoread_group,
		callback = function(args)
			stop_watch(args.buf)
		end,
	})

	autocmd("VimEnter", {
		group = autoread_group,
		callback = function()
			for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
					start_watch(bufnr)
				end
			end
		end,
	})

	autocmd("VimLeavePre", {
		group = autoread_group,
		callback = function()
			for bufnr, _ in pairs(M._fs_watchers) do
				stop_watch(bufnr)
			end
			if M._autoread_scan_timer and not M._autoread_scan_timer:is_closing() then
				M._autoread_scan_timer:stop()
				M._autoread_scan_timer:close()
				M._autoread_scan_timer = nil
			end
		end,
	})

	autocmd("VimEnter", {
		group = augroup("wipereg", { clear = true }),
		callback = commands.wipe_registers,
	})

	local filetypes = augroup("SetFileTypes", { clear = true })

	autocmd({ "BufNewFile", "BufRead" }, {
		group = filetypes,
		pattern = { "*.tsx", "*.jsx" },
		callback = function()
			vim.bo.filetype = "typescriptreact"
		end,
	})

	autocmd({ "BufNewFile", "BufRead" }, {
		group = filetypes,
		pattern = "*.ejs",
		callback = function()
			vim.bo.filetype = "jst"
		end,
	})

	autocmd({ "BufNewFile", "BufRead" }, {
		group = filetypes,
		pattern = "*.sql",
		callback = function()
			vim.bo.filetype = "sql"
		end,
	})

	autocmd("FileType", {
		group = filetypes,
		pattern = "sql",
		callback = function()
			vim.bo.commentstring = "--%s"
		end,
	})


	autocmd("FileType", {
		group = augroup("nvim-tree", { clear = true }),
		pattern = "fzf",
		callback = function(args)
			autocmd("BufLeave", {
				buffer = args.buf,
				callback = function()
					local ok, api = pcall(require, "nvim-tree.api")

					if ok then
						api.tree.close()
					end
				end,
			})
		end,
	})
end

return M
