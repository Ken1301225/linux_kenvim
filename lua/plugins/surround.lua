return {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    init = function()
        vim.g.nvim_surround_no_mappings = true
    end,
    opts = {
        highlight = {
            duration = 200,
        },
        move_cursor = "sticky",
    },
    keys = {
        { "<leader>sa", "<Plug>(nvim-surround-normal)",          mode = "n", desc = "Surround add" },
        { "<leader>ss", "<Plug>(nvim-surround-normal-cur)",      mode = "n", desc = "Surround current line" },
        { "<leader>sA", "<Plug>(nvim-surround-normal-line)",     mode = "n", desc = "Surround add linewise" },
        { "<leader>sS", "<Plug>(nvim-surround-normal-cur-line)", mode = "n", desc = "Surround current line linewise" },
        { "<leader>sd", "<Plug>(nvim-surround-delete)",          mode = "n", desc = "Surround delete" },
        { "<leader>sr", "<Plug>(nvim-surround-change)",          mode = "n", desc = "Surround replace" },
        { "<leader>sR", "<Plug>(nvim-surround-change-line)",     mode = "n", desc = "Surround replace linewise" },
        { "<leader>sa", "<Plug>(nvim-surround-visual)",          mode = "x", desc = "Surround selection" },
        { "<leader>sA", "<Plug>(nvim-surround-visual-line)",     mode = "x", desc = "Surround selection linewise" },
    },
}
