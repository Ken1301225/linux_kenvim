return{
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>b", group = "Buffers" },
      { "<leader>f", group = "Find" },
      { "<leader>l", group = "Language / LSP" },
      { "<leader>m", group = "DeepML" },
      { "<leader>r", group = "Run" },
      { "<leader>t", group = "Terminals / Tasks" },
      { "<leader>u", group = "UI / Toggles" },
      { "<leader>x", group = "Diagnostics" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
