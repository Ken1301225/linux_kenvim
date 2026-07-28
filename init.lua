vim.g.python3_host_prog = require("config.conda").get_python_path()

require("config.basic")
require("config.keymap")
require("config.lazy")

require("todo").setup({
  categories = {
    nlp = { color = "#7aa2f7" },
    RL = { color = "#9ece6a" },
    course = { color = "#e0af68" },
    paper = { color = "#f7768e" },
  },
})
vim.keymap.set("n", "<leader>td", "<cmd>Todo<cr>", { desc = "Todo 日历" })
