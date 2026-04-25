return {
	"akinsho/toggleterm.nvim",
	enabled = true,
	version = "*",
	config = function()
		vim.opt.splitright = true

		require("toggleterm").setup({
			cmd = "zsh", -- 将默认终端修改为 zsh
			size = 60,
			open_mapping = [[<c-\>]],
			direction = "vertical", -- 默认终端使用垂直分割
			start_in_insert = true,
            shade_terminals = false,

		})

		local Terminal = require("toggleterm.terminal").Terminal

		local bash = Terminal:new({
			cmd = "bash",
			hidden = true,
			direction = "vertical",
		})

		-- 保留 python 终端 (可选)
		local python = Terminal:new({ cmd = "ipython", hidden = true })

		-- 提取 lazygit，建议设置为 float (悬浮窗口) 视觉效果更好
		local lazygit = Terminal:new({
			cmd = "lazygit",
			hidden = true,
			direction = "float", -- lazygit 推荐使用悬浮窗
			float_opts = {
				border = "curved",
			}
		})

		function _BASH_TOGGLE()
			bash:toggle()
		end

		function _PYTHON_TOGGLE()
			python:toggle()
		end

		function _LAZYGIT_TOGGLE()
			lazygit:toggle()
		end

		-- 绑定快捷键，删除了之前的 Windows powershell 快捷键
		vim.api.nvim_set_keymap("n", "<leader>tb", "<cmd>lua _BASH_TOGGLE()<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "<leader>tg", "<cmd>lua _LAZYGIT_TOGGLE()<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "<leader>tp", "<cmd>lua _PYTHON_TOGGLE()<CR>", { noremap = true, silent = true })

		function _G.set_terminal_keymaps()
			local opts = { buffer = 0 }
			vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
			vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
			vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
			vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
			vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
			vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
			vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
		end

		-- if you only want these mappings for toggle term use term://*toggleterm#* instead
		vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
	end,
}
