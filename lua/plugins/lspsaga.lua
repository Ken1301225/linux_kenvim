return {
    "nvimdev/lspsaga.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = "Lspsaga",
    opts = {
        symbol_in_winbar = {
            enable = true
        },
        lightbulb = {
            enable = false,
        },
        finder = {
            keys = {
                toggle_or_open = "<CR>"
            }
        }
    },
    keys = {
        { "<leader>lr", ":Lspsaga rename<CR>", desc = "Rename symbol" },
        { "<leader>lc", ":Lspsaga code_action<CR>", desc = "Code actions" },
        { "<leader>ld", ":Lspsaga goto_definition<CR>", desc = "Go to definition" },
        { "<leader>lD", ":Lspsaga peek_definition<CR>", desc = "Peek definition" },
        { "<leader>lh", ":Lspsaga hover_doc<CR>", desc = "Hover documentation" },
        { "<leader>lR", ":Lspsaga finder<CR>", desc = "Find references / definitions" },
        { "<leader>lo", ":Lspsaga outline<CR>", desc = "Symbol outline" },
        { "<leader>le", ":Lspsaga show_line_diagnostics<CR>", desc = "Line diagnostics" },
        { "<leader>li", ":Lspsaga incoming_calls<CR>", desc = "Incoming calls" },
        { "<leader>ln", ":Lspsaga diagnostic_jump_next<CR>", desc = "Next diagnostic" },
        { "<leader>lp", ":Lspsaga diagnostic_jump_prev<CR>", desc = "Previous diagnostic" },
    }
}
