local function executable(path)
	return path and path ~= "" and vim.fn.executable(path) == 1
end

local function first_executable(paths)
	for _, path in ipairs(paths) do
		if executable(path) then
			return path
		end
	end
end

local function mason_path(...)
	return vim.fs.joinpath(vim.fn.stdpath("data"), "mason", ...)
end

local function python_with_debugpy()
	local candidates = {
		require("config.conda").get_python_path(),
		mason_path("packages", "debugpy", "venv", "bin", "python"),
		"/home/ken/miniconda3/bin/python3",
		vim.fn.exepath("python3"),
	}

	for _, python in ipairs(candidates) do
		if executable(python) then
			local check = vim.system({ python, "-c", "import debugpy" }):wait()
			if check.code == 0 then
				return python
			end
		end
	end

	return vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or "python3"
end

local function input_program()
	return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
end

local function source_language(path)
	local ext = vim.fn.fnamemodify(path, ":e"):lower()
	if ext == "c" then
		return "c"
	end
	if ext == "cc" or ext == "cpp" or ext == "cxx" or ext == "c++" then
		return "cpp"
	end
	return vim.bo.filetype == "c" and "c" or "cpp"
end

local function compiler_for(language)
	if language == "c" then
		return first_executable({
			vim.fn.exepath("gcc"),
			vim.fn.exepath("clang"),
		})
	end

	return first_executable({
		vim.fn.exepath("g++"),
		vim.fn.exepath("clang++"),
	})
end

local function normalize_flags(flags)
	if type(flags) == "table" then
		return vim.deepcopy(flags)
	end
	if type(flags) == "string" and flags ~= "" then
		return vim.split(flags, " ", { trimempty = true })
	end
	return {}
end

local function build_current_file()
	local source = vim.fn.expand("%:p")
	if source == "" then
		error("No current file to build for DAP")
	end

	if vim.bo.modified then
		vim.cmd.write()
	end

	local language = source_language(source)
	local compiler = compiler_for(language)
	if not compiler then
		error(("No %s compiler found. Install %s."):format(language, language == "c" and "gcc or clang" or "g++ or clang++"))
	end

	local build_dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "dap-build")
	vim.fn.mkdir(build_dir, "p")

	local output = vim.fs.joinpath(
		build_dir,
		("%s-%s"):format(vim.fn.fnamemodify(source, ":t:r"), vim.fn.sha256(source):sub(1, 8))
	)

	local cmd = { compiler, "-g", "-O0" }
	local extra_flags = normalize_flags(language == "c" and vim.g.cppdap_c_flags or vim.g.cppdap_cpp_flags)
	vim.list_extend(cmd, extra_flags)
	vim.list_extend(cmd, { source, "-o", output })

	local result = vim.system(cmd, { text = true }):wait()
	if result.code ~= 0 then
		local message = table.concat({
			"Build failed:",
			table.concat(cmd, " "),
			result.stderr or result.stdout or "",
		}, "\n")
		vim.notify(message, vim.log.levels.ERROR, { title = "DAP build" })
		error(message)
	end

	return output
end

local function input_args()
	local args = vim.fn.input("Arguments: ")
	return vim.split(args, " ", { trimempty = true })
end

local function configured_args()
	return normalize_flags(vim.g.cppdap_args)
