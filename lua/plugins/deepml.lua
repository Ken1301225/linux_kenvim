return {
  dir = "/home/ken/deepml.nvim",
  cmd = "DeepML",
  keys = {
    { "<leader>om", "<cmd>DeepML<CR>", desc = "Open DeepML" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("deepml").setup({
      preferred_environment = "numpy",
      python = { executable = "python3" },
      browser = {
        executable = "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe",
        args = {},
      },
    })
  end,
}
