return {
	"nvim-treesitter/nvim-treesitter",
	event = "BufReadPost",
	-- main = "nvim-treesitter.configs",
    build = ':TSUpdate',
    opts = {
        ensure_installed = {"latex","yaml","lua", "toml", "python","c","cpp","html","bash","vim","regex","markdown","markdown_inline"},
        highlight = { enable = true },
    }
}
