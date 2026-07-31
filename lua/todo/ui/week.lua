local util = require("todo.util")
local store = require("todo.store")
local hl = require("todo.ui.hl")

local M = {}

-- 上次渲染的位置信息（快速通道用）：pos[col][task_index] = { {lnum, cstart, cend}, ... }
local last = nil

local function col_width(win_w)
  return math.max(10, math.floor((win_w - 6) / 7)) -- 6 条列间竖线，无外框
end

-- 一列任务 -> 定高 max_rows 的行 segments 数组
local function col_rows(tasks, cw, max_rows)
  local rows = {}
  local shown = 0
  for i, t in ipairs(tasks) do
    if #rows + 2 > max_rows then break end
    local bullet = " ● "
    local line1
    if t.done then
      local s = util.truncate(bullet .. t.title, cw)
      line1 = { { text = s, hl = "TodoCalDone" }, { text = string.rep(" ", cw - util.strwidth(s)) } }
    else
      local cyc = t.cycle and util.cycle_mark or ""
      local title = util.truncate(t.title, cw - util.strwidth(bullet) - util.strwidth(cyc))
      line1 = {
        { text = bullet, hl = hl.cat(t.category) },
        { text = title },
        { text = cyc },
        { text = string.rep(" ", cw - util.strwidth(bullet) - util.strwidth(title) - util.strwidth(cyc)) },
      }
    end
    local marks = hl.pri_marks(t.priority)
    local meta = util.truncate("   " .. (t.category or "-"), cw - util.strwidth(marks))
    local line2 = {
      { text = meta, hl = "TodoCalOtherMonth" },
      { text = marks, hl = hl.pri_hl(t.priority) },
      { text = string.rep(" ", cw - util.strwidth(meta) - util.strwidth(marks)) },
    }
    rows[#rows + 1] = line1
    rows[#rows + 1] = line2
    shown = i
  end
  local extra = #tasks - shown
  if extra > 0 and #rows < max_rows then
    local s = " +" .. extra
    rows[#rows + 1] = { { text = s, hl = "TodoCalOverflow" }, { text = string.rep(" ", cw - util.strwidth(s)) } }
  end
  while #rows < max_rows do
    rows[#rows + 1] = { { text = string.rep(" ", cw) } }
  end
  return rows
end

function M.render(ctx)
  local api = vim.api
  local win_w = api.nvim_win_get_width(ctx.win)
  local win_h = api.nvim_win_get_height(ctx.win)
  local cw = col_width(win_w)
  local max_rows = win_h - 2 -- 1 列标题 + 1 分隔线
  local dates = util.week_dates(ctx.state.week_base)
  local today = util.today()
  local sel = ctx.state.week_sel

  local lines, spans = {}, {}
  local pos = {}
  local function push_line(text, group)
    lines[#lines + 1] = text
    if group then
      spans[#spans + 1] = { #lines - 1, 0, #text, group }
    end
  end

  -- 列标题行
  do
    local parts, byte = {}, 0
    local lnum = #lines
    local function add(text, group)
      parts[#parts + 1] = text
      if group then
        spans[#spans + 1] = { lnum, byte, byte + #text, group }
      end
      byte = byte + #text
    end
    for i = 1, 7 do
      if i > 1 then add("│", "TodoCalBorder") end
      local _, _, dd = util.split_date(dates[i])
      local label = string.format(" %s %02d", util.dow_names[i], dd)
      add(label, (dates[i] == today) and "TodoCalToday" or "TodoCalHeader")
      add(string.rep(" ", cw - util.strwidth(label)))
    end
    lines[#lines + 1] = table.concat(parts)
  end

  -- 分隔线
  local sep = {}
  for i = 1, 7 do
    sep[#sep + 1] = string.rep("─", cw)
    if i < 7 then sep[#sep + 1] = "┼" end
  end
  push_line(table.concat(sep), "TodoCalBorder")

  -- 各列内容
  local cols = {}
  local task_map = store.by_date_map()
  for i = 1, 7 do
    cols[i] = col_rows(task_map[dates[i]] or {}, cw, max_rows)
  end
  for r = 1, max_rows do
    local parts, byte = {}, 0
    local lnum = #lines
    local function add(text, group)
      parts[#parts + 1] = text
      if group then
        spans[#spans + 1] = { lnum, byte, byte + #text, group }
      end
      byte = byte + #text
    end
    for i = 1, 7 do
      if i > 1 then add("│", "TodoCalBorder") end
      local cstart = byte
      for _, seg in ipairs(cols[i][r]) do
        add(seg.text, seg.hl)
      end
      pos[i] = pos[i] or {}
      local ti = math.ceil(r / 2)
      pos[i][ti] = pos[i][ti] or {}
      table.insert(pos[i][ti], { lnum = lnum, cstart = cstart, cend = byte })
      if i == sel.col and (r == sel.row * 2 - 1 or r == sel.row * 2) then
        spans[#spans + 1] = { lnum, cstart, byte, "TodoCalCursor", 300 }
      end
    end
    lines[#lines + 1] = table.concat(parts)
  end

  hl.apply(ctx.buf, lines, spans)
  last = { pos = pos }
end

-- 只移动选中高亮，不重写 buffer（hjkl 的快速通道）
function M.move_cursor(ctx)
  local api = vim.api
  local sel = ctx.state.week_sel
  if not (last and last.pos[sel.col] and last.pos[sel.col][sel.row]) then
    ctx.refresh()
    return
  end
  local marks = api.nvim_buf_get_extmarks(ctx.buf, hl.NS, 0, -1, { details = true })
  for _, mk in ipairs(marks) do
    if mk[4].hl_group == "TodoCalCursor" then
      api.nvim_buf_del_extmark(ctx.buf, hl.NS, mk[1])
    end
  end
  for _, p in ipairs(last.pos[sel.col][sel.row]) do
    api.nvim_buf_set_extmark(ctx.buf, hl.NS, p.lnum, p.cstart, {
      end_col = p.cend,
      hl_group = "TodoCalCursor",
      priority = 300,
    })
  end
end

local function selected_task(ctx)
  local dates = util.week_dates(ctx.state.week_base)
  local tasks = store.by_date(dates[ctx.state.week_sel.col])
  return tasks[math.min(ctx.state.week_sel.row, #tasks)]
end

local function clamp(ctx)
  local st = ctx.state
  st.week_sel.col = math.max(1, math.min(7, st.week_sel.col))
  local dates = util.week_dates(st.week_base)
  local n = #store.by_date(dates[st.week_sel.col])
  if n == 0 then
    st.week_sel.row = 1
  else
    st.week_sel.row = math.max(1, math.min(st.week_sel.row, n))
  end
end

function M.attach(ctx)
  local st = ctx.state
  local map = function(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = ctx.buf, nowait = true, silent = true })
  end
  map("h", function() st.week_sel.col = st.week_sel.col - 1; clamp(ctx); M.move_cursor(ctx) end)
  map("l", function() st.week_sel.col = st.week_sel.col + 1; clamp(ctx); M.move_cursor(ctx) end)
  map("j", function() st.week_sel.row = st.week_sel.row + 1; clamp(ctx); M.move_cursor(ctx) end)
  map("k", function() st.week_sel.row = st.week_sel.row - 1; clamp(ctx); M.move_cursor(ctx) end)
  map("<Tab>", function() ctx.actions.focus_toggle() end)
  map("<", function() ctx.actions.shift_week(-1) end)
  map(">", function() ctx.actions.shift_week(1) end)
  map("t", function()
    st.week_base = util.today()
    st.week_sel = { col = util.weekday(util.today()), row = 1 }
    ctx.refresh()
  end)
  map("a", function()
    local dates = util.week_dates(st.week_base)
    ctx.actions.add(dates[st.week_sel.col])
  end)
  map("e", function() local t = selected_task(ctx); if t then ctx.actions.edit_task(t) end end)
  map("<CR>", function() local t = selected_task(ctx); if t then ctx.actions.edit_task(t) end end)
  map("x", function() local t = selected_task(ctx); if t then ctx.actions.toggle_task(t) end end)
  map("d", function() local t = selected_task(ctx); if t then ctx.actions.remove_task(t) end end)
  map("m", function() local t = selected_task(ctx); if t then ctx.actions.move_task(t) end end)
  map("w", function() end)
  map("M", function()
    local dates = util.week_dates(st.week_base)
    ctx.actions.show_month(dates[st.week_sel.col])
  end)
  map("q", function() ctx.actions.close() end)
  map("<Esc>", function() ctx.actions.close() end)
  M.render(ctx)
end

return M
