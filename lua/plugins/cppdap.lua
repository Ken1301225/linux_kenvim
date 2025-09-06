return {
	"mfussenegger/nvim-dap",
    dependencies = {
        {'theHamsta/nvim-dap-virtual-text',
            config = function (_,opts)
                require("nvim-dap-virtual-text").setup(opts)
            end
        },
        {
            "rcarriga/nvim-dap-ui",
            config = function (_,opts)
                require("dapui").setup(opts)
            end,
            dependencies = {"nvim-neotest/nvim-nio"},
            keys={
                {"<leader>du","<cmd>lua require('dapui').toggle()<CR>",desc = "Debug toggle ui"}
            }

        },
        {
            "mfussenegger/nvim-dap-python",
            config = function (_,opts)
                require("dap-python").setup("/home/ken/miniconda3/envs/ml/bin/python")
            end
        }
    },
	config = function()
		local dap = require("dap")
		dap.adapters.cppdbg = {
			id = "cppdbg",
			type = "executable",
			command = "D:\\cpptools\\cpptools-windows-x64\\extension\\debugAdapters\\bin\\OpenDebugAD7.exe",
			options = {
				detached = false,
			},
		}
		dap.configurations.cpp = {
			{
				name = "Launch file",
				type = "cppdbg",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopAtEntry = true,
                MIMode = "gdb",
                miDebuggerPath = "D:\\true_code\\mingwnew\\mingw64\\bin\\gdb.exe",
			},
			{
				name = "Attach to gdbserver :1234",
				type = "cppdbg",
				request = "launch",
				MIMode = "gdb",
				miDebuggerServerAddress = "localhost:1234",
				miDebuggerPath = "/usr/bin/gdb",
				cwd = "${workspaceFolder}",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
			},
		}
		setupCommands = {
			{
				text = "-enable-pretty-printing",
				description = "enable pretty printing",
				ignoreFailures = false,
			},
		}
		dap.configurations.c = dap.configurations.cpp
		dap.configurations.rust = dap.configurations.cpp
	end,
    keys ={
         {"<leader>db","<cmd>:DapToggleBreakpoint<CR>",desc = "Debug set breakpoint"},
         {"<leader>dn","<cmd>:DapNew<CR>",desc = "Debug start"},
         {"<leader>dc","<cmd>:DapContinue<CR>",desc = "Debug continue"},
         {"<leader>do","<cmd>:DapStepOver<CR>",desc = "Debug stepover"},
         {"<leader>di","<cmd><DapInto<CR>",desc = "Debug into"},
         {"<leader>dq","<cmd>:lua require('dap').terminate()<CR>",desc = "debug quit"}
    }
}
