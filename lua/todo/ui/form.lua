local util = require("todo.util")

local M = {}

local FIELD_NAMES = { title = true, date = true, category = true, priority = true, done = true }

local function split_lines(s)
  local out = {}
  for l in (s .. "\n"):gmatch("([^\n]*)\n") do
    out[#out + 1] = l
  end
  return out
end

-- 解析表单 buffer 内容 -> task | nil, err
local function parse_form(buf, cfg)
  local fields, notes_lines, in_notes = {}, {}, false
  for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if in_notes then
      notes_lines[#notes_lines + 1] = l
    else
      local k, v = l:match("^(%w+):%s?(.*)$")
      if k == "notes" then
        in_notes = true
      elseif k and FIELD_NAMES[k] then
        fields[k] = vim.trim(v)
      else
        return nil, "无法解析的行（字段须为 title/date/category/priority/done/notes）: " .. l
      end
    end
  end
  if fields.title == nil or fields.title == "" then
    return nil, "title 不能为空"
  end
  if not fields.date or not util.is_valid_date(fields.date) then
    return nil, "date 非法（须为 YYYY-MM-DD）: " .. tostring(fields.date)
  end
  local category = fields.category
  if category == "" or category == nil then
    category = nil
  elseif not cfg.categories[category] then
    return nil, "未知分类: " .. category .. "（可选: " .. table.concat(vim.tbl_keys(cfg.categories), ", ") .. "）"
  end
  local pri = fields.priority
  if pri ~= "high" and pri ~= "medium" and pri ~= "low" then
    return nil, "priority 须为 high/medium/low"
  end
  local done = fields.done
  if done ~= "true" and done ~= "false" then
    return nil, "done 须为 true/false"
  end
  while #notes_lines > 0 and notes_lines[#notes_lines] == "" do
    notes_lines[#notes_lines] = nil
  end
  return {
    title = fields.title,
    date = fields.date,
    category = category,
    priority = pri,
    done = (done == "true"),
    notes = table.concat(notes_lines, "\n"),
  }
end

-- open(task, cfg, on_save)
function M.open(task, cfg, on_save)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local lines = {
    "title: " .. task.title,
    "date: " .. task.date,
    "category: " .. (task.category or ""),
    "priority: " .. task.priority,
    "done: " .. tostring(task.done),
    "notes:",
  }
  if task.notes and task.notes ~= "" then
    for _, l in ipairs(split_lines(task.notes)) do
      lines[#lines + 1] = l
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = 56
  local height = math.min(#lines, math.floor(vim.o.lines * 0.6))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    style = "minimal",
    title = " 任务（<CR> 保存，q 取消） ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false
  vim.api.nvim_win_set_cursor(win, { 1, 7 })

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

  vim.keymap.set("n", "<CR>", try_save, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })
  vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = buf, callback = try_save })
end

return M
