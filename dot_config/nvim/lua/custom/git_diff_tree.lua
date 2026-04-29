local M = {}

M.state = {
	enabled = false,
	root = nil,
	files = {},
	dirs = {},
	regular_open_dirs = nil,
	watcher = nil,
	refresh_timer = nil,
}

local function normalize_path(path)
	return vim.fs.normalize(path):gsub("/$", "")
end

local function path_relative_to(path, root)
	path = normalize_path(path)
	root = normalize_path(root)

	if path == root then
		return ""
	end

	local prefix = root .. "/"
	if path:sub(1, #prefix) ~= prefix then
		return nil
	end

	return path:sub(#prefix + 1)
end

local function git_systemlist(cmd)
	local output = vim.fn.systemlist(cmd)

	if vim.v.shell_error ~= 0 then
		vim.notify(table.concat(output, "\n"), vim.log.levels.ERROR)
		return nil
	end

	return output
end

local function git_system(cmd, opts)
	opts = opts or {}

	local result = vim.system(cmd, { text = opts.text ~= false }):wait()
	if result.code ~= 0 then
		local message = result.stderr ~= "" and result.stderr or result.stdout
		vim.notify(message, vim.log.levels.ERROR)
		return nil
	end

	return result.stdout or ""
end

local function close_handle(handle)
	if handle and not handle:is_closing() then
		handle:stop()
		handle:close()
	end
end

local function stop_refresh_timer()
	close_handle(M.state.refresh_timer)
	M.state.refresh_timer = nil
end

local function stop_watcher()
	close_handle(M.state.watcher)
	M.state.watcher = nil
	stop_refresh_timer()
end

local function parse_git_status_z(output)
	local files = {}
	local seen = {}
	local items = {}

	for item in output:gmatch("([^%z]+)") do
		table.insert(items, item)
	end

	local index = 1
	while index <= #items do
		local item = items[index]
		local status = item:sub(1, 2)
		local path = item:sub(4)

		if path ~= "" and not seen[path] then
			seen[path] = true
			table.insert(files, path)
		end

		if status:match("[RC]") then
			index = index + 1
		end

		index = index + 1
	end

	return files
end

local function git_status_files(root)
	local output = git_system({
		"git",
		"-C",
		root,
		"status",
		"--porcelain=v1",
		"-z",
		"--untracked-files=all",
	}, { text = false })

	if not output then
		return nil
	end

	return parse_git_status_z(output)
end

local function set_tree_filter(files, root)
	local state = M.state
	state.enabled = true
	state.root = normalize_path(root)
	state.files = {}
	state.dirs = { [""] = true }

	for _, file in ipairs(files) do
		if file ~= "" then
			file = normalize_path(file)
			state.files[file] = true

			local dir = vim.fs.dirname(file)
			while dir and dir ~= "." and dir ~= "" do
				state.dirs[dir] = true
				dir = vim.fs.dirname(dir)
			end
		end
	end
end

local function rebuild_tree(api, root)
	if root then
		local ok, core = pcall(require, "nvim-tree.core")
		if ok then
			core.init(root)
		end
	end

	api.tree.open({ path = root })
end

local function reload_git_tree(opts)
	opts = opts or {}

	local ok, api = pcall(require, "nvim-tree.api")
	if not ok then
		return
	end

	local current_win = vim.api.nvim_get_current_win()

	rebuild_tree(api, M.state.root)
	api.tree.expand_all()

	if opts.focus then
		api.tree.focus()
	elseif vim.api.nvim_win_is_valid(current_win) then
		vim.api.nvim_set_current_win(current_win)
	end
end

local function collect_open_dirs(nodes, open_dirs)
	for _, node in ipairs(nodes or {}) do
		if node.nodes then
			if node.open then
				open_dirs[normalize_path(node.absolute_path)] = true
			end

			collect_open_dirs(node.nodes, open_dirs)
		end
	end
end

local function save_regular_tree_state()
	if M.state.enabled then
		return
	end

	local ok, api = pcall(require, "nvim-tree.api")
	if not ok then
		return
	end

	local open_dirs = {}
	collect_open_dirs(api.tree.get_nodes() or {}, open_dirs)
	M.state.regular_open_dirs = open_dirs
end

local function restore_regular_tree_state(api, root)
	rebuild_tree(api, root)

	local open_dirs = M.state.regular_open_dirs
	if open_dirs then
		api.tree.collapse_all()
		api.tree.expand_all(nil, {
			expand_until = function(_, node)
				return open_dirs[normalize_path(node.absolute_path)] == true
			end,
		})
	end

	api.tree.focus()
end

function M.refresh(opts)
	opts = opts or {}

	local state = M.state
	if not state.enabled or not state.root then
		return
	end

	local files = git_status_files(state.root)
	if not files then
		return
	end

	set_tree_filter(files, state.root)
	reload_git_tree({ focus = opts.focus })

	if not opts.silent then
		vim.notify(("Showing %d changed file(s) in nvim-tree"):format(#files), vim.log.levels.INFO)
	end
end

function M.schedule_refresh()
	local state = M.state
	if not state.enabled or not state.root then
		return
	end

	local uv = vim.uv or vim.loop
	if not uv or not uv.new_timer then
		M.refresh({ silent = true })
		return
	end

	if not state.refresh_timer or state.refresh_timer:is_closing() then
		state.refresh_timer = uv.new_timer()
	end

	state.refresh_timer:stop()
	state.refresh_timer:start(
		750,
		0,
		vim.schedule_wrap(function()
			M.refresh({ silent = true })
		end)
	)
end

local function start_watcher(root)
	stop_watcher()

	local uv = vim.uv or vim.loop
	if not uv or not uv.new_fs_event then
		return
	end

	local watcher = uv.new_fs_event()
	if not watcher then
		return
	end

	local function on_change(err)
		if err or not M.state.enabled then
			return
		end

		M.schedule_refresh()
	end

	local ok = pcall(function()
		watcher:start(root, { recursive = true }, on_change)
	end)

	if not ok then
		ok = pcall(function()
			watcher:start(root, {}, on_change)
		end)
	end

	if ok then
		M.state.watcher = watcher
	else
		close_handle(watcher)
	end
end

function M.should_filter_path(path)
	local state = M.state
	if not state.enabled or not state.root then
		return false
	end

	local relpath = path_relative_to(path, state.root)
	if not relpath then
		return true
	end

	if relpath == "" or state.files[relpath] or state.dirs[relpath] then
		return false
	end

	return true
end

function M.clear(opts)
	opts = opts or {}

	stop_watcher()

	local state = M.state
	local root = state.root
	state.enabled = false
	state.root = nil
	state.files = {}
	state.dirs = {}

	local ok, api = pcall(require, "nvim-tree.api")
	if ok then
		if opts.restore ~= false then
			restore_regular_tree_state(api, root)
		else
			api.tree.reload()
		end
	end

	state.regular_open_dirs = nil

	vim.notify("Showing all files in nvim-tree", vim.log.levels.INFO)
end

function M.open(opts)
	opts = opts or {}

	if opts.bang then
		M.clear()
		return
	end

	local cwd = vim.fn.getcwd()
	local root_output = git_systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })
	if not root_output or not root_output[1] then
		return
	end

	local root = normalize_path(root_output[1])
	local files = git_status_files(root)
	if not files then
		return
	end

	if #files == 0 then
		vim.notify("No changed files", vim.log.levels.INFO)
		return
	end

	save_regular_tree_state()
	set_tree_filter(files, root)
	start_watcher(root)

	local ok = pcall(require, "nvim-tree.api")
	if not ok then
		vim.notify("nvim-tree is not available", vim.log.levels.ERROR)
		return
	end

	reload_git_tree({ focus = true })

	vim.notify(("Showing %d changed file(s) in nvim-tree"):format(#files), vim.log.levels.INFO)
end

function M.toggle()
	if M.state.enabled then
		M.clear()
	else
		M.open()
	end
end

function M.setup()
	vim.api.nvim_create_user_command("GitDiffTree", M.open, { bang = true, force = true })
	vim.api.nvim_create_user_command("GitDiffTreeToggle", M.toggle, { force = true })
	vim.api.nvim_create_user_command("GitDiffTreeRefresh", function()
		M.refresh()
	end, { force = true })
	vim.api.nvim_create_user_command("GitDiffTreeClear", M.clear, { force = true })
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("git-diff-tree", { clear = true }),
		callback = stop_watcher,
	})
end

return M
