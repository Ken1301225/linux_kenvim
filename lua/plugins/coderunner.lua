return {
	"CRAG666/code_runner.nvim",
	opts = {
		filetype = {
			java = {
				"cd $dir &&",
				"javac $fileName &&",
				"java $fileNameWithoutExt",
			},
			python = "python3 -u",
			typescript = "deno run",
			rust = {
				"cd $dir &&",
				"rustc $fileName &&",
				"$dir/$fileNameWithoutExt",
			},
			c = function(...)
				c_base = {
					"cd $dir &&",
					"gcc $fileName -o",
					"/tmp/$fileNameWithoutExt",
				}
				local c_exec = {
					"&& /tmp/$fileNameWithoutExt &&",
					"rm /tmp/$fileNameWithoutExt",
				}
				vim.ui.input({ prompt = "Add more args:" }, function(input)
					c_base[4] = input
					vim.print(vim.tbl_extend("force", c_base, c_exec))
					require("code_runner.commands").run_from_fn(vim.list_extend(c_base, c_exec))
				end)
			end,
			cpp = function(...)
				cpp_base = {
					"cd $dir &&",
					"g++ $fileName -o",
					"/tmp/$fileNameWithoutExt",
				}
				local cpp_exec = {
					"&& /tmp/$fileNameWithoutExt &&",
					"rm /tmp/$fileNameWithoutExt",
				}
				vim.ui.input({ prompt = "Add more args:" }, function(input)
					cpp_base[4] = input
					vim.print(vim.tbl_extend("force", cpp_base, cpp_exec))
					require("code_runner.commands").run_from_fn(vim.list_extend(cpp_base, cpp_exec))
				end)
			end,
		},
	},
	config = function(_, opts)
		require("code_runner").setup({
			opts,
		})
		vim.keymap.set("n", "<leader>rr", function()
			vim.cmd("w") -- 保存
			vim.cmd("RunCode") -- 运行
		end, { silent = true })
	end,
}
