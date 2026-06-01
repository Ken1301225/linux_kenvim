local M = {}

M.conda_home = vim.env.CONDA_PREFIX and vim.fn.fnamemodify(vim.env.CONDA_PREFIX, ":h") or "/home/ken/miniconda3"

function M._python_path_for(env_name)
	if env_name == "base" then
		return vim.fs.joinpath(M.conda_home, "bin", "python3")
	end
	return vim.fs.joinpath(M.conda_home, "envs", env_name, "bin", "python")
end

function M.detect()
	local prefix = vim.env.CONDA_PREFIX
	if prefix and prefix ~= "" then
		M.current_python_path = prefix .. "/bin/python"
		M.current_env_name = vim.env.CONDA_DEFAULT_ENV or "base"
	else
		M.current_python_path = M._python_path_for("base")
		M.current_env_name = "base"
	end
	if vim.fn.executable(M.current_python_path) == 0 then
		M.current_python_path = vim.fn.exepath("python3")
		M.current_env_name = "system"
	end
end

function M.get_python_path()
	if not M.current_python_path then
		M.detect()
	end
	return M.current_python_path
end

function M.switch(env_name)
	if not env_name or env_name == "" then
		vim.notify("Usage: :CondaSwitch <env_name>", vim.log.levels.WARN)
		return false
	end

	local python_path = M._python_path_for(env_name)
	if vim.fn.executable(python_path) == 0 then
		vim.notify("Conda environment not found: " .. env_name, vim.log.levels.ERROR)
		return false
	end

	M.current_env_name = env_name
	M.current_python_path = python_path

	vim.g.python3_host_prog = python_path

	local pyright = vim.lsp.config.pyright
	if pyright then
		if not pyright.settings then
			pyright.settings = {}
		end
		if not pyright.settings.python then
			pyright.settings.python = {}
		end
		pyright.settings.python.pythonPath = python_path
	end

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[bufnr].filetype == "python" then
			local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "pyright" })
			if #clients > 0 then
				vim.lsp.restart({ name = "pyright", buf = bufnr })
			end
		end
	end

	pcall(function()
		require("dap-python").setup(python_path)
	end)

	vim.notify("Switched to conda env: " .. env_name, vim.log.levels.INFO)
	return true
end

function M.list_envs(prefix)
	local envs = {}
	if not prefix or vim.startswith("base", prefix) then
		table.insert(envs, "base")
	end

	local envs_dir = vim.fs.joinpath(M.conda_home, "envs")
	local handle = vim.loop.fs_scandir(envs_dir)
	if handle then
		while true do
			local name, typ = vim.loop.fs_scandir_next(handle)
			if not name then
				break
			end
			if typ == "directory" and (not prefix or vim.startswith(name, prefix)) then
				table.insert(envs, name)
			end
		end
	end

	table.sort(envs, function(a, b)
		if a == "base" then
			return true
		end
		if b == "base" then
			return false
		end
		return a < b
	end)
	return envs
end

vim.api.nvim_create_user_command("CondaSwitch", function(opts)
	M.switch(opts.args)
end, {
	nargs = 1,
	complete = function(arg_lead)
		return M.list_envs(arg_lead)
	end,
	desc = "Switch conda environment for Python tools (LSP, DAP, runner)",
})

return M
