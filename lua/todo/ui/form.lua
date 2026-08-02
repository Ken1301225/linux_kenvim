local util = require("todo.util")

local M = {}

-- 字段标签：inline 虚拟文本，用户无法删除（buffer 里只存值）
local LABELS = { "title:    ", "date:     ", "category: ", "priority: ", "done:     ", "repeat:   " }

local function split_lines(s)
  local out = {}
  for l in (s .. "\n"):gmatch("([^\n]*)\n") do
    out[#out + 1] = l
  end
  return out
end

-- 按行位置解析表单 -> task | nil, err
-- 行序：1 title, 2 date, 3 category, 4 priority, 5 done, 6 repeat, 7+ notes
local function parse_form(buf, cfg)
  local fl = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local function val(i)
    return vim.trim(fl[i] or "")
  end
  local title, date, category, priority, done, cycle = val(1), val(2), val(3), val(4), val(5), val(6)

  if title == "" then
    return nil, "title 不能为空"
  end
  if not util.is_valid_date(date) then
    return nil, "date 非法（须为 YYYY-MM-DD）: " .. date
  end
  if category == "" then
    category = nil
  elseif not cfg.categories[category] then
    return nil, "未知分类: " .. category .. "（可选: " .. table.concat(vim.tbl_keys(cfg.categories), ", ") .. "）"
  end
  if priority ~= "high" and priority ~= "medium" and priority ~= "low" then
    return nil, "priority 须为 high/medium/low"
  end
  if done ~= "true" and done ~= "false" then
    return nil, "done 须为 true/false"
  end
  cycle = util.normalize_cycle(cycle)
  if cycle == nil and val(6) ~= "" then
    return nil, "repeat 须为 day/week/month/Nd/Nw/Nm（如 3d、2w）或留空"
  end

  local notes_lines = {}
  for i = 7, #fl do
    notes_lines[#notes_lines + 1] = fl[i]
  end
  while #notes_lines > 0 and notes_lines[#notes_lines] == "" do
    notes_lines[#notes_lines] = nil
  end

  return {
    title = title,
    date = date,
    category = category,
    priority = priority,
    done = (done == "true"),
    cycle = cycle,
    notes = table.concat(notes_lines, "\n"),
  }
end

-- open(task, cfg, on_save)
function M.open(task, cfg, on_save)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  -- buffer 只放值
  local lines = {
    task.title,
    task.date,
    task.category or "",
    task.priority,
    tostring(task.done),
    task.cycle or "",
  }
  if task.notes and task.notes ~= "" then
    for _, l in ipairs(split_lines(task.notes)) do
      lines[#lines + 1] = l
    end
  else
    lines[#lines + 1] = ""
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- 标签用 inline 虚拟文本展示（删不掉）
  local label_ns = vim.api.nvim_create_namespace("todo_cal_form_label")
  for i = 1, 6 do
    vim.api.nvim_buf_set_extmark(buf, label_ns, i - 1, 0, {
      virt_text = { { LABELS[i], "TodoCalOtherMonth" } },
      virt_text_pos = "inline",
      right_gravity = false,
    })
  end
  vim.api.nvim_buf_set_extmark(buf, label_ns, 5, 0, {
    virt_lines = { { { "notes:", "TodoCalOtherMonth" } } },
  })

  local width = 56
  local height = math.min(#lines + 1, math.floor(vim.o.lines * 0.6))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    style = "minimal",
    title = " 任务（<C-s> 保存，q 取消） ",
    title_pos = "center",
    zindex = 50,
  })
  vim.wo[win].wrap = false

  local err_ns = vim.api.nvim_create_namespace("todo_cal_form")
  local function show_error(msg)
    vim.api.nvim_buf_clear_namespace(buf, err_ns, 0, -1)
    local last = #vim.api.nvim_buf_get_lines(buf, 0, -1, false) - 1
    vim.api.nvim_buf_set_extmark(buf, err_ns, last, 0, {
      virt_lines = { { { "⚠ " .. msg, "TodoCalFormError" } } },
    })
  end

  local function try_save()
    local t, err = parse_form(buf, cfg)
    if not t then
      show_error(err)
      return
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    on_save(t)
  end

  vim.keymap.set({ "n", "i" }, "<C-s>", function()
    vim.cmd.stopinsert()
    try_save()
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<CR>", try_save, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })
  vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = buf, callback = try_save })

  -- 打开即进入 insert（光标在 title 值处）
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  vim.cmd.startinsert()
end

return M
