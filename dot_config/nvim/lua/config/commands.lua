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
end

return M
