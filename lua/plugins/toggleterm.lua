-- -- ~/.config/nvim/lua/plugins/toggleterm.lua
-- return {
-- 	"akinsho/toggleterm.nvim",
--     enabled = false,
-- 	version = "*",
-- 	config = function()
-- 		require("toggleterm").setup({
--             cmd = "pwsh.exe",
-- 			size = 63,
-- 			open_mapping = [[<c-\>]],
-- 			direction = "vertical", -- or "float" / "vertical"
-- 			start_in_insert = true,
-- 		})
--
-- 		local Terminal = require("toggleterm.terminal").Terminal
-- 		local python = Terminal:new({ cmd = "ipython", hidden = true })
--         local pwsh = Terminal:new({
--             cmd = "pwsh.exe",
--             hidden = true,
--         })
--         local wpwsh = Terminal:new({
--             cmd = "powershell.exe",
--             hidden = true,
--         })
--         local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })
-- 		function _PYTHON_TOGGLE()
-- 			python:toggle()
-- 		end
--
-- 		function _PWSH_TOGGLE()
-- 			pwsh:toggle()
-- 		end
-- 		function _WPWSH_TOGGLE()
-- 			wpwsh:toggle()
-- 		end
-- 		function _LAZYGIT_TOGGLE()
-- 			lazygit:toggle()
-- 		end
--
-- 		vim.api.nvim_set_keymap("n", "<leader>tP", "<cmd>lua _PWSH_TOGGLE()<CR>", { noremap = true, silent = true })
-- 		vim.api.nvim_set_keymap("n", "<leader>tw", "<cmd>lua _WPWSH_TOGGLE()<CR>", { noremap = true, silent = true })
-- 		vim.api.nvim_set_keymap("n", "<leader>tg", "<cmd>lua _LAZYGIT_TOGGLE()<CR>", { noremap = true, silent = true })
--
-- 		vim.api.nvim_set_keymap("n", "<leader>tp", "<cmd>lua _PYTHON_TOGGLE()<CR>", { noremap = true, silent = true })
-- 		function _G.set_terminal_keymaps()
-- 			local opts = { buffer = 0 }
-- 			vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
-- 			vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
-- 			vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
-- 			vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
-- 			vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
-- 			vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
-- 			vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
-- 		end
--
-- 		-- if you only want these mappings for toggle term use term://*toggleterm#* instead
-- 		vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
-- 	end,
-- }
return {
	"akinsho/toggleterm.nvim",
	enabled = true, -- 注意：原配置为 false，你需要改为 true 才能启用该插件
	version = "*",
	config = function()
		require("toggleterm").setup({
			cmd = "zsh", -- 将默认终端修改为 zsh
			size = 63,
			open_mapping = [[<c-\>]],
			direction = "vertical", -- 默认终端使用垂直分割
			start_in_insert = true,
		})

		local Terminal = require("toggleterm.terminal").Terminal
        
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

		function _PYTHON_TOGGLE()
			python:toggle()
		end

		function _LAZYGIT_TOGGLE()
			lazygit:toggle()
		end

		-- 绑定快捷键，删除了之前的 Windows powershell 快捷键
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
