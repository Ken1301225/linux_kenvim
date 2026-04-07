return {
  "goolord/alpha-nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "nvim-lua/plenary.nvim",
  },
  lazy = false,
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")
    local theta = require("alpha.themes.theta")
    local recent_files_width = 44

    local function open_tree_for_alpha()
      vim.schedule(function()
        local alpha_buf = vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(alpha_buf) or vim.bo[alpha_buf].filetype ~= "alpha" then
          return
        end

        local ok, api = pcall(require, "nvim-tree.api")
        if not ok then
          return
        end

        local alpha_win = vim.api.nvim_get_current_win()
        local cwd = vim.fn.getcwd()

        if api.tree.is_visible() then
          api.tree.change_root(cwd)
        else
          api.tree.open({ path = cwd })
        end

        if vim.api.nvim_win_is_valid(alpha_win) then
          vim.api.nvim_set_current_win(alpha_win)
        end
      end)
    end

    local function is_empty_placeholder_buffer(bufnr)
      if vim.api.nvim_buf_get_name(bufnr) ~= "" or vim.bo[bufnr].modified then
        return false
      end

      if vim.api.nvim_buf_line_count(bufnr) ~= 1 then
        return false
      end

      return vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == ""
    end

    local function has_normal_buffers()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr)
          and vim.bo[bufnr].buflisted
          and vim.bo[bufnr].buftype == ""
          and vim.bo[bufnr].filetype ~= "alpha"
          and vim.bo[bufnr].filetype ~= "NvimTree"
          and not is_empty_placeholder_buffer(bufnr)
        then
          return true
        end
      end

      return false
    end

    local reopening_alpha = false

    local function pad_display(text, width)
      local padding = math.max(width - vim.fn.strdisplaywidth(text), 0)
      return text .. string.rep(" ", padding)
    end

    local function shift_highlights(hl, offset)
      local shifted = {}

      for _, item in ipairs(hl or {}) do
        table.insert(shifted, { item[1], item[2] + offset, item[3] + offset })
      end

      return shifted
    end

    local function bordered_recent_files()
      return {
        type = "group",
        val = function()
          local items = {}
          local top_border = "┌" .. string.rep("─", recent_files_width + 2) .. "┐"
          local separator = "├" .. string.rep("─", recent_files_width + 2) .. "┤"
          local bottom_border = "└" .. string.rep("─", recent_files_width + 2) .. "┘"
          local recent_files = theta.mru(0, vim.fn.getcwd(), 8)

          table.insert(items, { type = "text", val = top_border, opts = { hl = "SpecialComment", position = "center" } })
          table.insert(items, {
            type = "text",
            val = "│ " .. pad_display("Recent files", recent_files_width) .. " │",
            opts = { hl = "SpecialComment", position = "center" },
          })
          table.insert(items, { type = "text", val = separator, opts = { hl = "SpecialComment", position = "center" } })

          if #recent_files.val == 0 then
            table.insert(items, {
              type = "text",
              val = "│ " .. pad_display("No recent files", recent_files_width) .. " │",
              opts = { hl = "Comment", position = "center" },
            })
          else
            for index, button in ipairs(recent_files.val) do
              local prefix = string.format("│ %d. ", index)
              local suffix = " │"
              local padded = pad_display(button.val, recent_files_width + 2 - vim.fn.strdisplaywidth(prefix))

              button.val = prefix .. padded .. suffix
              button.opts.cursor = #prefix + 1
              button.opts.shortcut = nil
              button.opts.hl_shortcut = nil
              button.opts.hl = shift_highlights(button.opts.hl, #prefix)

              table.insert(items, button)
            end
          end

          table.insert(items, { type = "text", val = bottom_border, opts = { hl = "SpecialComment", position = "center" } })

          return items
        end,
      }
    end

    theta.header.val = {
      "██╗  ██╗███████╗███╗   ██╗██╗   ██╗██╗███╗   ███╗",
      "██║ ██╔╝██╔════╝████╗  ██║██║   ██║██║████╗ ████║",
      "█████╔╝ █████╗  ██╔██╗ ██║██║   ██║██║██╔████╔██║",
      "██╔═██╗ ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
      "██║  ██╗███████╗██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
      "╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
    }

    theta.buttons.val = {
      { type = "text", val = "Quick links", opts = { hl = "SpecialComment", position = "center" } },
      { type = "padding", val = 1 },
      dashboard.button("f", "  Find file", "<cmd>Telescope find_files<CR>"),
      dashboard.button("n", "  New file", "<cmd>ene <bar> startinsert<CR>"),
      dashboard.button("u", "󰒲  Lazy", "<cmd>Lazy<CR>"),
      dashboard.button("m", "󱘖  Mason", "<cmd>Mason<CR>"),
      dashboard.button("c", "  Configuration", "<cmd>NvimTreeOpen ~/.config/nvim/<CR>"),
      dashboard.button("q", "󰩈  Quit Neovim", "<cmd>qa<CR>"),
    }

    theta.config.layout = {
      { type = "padding", val = 2 },
      theta.header,
      { type = "padding", val = 2 },
      bordered_recent_files(),
      { type = "padding", val = 2 },
      theta.buttons,
      { type = "padding", val = 1 },
      {
        type = "text",
        val = "⚡Kenvim keep going!",
        opts = {
          hl = "Number",
          position = "center",
        },
      },
    }

    alpha.setup(theta.config)

    local alpha_group = vim.api.nvim_create_augroup("kenvim_alpha_homepage", { clear = true })

    vim.api.nvim_create_autocmd("User", {
      group = alpha_group,
      pattern = "AlphaReady",
      callback = open_tree_for_alpha,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
      group = alpha_group,
      callback = function()
        if reopening_alpha then
          return
        end

        vim.schedule(function()
          if reopening_alpha or has_normal_buffers() then
            return
          end

          reopening_alpha = true

          if vim.bo.filetype == "alpha" then
            open_tree_for_alpha()
          else
            vim.cmd("Alpha")
          end

          vim.schedule(function()
            reopening_alpha = false
          end)
        end)
      end,
    })
  end,
}
