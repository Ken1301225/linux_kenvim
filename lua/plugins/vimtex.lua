return {
	"lervag/vimtex",
	lazy = false, -- we don't want to lazy load VimTex
	-- tag = "v2.15", -- uncomment to pin to a specific release
	init = function()
		-- VimTeX configuration goes here, e.g.
		vim.g.vimtex_view_method = "zathura"
        vim.g.vimtex_view_general_viewer = "zathura"
        vim.g.vimtex_view_general_options = "--fork"
		vim.g.vimtex_compiler_method = "latexmk"
		vim.g.vimtex_compiler_latexmk = {
			build_dir = "",
			callback = 1,
			executable = "latexmk",
			options = {
				"-xelatex", -- 强制使用 XeLaTeX
				"-file-line-error", -- 错误显示文件名与行号
				"-interaction=nonstopmode", -- 遇错不中断
				"-synctex=1", -- 启用 SyncTeX
                '-shell-escape',
			},
		}
	end,
}
