return {
	"vague2k/vague.nvim",
	opts = {},
	config = function(_, opts)
		require("vague").setup(opts)
		vim.cmd("colorscheme tokyonight")
        vim.cmd("colorscheme vague")
	end,
}