end

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"nvim-neotest/nvim-nio",
		{
			"theHamsta/nvim-dap-virtual-text",
			config = function(_, opts)
				require("nvim-dap-virtual-text").setup(opts)
			end,
		},
		{
			"rcarriga/nvim-dap-ui",
			config = function()
				require("dapui").setup({
					icons = {
						expanded = "▾",
						collapsed = "▸",
						current_frame = "▸",
					},
					mappings = {
						expand = { "<CR>", "<2-LeftMouse>" },
						open = "o",
						remove = "d",
						edit = "e",
						repl = "r",
						toggle = "t",
					},
					expand_lines = vim.fn.has("nvim-0.7") == 1,
					layouts = {
						{
							elements = {
								{ id = "scopes", size = 0.62 },
								{ id = "watches", size = 0.18 },
								{ id = "stacks", size = 0.14 },
								{ id = "breakpoints", size = 0.06 },
							},
							position = "left",
							size = 48,
						},
						{
							elements = {
								{ id = "repl", size = 0.55 },
								{ id = "console", size = 0.45 },
							},
							position = "bottom",
							size = 12,
						},
					},
					floating = {
						border = "single",
						mappings = {
							close = { "q", "<Esc>" },
						},
					},
				})
			end,
			keys = {
				{
					"<leader>du",
					function()
						require("dapui").toggle()
					end,
					desc = "Debug toggle ui",
				},
				{
					"<leader>de",
					function()
						require("dapui").eval()
					end,
					desc = "Debug eval word/selection",
				},
				{
					"<leader>dh",
					function()
						require("dapui").float_element("scopes", { enter = true })
					end,
					desc = "Debug variables float",
				},
			},
		},
		{
			"mfussenegger/nvim-dap-python",
			config = function()
				require("dap-python").setup(python_with_debugpy())
			end,
		},
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		local lldb_dap = first_executable({
			vim.fn.exepath("lldb-dap"),
			vim.fn.exepath("codelldb"),
			mason_path("bin", "codelldb"),
		})
		if lldb_dap then
			dap.adapters.lldb = {
				type = "executable",
				command = lldb_dap,
				name = "lldb",
			}

			dap.configurations.cpp = {
				{
					name = "Build and launch current file (lldb)",
					type = "lldb",
					request = "launch",
					program = build_current_file,
					cwd = "${workspaceFolder}",
					args = configured_args,
					stopOnEntry = false,
				},
				{
					name = "Launch executable (lldb)",
					type = "lldb",
					request = "launch",
					program = input_program,
					cwd = "${workspaceFolder}",
					args = input_args,
					stopOnEntry = false,
				},
				{
					name = "Attach process (lldb)",
					type = "lldb",
					request = "attach",
					pid = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
				},
			}
		end

		local open_debug_ad7 = first_executable({
			vim.fn.exepath("OpenDebugAD7"),
			mason_path("bin", "OpenDebugAD7"),
			mason_path("packages", "cpptools", "extension", "debugAdapters", "bin", "OpenDebugAD7"),
		})
		if open_debug_ad7 then
			dap.configurations.cpp = dap.configurations.cpp or {}
			dap.adapters.cppdbg = {
				id = "cppdbg",
				type = "executable",
				command = open_debug_ad7,
				options = {
					detached = false,
				},
			}

			vim.list_extend(dap.configurations.cpp, {
				{
					name = "Build and launch current file (gdb/cpptools)",
					type = "cppdbg",
					request = "launch",
					program = build_current_file,
					cwd = "${workspaceFolder}",
					args = configured_args,
					stopAtEntry = false,
					MIMode = "gdb",
					miDebuggerPath = vim.fn.exepath("gdb") ~= "" and vim.fn.exepath("gdb") or "/usr/bin/gdb",
					setupCommands = {
						{
							text = "-enable-pretty-printing",
							description = "enable pretty printing",
							ignoreFailures = true,
						},
					},
				},
				{
					name = "Launch executable (gdb/cpptools)",
					type = "cppdbg",
					request = "launch",
					program = input_program,
					cwd = "${workspaceFolder}",
					args = input_args,
					stopAtEntry = false,
					MIMode = "gdb",
					miDebuggerPath = vim.fn.exepath("gdb") ~= "" and vim.fn.exepath("gdb") or "/usr/bin/gdb",
					setupCommands = {
						{
							text = "-enable-pretty-printing",
							description = "enable pretty printing",
							ignoreFailures = true,
						},
					},
				},
				{
					name = "Attach gdbserver :1234 (cpptools)",
					type = "cppdbg",
					request = "launch",
					program = input_program,
					cwd = "${workspaceFolder}",
					MIMode = "gdb",
					miDebuggerPath = vim.fn.exepath("gdb") ~= "" and vim.fn.exepath("gdb") or "/usr/bin/gdb",
					miDebuggerServerAddress = "localhost:1234",
				},
			})
		end

		dap.configurations.c = dap.configurations.cpp
		dap.configurations.rust = dap.configurations.cpp

		vim.api.nvim_create_user_command("DapCheckAdapters", function()
			local lines = {
				"lldb-dap: " .. (lldb_dap or "not found"),
				"OpenDebugAD7/cpptools: " .. (open_debug_ad7 or "not found"),
				"debugpy python: " .. python_with_debugpy(),
			}
			vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "DAP adapters" })
		end, { desc = "Show configured debug adapter paths" })
	end,
	keys = {
		{
			"<leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Debug set breakpoint",
		},
		{
			"<leader>dn",
			function()
				require("dap").continue()
			end,
			desc = "Debug start/continue",
		},
		{
			"<leader>dc",
			function()
				require("dap").continue()
			end,
			desc = "Debug continue",
		},
		{
			"<leader>do",
			function()
				require("dap").step_over()
			end,
			desc = "Debug step over",
		},
		{
			"<leader>di",
			function()
				require("dap").step_into()
			end,
			desc = "Debug step into",
		},
		{
			"<leader>dO",
			function()
				require("dap").step_out()
			end,
			desc = "Debug step out",
		},
		{
			"<leader>dr",
			function()
				require("dap").repl.toggle()
			end,
			desc = "Debug toggle repl",
		},
		{
			"<leader>dq",
			function()
				require("dap").terminate()
			end,
			desc = "Debug quit",
		},
	},
}
