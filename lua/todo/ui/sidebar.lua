local util = require("todo.util")
local store = require("todo.store")
local hl = require("todo.ui.hl")

local M = {}

-- 上次渲染的任务行映射：task_lnums = {lnum,...}（0 基行号），id_at[lnum] = 任务id
local task_lnums, id_at = {}, {}

-- 构建展示项：{{type="date", date=...}, {type="task", task=...}, ...}（仅未完成，日期升序）
local function build_items()
  local by_date, order = {}, {}
  for _, t in ipairs(store.tasks) do
    if not t.done then
      if not by_date[t.date] then
        by_date[t.date] = {}
        order[#order + 1] = t.date
      end
      by_date[t.date][#by_date[t.date] + 1] = t
    end
  end
  table.sort(order)
  local items = {}
  for _, d in ipairs(order) do
    items[#items + 1] = { type = "date", date = d }
    for _, t in ipairs(by_date[d]) do
      items[#items + 1] = { type = "task", task = t }
    end
  end
  return items
end

function M.render(ctx)
  if not (ctx.side_win and vim.api.nvim_win_is_valid(ctx.side_win)) then return end
  local width = vim.api.nvim_win_get_width(ctx.side_win)
  local today = util.today()
  local items = build_items()
  local lines, spans = {}, {}
  task_lnums, id_at = {}, {}

  if #items == 0 then
    lines[1] = " 没有未完成的任务"
    spans[1] = { 0, 0, #lines[1], "TodoCalOtherMonth" }
  else
    for _, it in ipairs(items) do
      if it.type == "date" then
        local label = string.format(" %s %s", it.date, util.dow_names[util.weekday(it.date)])
        local group
        if it.date == today then
          group = "TodoCalToday"
        elseif it.date < today then
          group = "TodoCalPriHigh"
        else
          group = "TodoCalHeader"
        end
        lines[#lines + 1] = label
        spans[#spans + 1] = { #lines - 1, 0, #label, group }
      else
        local t = it.task
        local bullet = " ● "
        local marks = hl.pri_marks(t.priority)
        local title = util.truncate(t.title, width - util.strwidth(bullet) - util.strwidth(marks))
        local parts, byte = {}, 0
        local lnum = #lines
        local function add(text, group)
          parts[#parts + 1] = text
          if group then
            spans[#spans + 1] = { lnum, byte, byte + #text, group }
          end
          byte = byte + #text
        end
        add(bullet, hl.cat(t.category))
        add(title)
        add(marks, hl.pri_hl(t.priority))
        lines[#lines + 1] = table.concat(parts)
        task_lnums[#task_lnums + 1] = lnum
        id_at[lnum] = t.id
      end
    end
  end

  -- 选中恢复：按 id 找行；找不到回退到第一个任务
  local sel_lnum
  if ctx.state.side_sel_id then
    for _, ln in ipairs(task_lnums) do
      if id_at[ln] == ctx.state.side_sel_id then
        sel_lnum = ln
        break
      end
    end
  end
  if not sel_lnum and #task_lnums > 0 then
    sel_lnum = task_lnums[1]
    ctx.state.side_sel_id = id_at[sel_lnum]
  end
  if sel_lnum then
    spans[#spans + 1] = { sel_lnum, 0, #lines[sel_lnum + 1], "TodoCalCursor", 300 }
  end

  M._task_lnums = task_lnums
  M._id_at = id_at
  hl.apply(ctx.side_buf, lines, spans)
end

local function selected_task(ctx)
  local id = ctx.state.side_sel_id
  if id then
    return store.find(id)
  end
  return nil
end

local function move_sel(ctx, delta)
  local lnums = M._task_lnums or {}
  if #lnums == 0 then return end
  local i = 1
  for idx, ln in ipairs(lnums) do
    if M._id_at[ln] == ctx.state.side_sel_id then
      i = idx
      break
    end
  end
  i = math.max(1, math.min(#lnums, i + delta))
  ctx.state.side_sel_id = M._id_at[lnums[i]]
  ctx.refresh()
end

function M.attach(ctx)
  local map = function(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = ctx.side_buf, nowait = true, silent = true })
  end
  map("j", function() move_sel(ctx, 1) end)
  map("k", function() move_sel(ctx, -1) end)
  map("<CR>", function()
    local t = selected_task(ctx)
    if t then ctx.actions.jump_to_date(t.date) end
  end)
  map("a", function()
    local t = selected_task(ctx)
    ctx.actions.add(t and t.date or util.today())
  end)
  map("e", function() local t = selected_task(ctx); if t then ctx.actions.edit_task(t) end end)
  map("x", function() local t = selected_task(ctx); if t then ctx.actions.toggle_task(t) end end)
  map("d", function() local t = selected_task(ctx); if t then ctx.actions.remove_task(t) end end)
  map("m", function() local t = selected_task(ctx); if t then ctx.actions.move_task(t) end end)
  map("<Tab>", function() ctx.actions.focus_toggle() end)
  map("q", function() ctx.actions.close() end)
  map("<Esc>", function() ctx.actions.close() end)
end

return M
