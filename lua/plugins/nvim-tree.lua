return {
    "nvim-tree/nvim-tree.lua",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    opts = {
        view = {
            width = 35
        },
        actions = {
            open_file = {
                quit_on_open = true
            }
        }
    },
    keys = {
        {"<leader>uf", "<cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree"},
        {"<leader>u>", "<cmd>NvimTreeResize +5<CR>", desc = "NvimTree wider"},
        {"<leader>u<", "<cmd>NvimTreeResize -5<CR>", desc = "NvimTree narrower"}
    }
}
