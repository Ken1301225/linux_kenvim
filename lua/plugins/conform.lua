local function buffer_autoformat_disabled(bufnr)
    local disabled = vim.b[bufnr].disable_autoformat
    if disabled ~= nil then return disabled end
    local filetype = vim.bo[bufnr].filetype
    return filetype == "tex" or filetype == "plaintex"
end

return {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            python = function(bufnr)
                local formatter = vim.b[bufnr].python_formatter or vim.g.python_formatter
                if formatter == "black" then
                    return { "isort", "black" }
                end
                return { "ruff_organize_imports", "ruff_format" }
            end,
            c = { "clang_format" },
            cpp = { "clang_format" },
            tex = { "latexindent" },
            plaintex = { "latexindent" },
        },
        format_on_save = function(bufnr)
            if vim.g.disable_autoformat or buffer_autoformat_disabled(bufnr) then
                return
            end
            return { timeout_ms = 1000 }
        end,
    },
    keys = {
        { "<leader>lf", function() require("conform").format({ async = true }) end, desc = "Format" },
        { "<leader>ua", "<cmd>FormatToggle<CR>", desc = "Toggle buffer autoformat" },
    },
    config = function(_, opts)
        require("conform").setup(opts)
        vim.api.nvim_create_user_command("FormatToggle", function(args)
            local scope = args.bang and vim.g or vim.b
            if args.bang then
                scope.disable_autoformat = not scope.disable_autoformat
            else
                scope.disable_autoformat = not buffer_autoformat_disabled(0)
            end
            local label = args.bang and "Global" or "Buffer"
            vim.notify(label .. " autoformat " .. (scope.disable_autoformat and "disabled" or "enabled"))
        end, { bang = true, desc = "Toggle autoformat (bang: all buffers)" })
    end,
}
