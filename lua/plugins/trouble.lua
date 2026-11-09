return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("trouble").setup({
      -- your settings here
      auto_open = false,      -- 有错误时自动打开
      auto_close = true,      -- 无错误时自动关闭
    })

    -- 快捷键
    vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Toggle diagnostics" })
  end,
}
