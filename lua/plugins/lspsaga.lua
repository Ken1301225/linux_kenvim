return {
    "nvimdev/lspsaga.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = "Lspsaga",
    opts = {
        symbol_in_winbar = {
            enable = true
        },
        finder = {
            keys = {
                toggle_or_open = "<CR>"
            }
        }
    },
    keys = {
        { "<leader>lr", ":Lspsaga rename<CR>" },
        { "<leader>lc", ":Lspsaga code_action<CR>" },
        { "<leader>ld", ":Lspsaga goto_definition<CR>" },
        { "<leader>lD", ":Lspsaga peek_definition<CR>" },
        { "<leader>lh", ":Lspsaga hover_doc<CR>" },
        { "<leader>lR", ":Lspsaga finder<CR>" },
        { "<leader>lo", ":Lspsaga outline<CR>" },
        { "<leader>le", ":Lspsaga show_line_diagnostics<CR>" },
        { "<leader>li", ":Lspsaga incoming_calls<CR>" },
        { "<leader>ln", ":Lspsaga diagnostic_jump_next<CR>" },
        { "<leader>lp", ":Lspsaga diagnostic_jump_prev<CR>" },
    }
}
