local util = require("todo.util")
local store = require("todo.store")
local hl = require("todo.ui.hl")

local M = {}

-- 上次渲染的布局信息（快速通道用）：pos[date] = { [r] = {lnum, cstart, cend} }
local last = nil

local MAX_CELL_H = 7 -- 1 日期行 + 5 任务行 + 1 溢出行

-- 格高自适应：网格总行数 = 6*(1+cell_h)+1 <= win_h-2
local function cell_height(win_h)
  local hgt = math.floor((win_h - 3) / 6) - 1
  return math.max(3, math.min(MAX_CELL_H, hgt))
end

local function cell_width(win_w)
  return math.max(10, math.floor((win_w - 8) / 7))
end

-- 任务 -> 格内一行 segments（定显示宽 cw）
local function task_segs(t, cw)
  if t.done then
    local s = util.truncate(" ● " .. t.title, cw)
    return { { text = s, hl = "TodoCalDone" }, { text = string.rep(" ", cw - util.strwidth(s)) } }
  end
  local bullet = " ● "
  local marks = (t.cycle and util.cycle_mark or "") .. hl.pri_marks(t.priority)
  local title = util.truncate(t.title, cw - util.strwidth(bullet) - util.strwidth(marks))
  local segs = {
    { text = bullet, hl = hl.cat(t.category) },
    { text = title },
    { text = marks, hl = hl.pri_hl(t.priority) },
  }
  local used = util.strwidth(bullet) + util.strwidth(title) + util.strwidth(marks)
  segs[#segs + 1] = { text = string.rep(" ", cw - used) }
  return segs
end

-- 一个日期格的 cell_h 行 segments
local function cell_rows(date, cur_m, today, cw, cell_h, tasks)
  local _, m, d = util.split_date(date)
  local num = (d == 1) and string.format("%d月%d日", m, d) or tostring(d)
  local label = " " .. num
  local date_hl
  if date == today then
    date_hl = "TodoCalToday"
  elseif m ~= cur_m then
    date_hl = "TodoCalOtherMonth"
  end
  local rows = { { { text = label, hl = date_hl }, { text = string.rep(" ", cw - util.strwidth(label)) } } }

  local n_task_rows = cell_h - 2
  for i = 1, n_task_rows do
    local t = tasks[i]
    rows[#rows + 1] = t and task_segs(t, cw) or { { text = string.rep(" ", cw) } }
  end

  local extra = #tasks - n_task_rows
  if extra > 0 then
    local s = " +" .. extra
    rows[#rows + 1] = { { text = s, hl = "TodoCalOverflow" }, { text = string.rep(" ", cw - util.strwidth(s)) } }
  else
    rows[#rows + 1] = { { text = string.rep(" ", cw) } }
  end
  return rows
end

function M.render(ctx)
  local api = vim.api
  local win_w = api.nvim_win_get_width(ctx.win)
  local win_h = api.nvim_win_get_height(ctx.win)
  local cw = cell_width(win_w)
  local cell_h = cell_height(win_h)
  local y, m = util.split_date(ctx.state.month_cursor)
  local days = util.month_grid(y, m)
  local today = util.today()
  local cursor = ctx.state.month_cursor

  local lines, spans = {}, {}
  local pos = {}
  local function push_line(text, group)
    lines[#lines + 1] = text
    if group then
      spans[#spans + 1] = { #lines - 1, 0, #text, group }
    end
  end

  push_line(string.format(" %d 年 %d 月 ", y, m), "TodoCalTitle")

  -- 星期表头（前导 1 空格对齐格内容列：格内容列起点 = 1 + (i-1)*(cw+1)）
  local header = { " " }
  for i = 1, 7 do
    header[#header + 1] = util.fit(util.dow_names[i], cw + 1)
  end
  push_line(table.concat(header), "TodoCalHeader")

  local function border(l, mid, r)
    local parts = { l }
    for i = 1, 7 do
      parts[#parts + 1] = string.rep("─", cw)
      parts[#parts + 1] = (i < 7) and mid or r
    end
    return table.concat(parts)
  end

  -- 光标格在网格中的位置
  local cur_week, cur_col
  for i, dstr in ipairs(days) do
    if dstr == cursor then
      cur_week = math.floor((i - 1) / 7)
      cur_col = (i - 1) % 7 + 1
      break
    end
  end

  local task_map = store.by_date_map()
  for w = 0, 5 do
    if w == 0 then
      push_line(border("┌", "┬", "┐"), "TodoCalBorder")
    else
      push_line(border("├", "┼", "┤"), "TodoCalBorder")
    end
    local cells = {}
    for col = 1, 7 do
      local date = days[w * 7 + col]
      cells[col] = cell_rows(date, m, today, cw, cell_h, task_map[date] or {})
    end
    for r = 1, cell_h do
      local parts, byte = {}, 0
      local lnum = #lines
      local function add(text, group)
        parts[#parts + 1] = text
        if group then
          spans[#spans + 1] = { lnum, byte, byte + #text, group }
        end
        byte = byte + #text
      end
      for col = 1, 7 do
        add("│", "TodoCalBorder")
        local cstart = byte
        for _, seg in ipairs(cells[col][r]) do
          add(seg.text, seg.hl)
        end
        local cell_date = days[w * 7 + col]
        pos[cell_date] = pos[cell_date] or {}
        pos[cell_date][r] = { lnum = lnum, cstart = cstart, cend = byte }
        if w == cur_week and col == cur_col then
          spans[#spans + 1] = { lnum, cstart, byte, "TodoCalCursor", 300 }
        end
      end
      add("│", "TodoCalBorder")
      lines[#lines + 1] = table.concat(parts)
    end
  end
  push_line(border("└", "┴", "┘"), "TodoCalBorder")

  hl.apply(ctx.buf, lines, spans)
  last = { days = days, pos = pos }
end

-- 只移动光标高亮，不重写 buffer（同月内 hjkl 的快速通道）
function M.move_cursor(ctx, date)
  local api = vim.api
  if not (last and last.pos[date]) then
    ctx.refresh()
    return
  end
  local marks = api.nvim_buf_get_extmarks(ctx.buf, hl.NS, 0, -1, { details = true })
  for _, mk in ipairs(marks) do
    if mk[4].hl_group == "TodoCalCursor" then
      api.nvim_buf_del_extmark(ctx.buf, hl.NS, mk[1])
    end
  end
  for _, p in ipairs(last.pos[date]) do
    api.nvim_buf_set_extmark(ctx.buf, hl.NS, p.lnum, p.cstart, {
      end_col = p.cend,
      hl_group = "TodoCalCursor",
      priority = 300,
    })
  end
end

local function move_day(ctx, delta)
  local st = ctx.state
  local oy, om = util.split_date(st.month_cursor)
  st.month_cursor = util.add_days(st.month_cursor, delta)
  local ny, nm = util.split_date(st.month_cursor)
  if oy == ny and om == nm then
    M.move_cursor(ctx, st.month_cursor)
  else
    ctx.refresh()
  end
end

function M.attach(ctx)
  local st = ctx.state
  local map = function(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = ctx.buf, nowait = true, silent = true })
  end
  map("h", function() move_day(ctx, -1) end)
  map("l", function() move_day(ctx, 1) end)
  map("j", function() move_day(ctx, 7) end)
  map("k", function() move_day(ctx, -7) end)
  map("<Tab>", function() ctx.actions.focus_toggle() end)
  map("<", function() ctx.actions.shift_month(-1) end)
  map(">", function() ctx.actions.shift_month(1) end)
  map("t", function() st.month_cursor = util.today(); ctx.refresh() end)
  map("a", function() ctx.actions.add(st.month_cursor) end)
  map("e", function() ctx.actions.edit(st.month_cursor) end)
  map("<CR>", function() ctx.actions.edit(st.month_cursor) end)
  map("x", function() ctx.actions.toggle(st.month_cursor) end)
  map("d", function() ctx.actions.remove(st.month_cursor) end)
  map("m", function() ctx.actions.move(st.month_cursor) end)
  map("w", function() ctx.actions.show_week(st.month_cursor) end)
  map("M", function() end)
  map("q", function() ctx.actions.close() end)
  map("<Esc>", function() ctx.actions.close() end)
  M.render(ctx)
end

return M
