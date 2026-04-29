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
    local ai_stats_cache

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
          local recent_files = theta.mru(0, vim.fn.getcwd(), 5)

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

    local function format_count(n)
      if n >= 1000000000 then
        return string.format("%.1fB", n / 1000000000)
      elseif n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
      elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
      end
      return tostring(n)
    end

    local function fetch_ai_stats()
      if ai_stats_cache then
        return ai_stats_cache
      end

      local stats = {}

      local function db_query(db, query)
        local ok, result = pcall(vim.fn.system, { "sqlite3", vim.fn.expand(db), query })
        if ok then
          return vim.trim(result)
        end
        return nil
      end

      local function db_count(db, query)
        local r = db_query(db, query)
        return r and tonumber(r) or 0
      end

      local week_ms = os.time() * 1000 - 7 * 86400 * 1000

      -- OpenCode
      local op_db = "~/.local/share/opencode/opencode.db"
      stats.opencode = {
        sessions = db_count(op_db, "SELECT COUNT(*) FROM session"),
        sessions_wk = db_count(op_db, "SELECT COUNT(*) FROM session WHERE time_created > " .. week_ms),
      }
      local op_tok = db_query(op_db, "SELECT COALESCE(SUM(json_extract(data,'$.tokens.input')),0)+COALESCE(SUM(json_extract(data,'$.tokens.output')),0)+COALESCE(SUM(json_extract(data,'$.tokens.cache.read')),0) FROM message WHERE json_extract(data,'$.role')='assistant'")
      stats.opencode.tokens = op_tok and math.floor(tonumber(op_tok) or 0) or 0
      local op_tok_wk = db_query(op_db, "SELECT COALESCE(SUM(json_extract(data,'$.tokens.input')),0)+COALESCE(SUM(json_extract(data,'$.tokens.output')),0)+COALESCE(SUM(json_extract(data,'$.tokens.cache.read')),0) FROM message WHERE json_extract(data,'$.role')='assistant' AND time_created > " .. week_ms)
      stats.opencode.tokens_wk = op_tok_wk and math.floor(tonumber(op_tok_wk) or 0) or 0
      local op_model = db_query(op_db, "SELECT json_extract(data,'$.modelID') FROM message WHERE json_extract(data,'$.role')='assistant' GROUP BY 1 ORDER BY COUNT(*) DESC LIMIT 1")
      stats.opencode.model = op_model or "?"

      -- Codex
      local cx_db = "~/.codex/state_5.sqlite"
      local cx = db_query(cx_db, "SELECT COUNT(*), COALESCE(SUM(tokens_used),0) FROM threads")
      local cx_threads, cx_tokens = 0, 0
      if cx then
        cx_threads = tonumber(cx:match("^(%d+)")) or 0
        cx_tokens = tonumber(cx:match("|(%d+)")) or 0
      end
      local cx_wk = db_query(cx_db, "SELECT COUNT(*), COALESCE(SUM(tokens_used),0) FROM threads WHERE created_at_ms > " .. week_ms)
      local cx_threads_wk, cx_tokens_wk = 0, 0
      if cx_wk then
        cx_threads_wk = tonumber(cx_wk:match("^(%d+)")) or 0
        cx_tokens_wk = tonumber(cx_wk:match("|(%d+)")) or 0
      end
      local cx_model = db_query(cx_db, "SELECT model FROM threads WHERE model != '' AND model != '?' GROUP BY model ORDER BY COUNT(*) DESC LIMIT 1")
      stats.codex = {
        sessions = cx_threads,
        sessions_wk = cx_threads_wk,
        tokens = cx_tokens,
        tokens_wk = cx_tokens_wk,
        model = cx_model or "?",
      }

      -- Claude
      local cl_history_path = vim.fn.expand("~/.claude/history.jsonl")
      local cl_sessions, cl_messages, cl_sessions_wk, cl_messages_wk = 0, 0, 0, 0
      if vim.fn.filereadable(cl_history_path) == 1 then
        local py_script = string.format([[
import json, sys
week_ms = %d
sessions = set()
count = 0
sessions_wk = set()
count_wk = 0
with open(sys.argv[1]) as f:
    for line in f:
        try:
            d = json.loads(line)
            sid = d.get('sessionId','')
            ts = d.get('timestamp',0)
            sessions.add(sid)
            count += 1
            if ts > week_ms:
                sessions_wk.add(sid)
                count_wk += 1
        except: pass
print(len(sessions), count, len(sessions_wk), count_wk)
]], week_ms)
        local result = vim.fn.system({ "python3", "-c", py_script, cl_history_path })
        local a, b, c, d = result:match("(%d+) (%d+) (%d+) (%d+)")
        cl_sessions = tonumber(a) or 0
        cl_messages = tonumber(b) or 0
        cl_sessions_wk = tonumber(c) or 0
        cl_messages_wk = tonumber(d) or 0
      end
      stats.claude = {
        sessions = cl_sessions,
        sessions_wk = cl_sessions_wk,
        messages = cl_messages,
        messages_wk = cl_messages_wk,
      }

      ai_stats_cache = stats
      return stats
    end

    local function bordered_ai_stats()
      return {
        type = "group",
        val = function()
          ai_stats_cache = nil
          local stats = fetch_ai_stats()
          local items = {}

          table.insert(items, { type = "text", val = "AI Usage (total / this week)", opts = { hl = "SpecialComment", position = "center" } })
          table.insert(items, { type = "padding", val = 1 })

          local function tool_line(name, n_sess, w_sess, n_col2, w_col2, col2_label, extra)
            return string.format("%-9s %s sess (+%s/wk)  |  %s %s (+%s/wk)  |  %s",
              name, format_count(n_sess), format_count(w_sess),
              format_count(n_col2), col2_label, format_count(w_col2), extra)
          end

          table.insert(items, { type = "text", val = tool_line("OpenCode", stats.opencode.sessions, stats.opencode.sessions_wk, stats.opencode.tokens, stats.opencode.tokens_wk, "tkn", "@" .. stats.opencode.model), opts = { hl = "Comment", position = "center" } })
          table.insert(items, { type = "text", val = tool_line("Codex", stats.codex.sessions, stats.codex.sessions_wk, stats.codex.tokens, stats.codex.tokens_wk, "tkn", "@" .. stats.codex.model), opts = { hl = "Comment", position = "center" } })
          table.insert(items, { type = "text", val = tool_line("Claude", stats.claude.sessions, stats.claude.sessions_wk, stats.claude.messages, stats.claude.messages_wk, "msgs", ""), opts = { hl = "Comment", position = "center" } })

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
      { type = "padding", val = 1 },
      theta.header,
      { type = "padding", val = 1 },
      bordered_ai_stats(),
      { type = "padding", val = 1 },
      bordered_recent_files(),
      { type = "padding", val = 1 },
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
