return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
        enabled = false,
		build = "make tiktoken",
		opts = {

			window = {
				layout = "vertical", -- 'vertical' | 'horizontal'
				width = 60, -- Fixed width in columns
				height = 20, -- Fixed height in rows
				border = "rounded", -- 'single', 'double', 'rounded', 'solid'
				title = "🤖 AI Assistant",
				zindex = 100, -- Ensure window stays on top
			},

			headers = {
				user = "👤 You",
				assistant = "🤖 Copilot",
				tool = "🔧 Tool",
			},
            auto_insert_mode = true,
			separator = "━━",
			auto_fold = true, -- Automatically folds non-assistant messages
			model = "claude-sonnet-4",

			system_prompt = "请用中文回复所有问题。",
			vim.api.nvim_create_autocmd("BufEnter", {
				pattern = "copilot-*",
				callback = function()
					vim.opt_local.relativenumber = false
					vim.opt_local.number = false
					vim.opt_local.conceallevel = 0
				end,
			}),
		},
		keys = {
			-- 你可以在这里自定义快捷键
			{ "<leader>cc", ":CopilotChat<CR>", desc = "Open Copilot Chat" },
			{ "<leader>ce", ":CopilotChatExplain<CR>", desc = "Explain code" },
			{ "<leader>cf", ":CopilotChatFix<CR>", desc = "Fix code" },
		},
	},
}
