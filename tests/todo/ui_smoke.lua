package.path = "./lua/?.lua;./lua/?/init.lua;./tests/?.lua;" .. package.path
local h = require("todo.helper")

-- 准备数据文件
local tmp = vim.fn.tempname() .. ".md"
local fd = io.open(tmp, "w")
fd:write("## 2026-07-15\n- [ ] 任务A @nlp !high\n- [x] 任务B\n\n## 2026-07-28\n- [ ] 任务C\n")
fd:close()

-- 无头环境默认 80x24 太窄，放大以获得真实布局
vim.o.columns = 200
vim.o.lines = 60

local todo = require("todo")
todo.setup({ file = tmp, categories = { nlp = { color = "#7aa2f7" } } })
todo.open()

local function joined()
  local lines = vim.api.nvim_buf_get_lines(todo._buf, 0, -1, false)
  return table.concat(lines, "\n")
end
local function has(s, label)
  h.eq(joined():find(s, 1, true) ~= nil, true, label)
end

-- 月视图渲染
has("┌", "月视图有网格边框")
has("2026 年 7 月", "月视图标题")
has("星期一", "星期表头")
has("任务A", "显示任务A")
has("任务C", "显示任务C")

-- 光标移动
todo.state.month_cursor = "2026-07-15"
todo.refresh()
has("7月1日", "1 号显示月日格式")

-- 切周视图
todo.actions.show_week("2026-07-15")
has("星期三 15", "周视图列标题")
has("任务A", "周视图显示任务")

-- 周视图动作：toggle（单任务日期不弹选择器）
todo.actions.toggle("2026-07-28")
local store = require("todo.store")
h.eq(store.by_date("2026-07-28")[1].done, true, "toggle 生效并落盘")

-- 回月视图
todo.actions.show_month("2026-07-15")
has("2026 年 7 月", "回到月视图")

-- 关闭
todo.close()
h.eq(todo._win, nil, "关闭后窗口句柄清空")

os.remove(tmp)
h.finish("ui_smoke")
