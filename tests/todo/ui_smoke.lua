package.path = "./lua/?.lua;./lua/?/init.lua;./tests/?.lua;" .. package.path
local h = require("todo.helper")

-- 准备数据文件
local tmp = vim.fn.tempname() .. ".md"
local fd = io.open(tmp, "w")
fd:write("## 2026-07-15\n- [ ] 任务A @nlp !high\n- [x] 任务B\n\n## 2026-07-28\n- [ ] 任务C\n\n## 2026-07-20\n- [ ] 每周打卡 @every week\n")
fd:close()

-- 无头环境默认 80x24 太窄，放大以获得真实布局
vim.o.columns = 200
vim.o.lines = 60

local todo = require("todo")
local store = require("todo.store")
todo.setup({ file = tmp, categories = { nlp = { color = "#7aa2f7" } } })
todo.open()

local function joined()
  local lines = vim.api.nvim_buf_get_lines(todo._buf, 0, -1, false)
  return table.concat(lines, "\n")
end
local function has(s, label)
  h.eq(joined():find(s, 1, true) ~= nil, true, label)
end

-- 月视图渲染（先把光标固定到测试数据的月份，避免受“今天”日期影响）
todo.state.month_cursor = "2026-07-15"
todo.refresh()
has("┌", "月视图有网格边框")
has("2026 年 7 月", "月视图标题")
has("星期一", "星期表头")
has("任务A", "显示任务A")
has("任务C", "显示任务C")

-- 光标移动
todo.state.month_cursor = "2026-07-15"
todo.refresh()
has("7月1日", "1 号显示月日格式")

-- 侧边栏存在且 zindex=40
h.eq(todo._side_win and vim.api.nvim_win_is_valid(todo._side_win), true, "侧边栏窗口存在")
h.eq(vim.api.nvim_win_get_config(todo._side_win).zindex, 40, "侧边栏 zindex")
h.eq(vim.api.nvim_win_get_config(todo._win).zindex, 40, "日历 zindex")

local function side_joined()
  return table.concat(vim.api.nvim_buf_get_lines(todo._side_buf, 0, -1, false), "\n")
end
-- 侧边栏只显示未完成：任务A/任务C 可见，任务B(done) 不可见
h.eq(side_joined():find("任务A", 1, true) ~= nil, true, "侧边栏显示任务A")
h.eq(side_joined():find("任务C", 1, true) ~= nil, true, "侧边栏显示任务C")
h.eq(side_joined():find("任务B", 1, true) == nil, true, "侧边栏不显示已完成")
h.eq(side_joined():find("2026-07-15", 1, true) ~= nil, true, "侧边栏日期头")

-- 底部命令栏
h.eq(side_joined():find("a 新建", 1, true) ~= nil, true, "命令栏：a 新建")
h.eq(side_joined():find("Tab 切窗", 1, true) ~= nil, true, "命令栏：Tab 切窗")
h.eq(side_joined():find("q 关闭", 1, true) ~= nil, true, "命令栏：q 关闭")

-- 周期任务标记：月历与侧边栏显示 ↻
h.eq(joined():find("每周打卡", 1, true) ~= nil, true, "月历显示周期任务")
h.eq(joined():find("↻", 1, true) ~= nil, true, "月历显示周期标记")
h.eq(side_joined():find("↻", 1, true) ~= nil, true, "侧边栏显示周期标记")

-- 完成周期任务 -> 生成下个实例
todo.state.month_cursor = "2026-07-20"
todo.refresh()
todo.actions.toggle_task(store.by_date("2026-07-20")[1])
h.eq(store.by_date("2026-07-20")[1].done, true, "周期任务完成")
h.eq(store.by_date("2026-07-27")[1] ~= nil, true, "下周自动生成新实例")
h.eq(store.by_date("2026-07-27")[1].done, false, "新实例未完成")
h.eq(store.by_date("2026-07-27")[1].cycle, "week", "新实例保留周期")

-- 快速通道：月视图 h 移动后 buffer 文本不变
todo.state.month_cursor = "2026-07-15"
todo.refresh()
local before = joined()
for _, mp in ipairs(vim.api.nvim_buf_get_keymap(todo._buf, "n")) do
  if mp.lhs == "h" then mp.callback() end
end
h.eq(todo.state.month_cursor, "2026-07-14", "h 移动光标")
h.eq(joined() == before, true, "快速通道不重写 buffer")
todo.state.month_cursor = "2026-07-15"
todo.refresh()

-- Tab 焦点切换
todo.actions.focus_toggle()
h.eq(todo.state.focus, "sidebar", "Tab 切到侧边栏")
h.eq(vim.api.nvim_get_current_win(), todo._side_win, "当前窗口为侧边栏")

-- 侧边栏 j 移动 + <CR> 跳转（任务A -> 每周打卡 -> 任务C）
for _, mp in ipairs(vim.api.nvim_buf_get_keymap(todo._side_buf, "n")) do
  if mp.lhs == "j" then mp.callback() end
end
for _, mp in ipairs(vim.api.nvim_buf_get_keymap(todo._side_buf, "n")) do
  if mp.lhs == "j" then mp.callback() end
end
h.eq(todo.state.side_sel_id, "2026-07-28-1", "j 两次选中任务C")
for _, mp in ipairs(vim.api.nvim_buf_get_keymap(todo._side_buf, "n")) do
  if mp.lhs == "<CR>" then mp.callback() end
end
h.eq(todo.state.month_cursor, "2026-07-28", "<CR> 跳转日历到任务日期")
h.eq(todo.state.focus, "sidebar", "跳转后焦点留在侧边栏")

todo.actions.focus_toggle()
h.eq(todo.state.focus, "calendar", "Tab 切回日历")
todo.state.month_cursor = "2026-07-15"
todo.refresh()

-- 切周视图
todo.actions.show_week("2026-07-15")
has("星期三 15", "周视图列标题")
has("任务A", "周视图显示任务")

-- 周视图动作：toggle（单任务日期不弹选择器）
todo.actions.toggle("2026-07-28")
h.eq(store.by_date("2026-07-28")[1].done, true, "toggle 生效并落盘")

-- 回月视图
todo.actions.show_month("2026-07-15")
has("2026 年 7 月", "回到月视图")

-- 关闭
todo.close()
h.eq(todo._win, nil, "关闭后窗口句柄清空")

os.remove(tmp)
h.finish("ui_smoke")
