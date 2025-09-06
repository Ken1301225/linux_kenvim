return {
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- 自定义 Header（可修改为 ASCII 艺术字）
    dashboard.section.header.val = {
"██╗  ██╗███████╗███╗   ██╗██╗   ██╗██╗███╗   ███╗",
"██║ ██╔╝██╔════╝████╗  ██║██║   ██║██║████╗ ████║",
"█████╔╝ █████╗  ██╔██╗ ██║██║   ██║██║██╔████╔██║",
"██╔═██╗ ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
"██║  ██╗███████╗██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
"╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
    }
    local add = vim.fn.stdpath("config")
    -- 自定义菜单按钮
    dashboard.section.buttons.val = {
      dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
      dashboard.button("r", "󱚈  Recent files", ":Telescope oldfiles<CR>"),
      dashboard.button("n", "  New file", ":ene <BAR> startinsert <CR>"),
      dashboard.button("u", "󰒲  Lazy", ":Lazy<CR> "),
      dashboard.button("m", "󱘖  Mason", ":Mason<CR>"),
      dashboard.button("q", "󰩈  Quit Neovim", ":qa<CR>"),
      dashboard.button("c", "  Configration", ":NvimTreeOpen ~/.config/nvim/<CR>")
    }

    -- 页脚信息
    dashboard.section.footer.val = function()
      return "⚡Kenvim keep going!"
    end

    alpha.setup(dashboard.config)
  end,
}
