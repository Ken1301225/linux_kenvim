return {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "isort", "black" },
            c = { "clang_format" },
            cpp = { "clang_format" },
        },
        format_on_save = function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
            end
            return { timeout_ms = 3000 }
        end,
    },
    keys = {
        { "<leader>lf", function() require("conform").format({ async = true }) end, desc = "Format" },
    },
}
