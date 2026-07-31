package.path = "./lua/?.lua;./lua/?/init.lua;./tests/?.lua;" .. package.path
vim.o.columns = 200
vim.o.lines = 60

local h = require("todo.helper")
local form = require("todo.ui.form")

local cfg = { categories = { nlp = { color = "#7aa2f7" } } }

local function open_form(task)
  local saved = nil
  form.open(task, cfg, function(t) saved = t end)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  return buf, win, function() return saved end
end

local function press(buf, mode, lhs)
  lhs = lhs:lower()
  for _, mp in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
    if mp.lhs:lower() == lhs then mp.callback() return true end
  end
  return false
end

local function all_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

-- 1. 表单 buffer 只含值，不含标签文字（标签删不掉）
local buf, _, get = open_form({ title = "", date = "2026-07-15", category = nil,
  priority = "medium", done = false, notes = "" })
local lines = all_lines(buf)
h.eq(lines[1], "", "第 1 行是纯 title 值（无标签）")
h.eq(lines[2], "2026-07-15", "第 2 行是纯 date 值")
h.eq(lines[4], "medium", "第 4 行是纯 priority 值")
local has_label_text = false
for _, l in ipairs(lines) do
  if l:find("title:") or l:find("date:") then has_label_text = true end
end
h.eq(has_label_text, false, "buffer 中不存在标签文字")

-- 2. 标签以 inline 虚拟文本存在
local label_found = false
for _, ns_id in pairs(vim.api.nvim_get_namespaces()) do
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns_id, 0, -1, { details = true })) do
    local vt = m[4].virt_text
    if vt and vt[1] and vt[1][1] and vt[1][1]:find("title:") and m[4].virt_text_pos == "inline" then
      label_found = true
    end
  end
end
h.eq(label_found, true, "title 标签为 inline 虚拟文本")

-- 3. 打开即 insert 模式（-l 脚本同步执行，看不到模式切换；用无头子进程验证）
local snippet = [[
package.path = './lua/?.lua;./lua/?/init.lua;' .. package.path
vim.defer_fn(function()
  local form = require('todo.ui.form')
  form.open({ title = '', date = '2026-07-15', category = nil, priority = 'medium', done = false, notes = '' },
    { categories = {} }, function() end)
  vim.defer_fn(function()
    print('mode: ' .. vim.api.nvim_get_mode().mode)
    vim.cmd('qa!')
  end, 100)
end, 50)
]]
local out = vim.fn.system({ "nvim", "--clean", "--headless", "+lua " .. snippet })
h.eq(out:find("mode: i") ~= nil, true, "打开即 insert 模式（headless 验证）")

-- 4. insert 模式有 <C-s> 保存映射；按 <C-s> 保存成功
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "新任务" })
vim.api.nvim_buf_set_lines(buf, 2, 3, false, { "nlp" })
h.eq(press(buf, "i", "<C-s>"), true, "insert 模式 <C-s> 存在")
h.eq(get() and get().title, "新任务", "<C-s> 保存 title")
h.eq(get() and get().category, "nlp", "<C-s> 保存 category")

-- 5. 备注多行往返
local buf2, _, get2 = open_form({ title = "t", date = "2026-07-15", category = nil,
  priority = "medium", done = false, notes = "第一行\n第二行" })
local l2 = all_lines(buf2)
h.eq(l2[6], "第一行", "备注第 1 行")
h.eq(l2[7], "第二行", "备注第 2 行")
press(buf2, "n", "<CR>")
h.eq(get2() and get2().notes, "第一行\n第二行", "备注往返")

-- 6. 校验失败不保存不关闭
local buf3, win3, get3 = open_form({ title = "x", date = "2026-13-99", category = nil,
  priority = "medium", done = false, notes = "" })
press(buf3, "n", "<CR>")
h.eq(get3(), nil, "非法日期不保存")
h.eq(vim.api.nvim_win_is_valid(win3), true, "非法日期表单不关闭")
press(buf3, "n", "q")

h.finish("form")
