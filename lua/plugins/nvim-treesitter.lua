return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local treesitter = require("nvim-treesitter")
        treesitter.setup({})
        treesitter.install({
            "latex", "yaml", "lua", "toml", "python", "c", "cpp", "html",
            "bash", "vim", "regex", "markdown", "markdown_inline",
        })
        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
            callback = function(args)
                local filetype = vim.bo[args.buf].filetype
                if vim.tbl_contains({ "tex", "plaintex", "latex", "context" }, filetype) then
                    return
                end
                if vim.bo[args.buf].buftype == "" then
                    -- Filetypes without an installed parser keep their usual syntax.
                    pcall(vim.treesitter.start, args.buf)
                end
            end,
        })
    end,
}
