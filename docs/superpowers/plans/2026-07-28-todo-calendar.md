# Todo Calendar 插件实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 nvim 配置内实现一个日历式 TODO 插件：月历/周历 TUI、任务按日期排布、分类着色、Markdown 持久化。

**Architecture:** 纯 Lua scratch buffer + extmark 自绘网格（box-drawing 边框）；浮动表单 buffer 编辑任务；Markdown 文件存储。模块：util（日期/宽度）→ parser（md⇄tasks，纯函数）→ store（CRUD+落盘）→ ui（month/week/form/hl）→ init（setup/窗口/动作）。

**Tech Stack:** Neovim 0.12.4 Lua API，零新增插件依赖。

**Spec:** `docs/superpowers/specs/2026-07-28-todo-calendar-design.md`

## Global Constraints

- git 仓库根为 `~/.config/nvim`，所有文件创建于其下；每个 Task 结束即 commit。
- Neovim 0.12：用 `vim.uv`（不是 `vim.loop`）、`vim.api.nvim_set_option_value`（不是 `nvim_buf_set_option`）。
- 不新增任何插件依赖；只用内置 API。
- UI 文案一律中文。
- 测试统一命令（cwd = `~/.config/nvim`）：`nvim --clean -l tests/todo/<spec>.lua`；预期最后一行输出 `<name>: N passed, 0 failed` 且退出码 0（紧跟 `&& echo "exit=$?"` 验证）。若 `--clean` 与 `-l` 组合不可用，改用 `nvim -u NONE -l`。
- 测试文件的 `package.path` 依赖 cwd 为 `~/.config/nvim`，必须从该目录运行。
- 任务结构体字段（parser 产出 / store 存储）：`{ title=string, date="YYYY-MM-DD", category=string|nil, priority="high"|"medium"|"low", done=boolean, notes=string }`；store 在加载/变更后额外派生 `id`（`date-节内序号`，不落盘）。

---

### Task 1: util.lua + 测试辅助 + util 测试

**Files:**
- Create: `~/.config/nvim/lua/todo/util.lua`
- Create: `~/.config/nvim/tests/todo/helper.lua`
- Test: `~/.config/nvim/tests/todo/util_spec.lua`

**Interfaces:**
- Consumes: 无
- Produces（后续所有任务依赖，签名必须一字不差）:
  - `util.strwidth(s) -> number`
  - `util.truncate(s, w) -> string`（截到显示宽度 ≤ w，截断时末尾加 `…`）
  - `util.pad_right(s, w) -> string`
  - `util.fit(s, w) -> string`（truncate+pad_right）
  - `util.today() -> "YYYY-MM-DD"`
  - `util.is_valid_date(s) -> boolean`
  - `util.days_in_month(y, m) -> number`
  - `util.split_date(s) -> y, m, d`（数字）
  - `util.make_date(y, m, d) -> "YYYY-MM-DD"`
  - `util.add_days(s, n) -> "YYYY-MM-DD"`
  - `util.weekday(s) -> 1..7`（1=周一）
  - `util.month_grid(y, m) -> {42 个日期字符串}`（周一起，含前后月填充）
  - `util.add_months(y, m, n) -> y, m`
  - `util.week_dates(s) -> {7 个日期字符串}`（周一起）
  - `util.dow_names = { "星期一", ..., "星期日" }`
  - `helper.eq(actual, expected, label)`（深比较，失败打印）
  - `helper.finish(name)`（打印统计并按失败数 `os.exit`）

- [ ] **Step 1: 写测试辅助 helper.lua**

```lua
local M = { failed = 0, passed = 0 }

local function ser(v)
  if type(v) ~= "table" then return tostring(v) end
  local parts = {}
  for k, val in pairs(v) do
    parts[#parts + 1] = tostring(k) .. "=" .. tostring(val)
  end
  table.sort(parts)
  return "{" .. table.concat(parts, ", ") .. "}"
end

local function deep_eq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deep_eq(v, b[k]) then return false end end
  for k, v in pairs(b) do if not deep_eq(v, a[k]) then return false end end
  return true
end

function M.eq(actual, expected, label)
  if deep_eq(actual, expected) then
    M.passed = M.passed + 1
  else
    M.failed = M.failed + 1
    print("FAIL: " .. (label or ""))
    print("  expected: " .. ser(expected))
    print("  actual:   " .. ser(actual))
  end
end

function M.finish(name)
  print(string.format("%s: %d passed, %d failed", name, M.passed, M.failed))
  os.exit(M.failed > 0 and 1 or 0)
end

return M
```

- [ ] **Step 2: 写失败测试 util_spec.lua**

```lua
package.path = "./lua/?.lua;./lua/?/init.lua;./tests/?.lua;" .. package.path
local h = require("todo.helper")
local util = require("todo.util")

-- today 格式
h.eq(util.today():match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil, true, "today 格式")

-- is_valid_date
h.eq(util.is_valid_date("2026-07-28"), true, "合法日期")
h.eq(util.is_valid_date("2026-02-29"), false, "平年 2 月无 29 日")
h.eq(util.is_valid_date("2028-02-29"), true, "闰年 2 月 29 日")
h.eq(util.is_valid_date("2000-02-29"), true, "2000 是闰年")
h.eq(util.is_valid_date("2100-02-29"), false, "2100 不是闰年")
h.eq(util.is_valid_date("2026-7-8"), false, "必须补零")
h.eq(util.is_valid_date("abcd"), false, "非日期")

-- weekday（2026-07-28 是周二；2026-07-01 是周三）
h.eq(util.weekday("2026-07-28"), 2, "2026-07-28 周二")
h.eq(util.weekday("2026-07-01"), 3, "2026-07-01 周三")

-- days_in_month
h.eq(util.days_in_month(2026, 2), 28, "2026 年 2 月")
h.eq(util.days_in_month(2028, 2), 29, "2028 年 2 月")

-- add_days
h.eq(util.add_days("2026-01-31", 1), "2026-02-01", "跨月加一天")
h.eq(util.add_days("2026-07-28", -7), "2026-07-21", "减 7 天")

-- add_months
local y, m = util.add_months(2026, 12, 1)
h.eq({ y, m }, { 2027, 1 }, "12 月加 1 月跨年")
y, m = util.add_months(2026, 1, -1)
h.eq({ y, m }, { 2025, 12 }, "1 月减 1 月跨年")

-- month_grid
local g = util.month_grid(2026, 7)
h.eq(#g, 42, "月网格 42 格")
h.eq(g[1], "2026-06-29", "2026 年 7 月网格首日")
h.eq(g[42], "2026-08-09", "2026 年 7 月网格末日")

-- week_dates
local wk = util.week_dates("2026-07-28")
h.eq(wk[1], "2026-07-27", "本周周一")
h.eq(wk[7], "2026-08-02", "本周周日")

-- truncate / pad_right / fit（中文按宽字符）
h.eq(util.truncate("你好世界", 5), "你好…", "中文截断")
h.eq(util.truncate("hello", 5), "hello", "不超宽原样")
h.eq(util.truncate("hello world", 5), "hell…", "英文截断")
h.eq(util.fit("你好", 6), "你好  ", "fit 中文补齐")
h.eq(util.fit("ab", 4), "ab  ", "fit 英文补齐")
h.eq(util.pad_right("abc", 3), "abc", "已够宽原样")

h.finish("util")
```

- [ ] **Step 3: 运行确认失败**

Run: `cd ~/.config/nvim && nvim --clean -l tests/todo/util_spec.lua`
Expected: 报错 `module 'todo.util' not found`，退出码非 0

- [ ] **Step 4: 实现 util.lua**

```lua
local M = {}

M.dow_names = { "星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日" }

-- 逐字符迭代 UTF-8 字符串
function M.each_char(s)
  return s:gmatch("[%z\1-\127\194-\244][\128-\191]*")
end

function M.strwidth(s)
  return vim.fn.strdisplaywidth(s)
end

-- 截断到显示宽度 <= w；被截断时末尾加 …
function M.truncate(s, w)
  if w <= 0 then return "" end
  if vim.fn.strdisplaywidth(s) <= w then return s end
  if w == 1 then return "…" end
  local out, width = {}, 0
  for c in M.each_char(s) do
    local cw = vim.fn.strdisplaywidth(c)
    if width + cw > w - 1 then break end
    out[#out + 1] = c
    width = width + cw
  end
  return table.concat(out) .. "…"
end

-- 右补空格到显示宽度 w（已 >= w 时原样返回）
function M.pad_right(s, w)
  local sw = vim.fn.strdisplaywidth(s)
  if sw >= w then return s end
  return s .. string.rep(" ", w - sw)
end

-- 截断 + 补齐到定宽
function M.fit(s, w)
  return M.pad_right(M.truncate(s, w), w)
end

function M.today()
  return os.date("%Y-%m-%d")
end

function M.days_in_month(y, m)
  local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
  if m == 2 and (y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)) then
    return 29
  end
  return days[m]
end

function M.is_valid_date(s)
  if type(s) ~= "string" then return false end
  local y, m, d = s:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  y, m, d = tonumber(y), tonumber(m), tonumber(d)
  if not y then return false end
  if m < 1 or m > 12 or d < 1 then return false end
  return d <= M.days_in_month(y, m)
end

function M.split_date(s)
  local y, m, d = s:match("^(%d+)%-(%d+)%-(%d+)$")
  return tonumber(y), tonumber(m), tonumber(d)
end

function M.make_date(y, m, d)
  return string.format("%04d-%02d-%02d", y, m, d)
end

local function to_time(s)
  local y, m, d = M.split_date(s)
  return os.time({ year = y, month = m, day = d, hour = 12 })
end

function M.add_days(s, n)
  return os.date("%Y-%m-%d", to_time(s) + n * 86400)
end

-- 周几：1=周一 ... 7=周日
function M.weekday(s)
  local w = os.date("*t", to_time(s)).wday -- 1=周日 ... 7=周六
  return (w + 5) % 7 + 1
end

-- 月视图 42 格（含前后月填充），周一起
function M.month_grid(y, m)
  local first = M.make_date(y, m, 1)
  local start = M.add_days(first, -(M.weekday(first) - 1))
  local days = {}
  for i = 0, 41 do
    days[#days + 1] = M.add_days(start, i)
  end
  return days
end

-- (y, m) 加减 n 个月 -> y, m
function M.add_months(y, m, n)
  local total = y * 12 + (m - 1) + n
  return math.floor(total / 12), total % 12 + 1
end

-- 包含 date 的一周（周一起）7 天
function M.week_dates(s)
  local start = M.add_days(s, -(M.weekday(s) - 1))
  local days = {}
  for i = 0, 6 do
    days[#days + 1] = M.add_days(start, i)
  end
  return days
end

return M
```

- [ ] **Step 5: 运行确认通过**

Run: `cd ~/.config/nvim && nvim --clean -l tests/todo/util_spec.lua && echo "exit=$?"`
Expected: 最后一行 `util: 27 passed, 0 failed`，`exit=0`

- [ ] **Step 6: Commit**

```bash
cd ~/.config/nvim
git add lua/todo/util.lua tests/todo/helper.lua tests/todo/util_spec.lua
git commit -m "feat(todo): 日期与显示宽度工具函数 + 测试"
```

---

### Task 2: parser.lua（Markdown ⇄ 任务列表）

**Files:**
- Create: `~/.config/nvim/lua/todo/parser.lua`
- Test: `~/.config/nvim/tests/todo/parser_spec.lua`

**Interfaces:**
- Consumes: `require("todo.util")` 的 `is_valid_date`
- Produces:
  - `parser.parse(content) -> tasks, unparsed`（tasks 为任务数组，字段见 Global Constraints，**无 id**；unparsed 为无法解析的原始行数组）
  - `parser.serialize(tasks, unparsed) -> content`（日期升序、组内保持原顺序；`!medium` 不写出；无法解析内容写入 `## (unparsed)` 节）
  - 行格式：`- [ ] 标题 @分类 !优先级`，完成 `- [x]`；备注为后续缩进 ≥2 空格的行；元数据只从行尾剥离（标题中间出现 `@`/`!` 不受影响）

- [ ] **Step 1: 写失败测试 parser_spec.lua**

```lua
package.path = "./lua/?.lua;./lua/?/init.lua;./tests/?.lua;" .. package.path
local h = require("todo.helper")
local parser = require("todo.parser")

-- 1. 空内容
local tasks, unp = parser.parse("")
h.eq(#tasks, 0, "空内容任务数")
h.eq(#unp, 0, "空内容 unparsed")

-- 2. 全字段多任务
local src = table.concat({
  "## 2026-07-15",
  "- [ ] 古代绘画作业 @course !low",
  "  备注：第三章 1-5 题",
  "  第二行备注",
  "- [x] AAAI 截稿 @paper !high",
  "",
  "## 2026-07-28",
  "- [ ] 默认优先级任务 @nlp",
}, "\n")
tasks, unp = parser.parse(src)
h.eq(#tasks, 3, "解析出 3 个任务")
h.eq(tasks[1], { title = "古代绘画作业", date = "2026-07-15", category = "course",
  priority = "low", done = false, notes = "备注：第三章 1-5 题\n第二行备注" }, "任务1全字段")
h.eq(tasks[2], { title = "AAAI 截稿", date = "2026-07-15", category = "paper",
  priority = "high", done = true, notes = "" }, "任务2全字段")
h.eq(tasks[3].priority, "medium", "缺省优先级为 medium")
h.eq(#unp, 0, "合法内容无 unparsed")

-- 3. 往返一致
local again, unp2 = parser.parse(parser.serialize(tasks, unp))
h.eq(again, tasks, "parse∘serialize 往返一致")
h.eq(unp2, unp, "unparsed 往返一致")

-- 4. 无法解析内容保留
local bad = "随便一行字\n## 2026-13-99\n- [ ] 坏日期节的任务\n## (unparsed)\n旧内容\n"
local t3, u3 = parser.parse(bad)
h.eq(#t3, 0, "坏日期不产生任务")
h.eq(u3, { "随便一行字", "## 2026-13-99", "- [ ] 坏日期节的任务", "旧内容" }, "unparsed 收集")
local t4, u4 = parser.parse(parser.serialize(t3, u3))
h.eq(#t4, 0, "unparsed 节不产生任务")
h.eq(u4, u3, "unparsed 序列化后稳定")

-- 5. 标题中间的 @ 和 ! 不被当作元数据
local t5 = parser.parse("## 2026-07-28\n- [ ] 给 @someone 发邮件 @nlp\n- [ ] 重要! 任务\n")
h.eq(t5[1].title, "给 @someone 发邮件", "标题中的 @ 保留")
h.eq(t5[1].category, "nlp", "行尾分类识别")
h.eq(t5[2].title, "重要! 任务", "标题中的 ! 保留")
h.eq(t5[2].priority, "medium", "无优先级标记时 medium")

-- 6. 序列化排序与精确格式
local s = parser.serialize({
  { title = "b", date = "2026-08-01", priority = "medium", done = false, notes = "" },
  { title = "a", date = "2026-07-01", priority = "high", done = true, notes = "n" },
}, {})
h.eq(s, table.concat({ "## 2026-07-01", "- [x] a !high", "  n", "",
  "## 2026-08-01", "- [ ] b", "" }, "\n"), "序列化排序与格式")

h.finish("parser")
```

- [ ] **Step 2: 运行确认失败**

Run: `cd ~/.config/nvim && nvim --clean -l tests/todo/parser_spec.lua`
Expected: 报错 `module 'todo.parser' not found`

- [ ] **Step 3: 实现 parser.lua**

```lua
local util = require("todo.util")

local M = {}

local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

-- 任务行 -> task | nil（date 由调用者补上）
local function parse_task_line(line)
  local check, rest = line:match("^%- %[([ x])%] (.*)$")
  if not check then return nil end
  local task = { done = (check == "x"), priority = "medium", notes = "" }
  -- 尾部元数据：先 !优先级，后 @分类（与 serialize 输出顺序对应）
  local pri = rest:match("!(%a+)%s*$")
  if pri == "high" or pri == "medium" or pri == "low" then
    task.priority = pri
    rest = rest:gsub("%s*!%a+%s*$", "")
  end
  local cat = rest:match("@([%w_%-]+)%s*$")
  if cat then
    task.category = cat
    rest = rest:gsub("%s*@[%w_%-]+%s*$", "")
  end
  task.title = trim(rest)
  return task
end

-- parse(content) -> tasks(array), unparsed(array of string)
function M.parse(content)
  local tasks, unparsed = {}, {}
  local cur_date, cur_task = nil, nil
  local in_unparsed = false

  local function flush_task()
    if cur_task then
      tasks[#tasks + 1] = cur_task
      cur_task = nil
    end
  end

  for line in (content .. "\n"):gmatch("([^\n]*)\n") do
    local date = line:match("^## (%d%d%d%d%-%d%d%-%d%d)%s*$")
    if line:match("^## %(unparsed%)%s*$") then
      flush_task()
      cur_date = nil
      in_unparsed = true
    elseif date and util.is_valid_date(date) then
      flush_task()
      cur_date = date
      in_unparsed = false
    elseif line:match("^## ") then
      -- 非法日期节标题：整节归入 unparsed
      flush_task()
      cur_date = nil
      in_unparsed = true
      unparsed[#unparsed + 1] = line
    elseif in_unparsed then
      unparsed[#unparsed + 1] = line
    elseif cur_date then
      local t = parse_task_line(line)
      if t then
        flush_task()
        t.date = cur_date
        cur_task = t
      elseif line:sub(1, 2) == "  " and line:match("%S") and cur_task then
        -- 备注行（缩进 >= 2），保留 2 空格之后的内容
        if cur_task.notes ~= "" then
          cur_task.notes = cur_task.notes .. "\n"
        end
        cur_task.notes = cur_task.notes .. line:sub(3)
      elseif line:match("%S") then
        flush_task()
        unparsed[#unparsed + 1] = line
      end
      -- 空行忽略（不终止当前任务）
    elseif line:match("%S") then
      unparsed[#unparsed + 1] = line
    end
  end
  flush_task()
  return tasks, unparsed
end

local function task_line(t)
  local parts = { "- [", t.done and "x" or " ", "] ", t.title }
  if t.category then
    parts[#parts + 1] = " @" .. t.category
  end
  if t.priority and t.priority ~= "medium" then
    parts[#parts + 1] = " !" .. t.priority
  end
  return table.concat(parts)
end

-- serialize(tasks, unparsed) -> content（按日期升序，组内保持原顺序）
function M.serialize(tasks, unparsed)
  local order, groups = {}, {}
  for _, t in ipairs(tasks) do
    if not groups[t.date] then
      groups[t.date] = {}
      order[#order + 1] = t.date
    end
    groups[t.date][#groups[t.date] + 1] = t
  end
  table.sort(order)

  local out = {}
  for _, date in ipairs(order) do
    out[#out + 1] = "## " .. date
    for _, t in ipairs(groups[date]) do
      out[#out + 1] = task_line(t)
      if t.notes and t.notes ~= "" then
        for nl in (t.notes .. "\n"):gmatch("([^\n]*)\n") do
          out[#out + 1] = "  " .. nl
        end
      end
    end
    out[#out + 1] = ""
  end
  if unparsed and #unparsed > 0 then
    out[#out + 1] = "## (unparsed)"
    for _, l in ipairs(unparsed) do
      out[#out + 1] = l
    end
    out[#out + 1] = ""
  end
  return table.concat(out, "\n")
end

return M
```

- [ ] **Step 4: 运行确认通过**

Run: `cd ~/.config/nvim && nvim --clean -l tests/todo/parser_spec.lua && echo "exit=$?"`
Expected: 最后一行 `parser: 18 passed, 0 failed`，`exit=0`

- [ ] **Step 5: Commit**

```bash
cd ~/.config/nvim
git add lua/todo/parser.lua tests/todo/parser_spec.lua
git commit -m "feat(todo): Markdown 解析/序列化 + 测试"
```

---

### Task 3: store.lua（加载/保存/CRUD）

**Files:**
- Create: `~/.config/nvim/lua/todo/store.lua`
- Test: `~/.config/nvim/tests/todo/store_spec.lua`

**Interfaces:**
- Consumes: `parser.parse` / `parser.serialize`
- Produces:
  - `store.file` / `store.tasks` / `store.unparsed` / `store.mtime`（字段）
  - `store.setup(file)`（支持 `~` 展开）
  - `store.load()`（文件不存在视为空）
  - `store.save(force?) -> ok, err`（外部修改冲突返回 `false, "conflict"`；自动创建父目录）
  - `store.find(id) -> task, index | nil`
  - `store.add(t) / store.update(id, fields) / store.remove(id) / store.toggle(id) / store.move(id, date) -> ok, err`（均改内存后落盘；update 只拷贝 `title/date/category/priority/done/notes` 六个字段）
  - `store.by_date(date) -> task array`（文件顺序，任务带 `id`）

- [ ] **Step 1: 写失败测试 store_spec.lua**

```lua
package.path = "./lua/?.lua;./lua/?/init.lua;./tests/?.lua;" .. package.path
local h = require("todo.helper")
local store = require("todo.store")

local tmp = vim.fn.tempname() .. ".md"
store.setup(tmp)

-- 文件不存在 -> 空
store.load()
h.eq(#store.tasks, 0, "不存在文件视为空")

-- add + 落盘内容
local ok = store.add({ title = "任务一", date = "2026-07-28", category = "nlp",
  priority = "high", done = false, notes = "备注" })
h.eq(ok, true, "add 保存成功")
h.eq(store.tasks[1].id, "2026-07-28-1", "id 派生")
local fd = io.open(tmp, "r")
local content = fd:read("*a")
fd:close()
h.eq(content, "## 2026-07-28\n- [ ] 任务一 @nlp !high\n  备注\n", "文件内容精确匹配")

-- 重载往返
store.load()
h.eq(#store.tasks, 1, "重载任务数")
h.eq(store.tasks[1], { id = "2026-07-28-1", title = "任务一", date = "2026-07-28",
  category = "nlp", priority = "high", done = false, notes = "备注" }, "重载往返一致")

-- toggle / move / update
store.toggle("2026-07-28-1")
h.eq(store.tasks[1].done, true, "toggle")
store.move("2026-07-28-1", "2026-08-01")
h.eq(store.tasks[1].id, "2026-08-01-1", "move 后 id 重派生")
store.update("2026-08-01-1", { title = "新标题", date = "2026-08-01", category = nil,
  priority = "low", done = false, notes = "" })
h.eq(store.tasks[1].category, nil, "update 可把分类置空")
h.eq(store.tasks[1].priority, "low", "update 优先级")

-- 外部修改冲突
store.mtime = 1 -- 模拟文件已被外部改动
local ok2, err2 = store.save()
h.eq(ok2, false, "冲突返回 false")
h.eq(err2, "conflict", "冲突标记")
local ok3 = store.save(true)
h.eq(ok3, true, "force 覆盖成功")

-- remove
store.remove("2026-08-01-1")
h.eq(#store.tasks, 0, "remove 后为空")

-- 找不到的 id
local ok4, err4 = store.toggle("不存在的id")
h.eq(ok4, false, "不存在 id 报错")
h.eq(err4, "not found", "not found 标记")

os.remove(tmp)
h.finish("store")
```

- [ ] **Step 2: 运行确认失败**

Run: `cd ~/.config/nvim && nvim --clean -l tests/todo/store_spec.lua`
Expected: 报错 `module 'todo.store' not found`

- [ ] **Step 3: 实现 store.lua**

```lua
local parser = require("todo.parser")

local M = {
  file = nil,
  tasks = {},
  unparsed = {},
  mtime = nil,
}

local UPDATE_FIELDS = { "title", "date", "category", "priority", "done", "notes" }

local function derive_ids()
  local counts = {}
  for _, t in ipairs(M.tasks) do
    counts[t.date] = (counts[t.date] or 0) + 1
    t.id = t.date .. "-" .. counts[t.date]
  end
end

local function stat_mtime(path)
  local st = (vim.uv or vim.loop).fs_stat(path)
  return st and st.mtime.sec or nil
end

function M.setup(file)
  M.file = vim.fn.expand(file)
end

function M.load()
  M.tasks, M.unparsed = {}, {}
  local fd = io.open(M.file, "r")
  if fd then
    local content = fd:read("*a")
    fd:close()
    M.tasks, M.unparsed = parser.parse(content)
  end
  M.mtime = stat_mtime(M.file)
  derive_ids()
end

-- 保存；文件被外部修改且未 force 时返回 false, "conflict"
function M.save(force)
  if not force then
    local cur = stat_mtime(M.file)
    if M.mtime ~= nil and cur ~= nil and cur ~= M.mtime then
      return false, "conflict"
    end
  end
  local dir = vim.fn.fnamemodify(M.file, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  local fd, err = io.open(M.file, "w")
  if not fd then return false, err end
  fd:write(parser.serialize(M.tasks, M.unparsed))
  fd:close()
  M.mtime = stat_mtime(M.file)
  return true
end

function M.find(id)
  for i, t in ipairs(M.tasks) do
    if t.id == id then return t, i end
  end
  return nil
end

function M.add(t)
  M.tasks[#M.tasks + 1] = t
  derive_ids()
  return M.save()
end

function M.update(id, fields)
  local t = M.find(id)
  if not t then return false, "not found" end
  for _, k in ipairs(UPDATE_FIELDS) do
    t[k] = fields[k]
  end
  derive_ids()
  return M.save()
end

function M.remove(id)
  local _, i = M.find(id)
  if not i then return false, "not found" end
  table.remove(M.tasks, i)
  derive_ids()
  return M.save()
end

function M.toggle(id)
  local t = M.find(id)
  if not t then return false, "not found" end
  t.done = not t.done
  return M.save()
end

function M.move(id, date)
  local t = M.find(id)
  if not t then return false, "not found" end
  t.date = date
  derive_ids()
  return M.save()
end

function M.by_date(date)
  local out = {}
  for _, t in ipairs(M.tasks) do
    if t.date == date then
      out[#out + 1] = t
    end
  end
  return out
end

return M
```

- [ ] **Step 4: 运行确认通过**

Run: `cd ~/.config/nvim && nvim --clean -l tests/todo/store_spec.lua && echo "exit=$?"`
Expected: 最后一行 `store: 16 passed, 0 failed`，`exit=0`

- [ ] **Step 5: Commit**

```bash
cd ~/.config/nvim
git add lua/todo/store.lua tests/todo/store_spec.lua
git commit -m "feat(todo): 任务存储层（CRUD + mtime 冲突检测）+ 测试"
```

---

### Task 4: config + hl + init 骨架 + month 占位（可打开/关闭浮窗）

**Files:**
- Create: `~/.config/nvim/lua/todo/config.lua`
- Create: `~/.config/nvim/lua/todo/ui/hl.lua`
- Create: `~/.config/nvim/lua/todo/init.lua`
- Create: `~/.config/nvim/lua/todo/ui/month.lua`（占位，Task 5 整体替换）

**Interfaces:**
- Consumes: `store.setup/load/save/toggle/remove/move/add/update/by_date`，`util.*`
- Produces:
  - `config.merge(opts) -> cfg`（cfg 字段：`file, categories, default_category, win{width,height}`）
  - `hl.NS`（namespace id）；`hl.setup(categories)`；`hl.cat(name) -> 高亮组名|nil`；`hl.pri_marks(p) -> " !!!"|" !!"|" !"`（high/medium/low）；`hl.pri_hl(p) -> 高亮组名|nil`；`hl.apply(buf, lines, spans)`（spans 元素 `{lnum(0基), col_start, col_end, hl_group, priority?}`，col 为字节偏移）
  - `require("todo")` 主模块：`setup(opts)`、`open()`、`close()`、`toggle()`、`refresh()`；字段 `cfg/state/_buf/_win/actions`
  - `state` 结构：`{ view="month"|"week", month_cursor=date, week_base=date, week_sel={col=number,row=number} }`
  - `actions` 完整集合（其中 form 的 require 为惰性，Task 6 之前不调用即不报错）：`add(date)`、`edit(date)`、`edit_task(t)`、`toggle(date)`、`toggle_task(t)`、`remove(date)`、`remove_task(t)`、`move(date)`、`move_task(t)`、`shift_month(n)`、`shift_week(n)`、`show_week(date)`、`show_month(date)`、`close()`
  - 视图模块协议：`require("todo.ui."..state.view).attach(ctx)`，ctx = `{ buf, win, cfg, state, refresh, actions }`

- [ ] **Step 1: 写 config.lua**

```lua
local M = {}

M.defaults = {
  file = "~/todo.md",
  categories = {},
  default_category = nil,
  win = { width = 0.9, height = 0.85 },
}

function M.merge(opts)
  local cfg = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  assert(type(cfg.file) == "string", "todo: file 必须是字符串")
  assert(type(cfg.categories) == "table", "todo: categories 必须是 table")
  for name, c in pairs(cfg.categories) do
    assert(type(c) == "table" and type(c.color) == "string",
      "todo: 分类 '" .. name .. "' 需要形如 { color = \"#rrggbb\" }")
  end
  return cfg
end

return M
```

- [ ] **Step 2: 写 hl.lua**

```lua
local M = {}

M.NS = nil
M._cats = {}

local function set(name, def)
  vim.api.nvim_set_hl(0, name, def)
end

function M.setup(categories)
  M.NS = vim.api.nvim_create_namespace("todo_cal")
  M._cats = categories or {}
  set("TodoCalTitle", { bold = true })
  set("TodoCalHeader", { bold = true })
  set("TodoCalBorder", { link = "Comment" })
  set("TodoCalToday", { bold = true, fg = "#ff9e64" })
  set("TodoCalOtherMonth", { link = "Comment" })
  set("TodoCalCursor", { reverse = true })
  set("TodoCalDone", { strikethrough = true, fg = "#565f89" })
  set("TodoCalPriHigh", { fg = "#f7768e" })
  set("TodoCalPriLow", { link = "Comment" })
  set("TodoCalOverflow", { link = "Comment" })
  set("TodoCalFormError", { fg = "#f7768e" })
  for name, c in pairs(M._cats) do
    set("TodoCalCat_" .. name, { fg = c.color })
  end
end

-- 分类名 -> 高亮组；未定义的分类返回 nil
function M.cat(name)
  if name and M._cats[name] then
    return "TodoCalCat_" .. name
  end
  return nil
end

-- 优先级标记文本
function M.pri_marks(p)
  if p == "high" then return " !!!" end
  if p == "low" then return " !" end
  return " !!"
end

-- 优先级高亮组（medium 无特殊高亮）
function M.pri_hl(p)
  if p == "high" then return "TodoCalPriHigh" end
  if p == "low" then return "TodoCalPriLow" end
  return nil
end

-- 把渲染结果写入 buffer（行 + 高亮 spans）
function M.apply(buf, lines, spans)
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, M.NS, 0, -1)
  for _, s in ipairs(spans) do
    vim.api.nvim_buf_set_extmark(buf, M.NS, s[1], s[2], {
      end_col = s[3],
      hl_group = s[4],
      priority = s[5] or 100,
    })
  end
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

return M
```

- [ ] **Step 3: 写 init.lua（完整版，actions 全部包含）**

```lua
local config = require("todo.config")
local store = require("todo.store")
local hl = require("todo.hl")
local util = require("todo.util")

local M = {}

M.cfg = nil
M.state = nil
M._buf = nil
M._win = nil

M.actions = {}

function M.setup(opts)
  M.cfg = config.merge(opts)
  store.setup(M.cfg.file)
  hl.setup(M.cfg.categories)
  vim.api.nvim_create_user_command("Todo", function() M.toggle() end, {})
  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if M._win and vim.api.nvim_win_is_valid(M._win) then
        M.close()
        M.open()
      end
    end,
  })
end

local function ensure_buf()
  if M._buf and vim.api.nvim_buf_is_valid(M._buf) then return end
  M._buf = vim.api.nvim_create_buf(false, true)
  vim.bo[M._buf].bufhidden = "hide"
  vim.bo[M._buf].filetype = "todocal"
end

function M.open()
  if M._win and vim.api.nvim_win_is_valid(M._win) then return end
  store.load()
  if not M.state then
    local today = util.today()
    M.state = {
      view = "month",
      month_cursor = today,
      week_base = today,
      week_sel = { col = util.weekday(today), row = 1 },
    }
  end
  ensure_buf()
  local w = math.floor(vim.o.columns * M.cfg.win.width)
  local h = math.floor(vim.o.lines * M.cfg.win.height)
  M._win = vim.api.nvim_open_win(M._buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
    style = "minimal",
    border = "rounded",
    title = " TODO ",
    title_pos = "center",
  })
  vim.wo[M._win].wrap = false
  M.refresh()
end

function M.close()
  if M._win and vim.api.nvim_win_is_valid(M._win) then
    vim.api.nvim_win_close(M._win, true)
  end
  M._win = nil
end

function M.toggle()
  if M._win and vim.api.nvim_win_is_valid(M._win) then
    M.close()
  else
    M.open()
  end
end

function M.refresh()
  if not (M._win and vim.api.nvim_win_is_valid(M._win)) then return end
  local view = require("todo.ui." .. M.state.view)
  view.attach({
    buf = M._buf,
    win = M._win,
    cfg = M.cfg,
    state = M.state,
    refresh = M.refresh,
    actions = M.actions,
  })
end

-- 保存结果统一处理（含外部修改冲突）
local function persist(ok, err)
  if ok then
    M.refresh()
    return
  end
  if err == "conflict" then
    vim.ui.select({ "覆盖", "放弃并重载" }, { prompt = "todo 文件已被外部修改：" }, function(choice)
      if choice == "覆盖" then
        store.save(true)
      else
        store.load()
      end
      M.refresh()
    end)
  else
    vim.notify("todo 保存失败: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- 某天有多个任务时让用户选择
local function pick_task(date, cb)
  local tasks = store.by_date(date)
  if #tasks == 0 then
    vim.notify("该日期没有任务", vim.log.levels.INFO)
    return
  end
  if #tasks == 1 then
    cb(tasks[1])
    return
  end
  vim.ui.select(tasks, {
    prompt = "选择任务：",
    format_item = function(t) return t.title end,
  }, function(t)
    if t then cb(t) end
  end)
end

local function new_task(date)
  return {
    title = "",
    date = date,
    category = M.cfg.default_category,
    priority = "medium",
    done = false,
    notes = "",
  }
end

function M.actions.add(date)
  require("todo.ui.form").open(new_task(date), M.cfg, function(t)
    persist(store.add(t))
  end)
end

function M.actions.edit_task(t)
  require("todo.ui.form").open(vim.deepcopy(t), M.cfg, function(nt)
    persist(store.update(t.id, nt))
  end)
end

function M.actions.edit(date)
  pick_task(date, function(t) M.actions.edit_task(t) end)
end

function M.actions.toggle_task(t)
  persist(store.toggle(t.id))
end

function M.actions.toggle(date)
  pick_task(date, function(t) M.actions.toggle_task(t) end)
end

function M.actions.remove_task(t)
  vim.ui.select({ "否", "是" }, { prompt = "删除任务「" .. t.title .. "」？" }, function(c)
    if c == "是" then persist(store.remove(t.id)) end
  end)
end

function M.actions.remove(date)
  pick_task(date, function(t) M.actions.remove_task(t) end)
end

function M.actions.move_task(t)
  vim.ui.input({ prompt = "移动到日期（YYYY-MM-DD）：", default = t.date }, function(input)
    if not input then return end
    input = vim.trim(input)
    if not util.is_valid_date(input) then
      vim.notify("非法日期: " .. input, vim.log.levels.ERROR)
      return
    end
    persist(store.move(t.id, input))
  end)
end

function M.actions.move(date)
  pick_task(date, function(t) M.actions.move_task(t) end)
end

function M.actions.shift_month(n)
  local y, m, d = util.split_date(M.state.month_cursor)
  y, m = util.add_months(y, m, n)
  d = math.min(d, util.days_in_month(y, m))
  M.state.month_cursor = util.make_date(y, m, d)
  M.refresh()
end

function M.actions.shift_week(n)
  M.state.week_base = util.add_days(M.state.week_base, 7 * n)
  M.refresh()
end

function M.actions.show_week(date)
  M.state.view = "week"
  M.state.week_base = date
  M.state.week_sel = { col = util.weekday(date), row = 1 }
  M.refresh()
end

function M.actions.show_month(date)
  M.state.view = "month"
  M.state.month_cursor = date
  M.refresh()
end

function M.actions.close()
  M.close()
end

return M
```

- [ ] **Step 4: 写 month.lua 占位**

```lua
-- 占位实现，Task 5 替换为完整月视图
local M = {}

function M.attach(ctx)
  vim.keymap.set("n", "q", function() ctx.actions.close() end,
    { buffer = ctx.buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", function() ctx.actions.close() end,
    { buffer = ctx.buf, nowait = true, silent = true })
  vim.api.nvim_set_option_value("modifiable", true, { buf = ctx.buf })
  vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, { " TODO（月视图占位）" })
  vim.api.nvim_set_option_value("modifiable", false, { buf = ctx.buf })
end

return M
```

- [ ] **Step 5: 手动验证打开/关闭**

Run:

```bash
cd ~/.config/nvim && nvim --clean \
  +'lua require("todo").setup({ categories = { nlp = { color = "#7aa2f7" } } })' \
  +'Todo'
```

Expected: 屏幕中央出现圆角边框浮窗（约占 90%×85%），内含一行 `TODO（月视图占位）`，顶边中央显示 `TODO` 标题；按 `q` 浮窗关闭；再 `:Todo` 回车能重新打开；`:qa!` 退出。

- [ ] **Step 6: Commit**

```bash
cd ~/.config/nvim
git add lua/todo/config.lua lua/todo/ui/hl.lua lua/todo/init.lua lua/todo/ui/month.lua
git commit -m "feat(todo): 配置/高亮/主模块骨架与浮窗"
```

---

### Task 5: 完整月视图（网格渲染 + 光标移动 + 高亮）

**Files:**
- Modify: `~/.config/nvim/lua/todo/ui/month.lua`（整体替换 Task 4 占位）

**Interfaces:**
- Consumes: `util.*`、`store.by_date`、`hl.cat/pri_marks/pri_hl/apply`、ctx 协议（Task 4）
- Produces: `month.attach(ctx)`（设置月视图全部键位并渲染）。渲染协议：
  - 第 1 行 ` %d 年 %d 月 `（hl `TodoCalTitle`）
  - 第 2 行星期表头（hl `TodoCalHeader`，与格内容列对齐）
  - 之后 7×6 box-drawing 网格（边框 hl `TodoCalBorder`）；格内第 1 行日期号（1 号显示 `M月d日`，其余显示日号；今天 `TodoCalToday`，非本月 `TodoCalOtherMonth`）；任务行 ` ● 标题`+优先级标记（bullet 用分类色 `hl.cat`，完成整行 `TodoCalDone`，high/low 标记分别 `TodoCalPriHigh`/`TodoCalPriLow`）；溢出末行 ` +N`（`TodoCalOverflow`）
  - 光标格整格内容区加 `TodoCalCursor`（priority 300）
  - 格高自适应：`cell_h = clamp(floor((win_h-3)/6)-1, 3, 7)`，任务行数 = cell_h-2；格宽 `cw = max(10, floor((win_w-8)/7))`

- [ ] **Step 1: 整体替换 month.lua**

```lua
local util = require("todo.util")
local store = require("todo.store")
local hl = require("todo.hl")

local M = {}

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
  local marks = hl.pri_marks(t.priority)
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
local function cell_rows(date, cur_m, today, cw, cell_h)
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

  local tasks = store.by_date(date)
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

  for w = 0, 5 do
    if w == 0 then
      push_line(border("┌", "┬", "┐"), "TodoCalBorder")
    else
      push_line(border("├", "┼", "┤"), "TodoCalBorder")
    end
    local cells = {}
    for col = 1, 7 do
      cells[col] = cell_rows(days[w * 7 + col], m, today, cw, cell_h)
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
end

function M.attach(ctx)
  local st = ctx.state
  local map = function(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = ctx.buf, nowait = true, silent = true })
  end
  map("h", function() st.month_cursor = util.add_days(st.month_cursor, -1); ctx.refresh() end)
  map("l", function() st.month_cursor = util.add_days(st.month_cursor, 1); ctx.refresh() end)
  map("j", function() st.month_cursor = util.add_days(st.month_cursor, 7); ctx.refresh() end)
  map("k", function() st.month_cursor = util.add_days(st.month_cursor, -7); ctx.refresh() end)
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
```

- [ ] **Step 2: 手动验证渲染与移动**

先造测试数据：

```bash
cat > /tmp/todo_test.md <<'EOF'
## 2026-07-15
- [ ] 古代绘画作业 @course !low
- [x] 已完成任务 @nlp
EOF
```

启动：

```bash
cd ~/.config/nvim && nvim --clean \
  +'lua require("todo").setup({ file = "/tmp/todo_test.md", categories = { nlp = { color = "#7aa2f7" }, course = { color = "#e0af68" }, paper = { color = "#f7768e" } } })' \
  +'lua require("todo").open(); require("todo").state.month_cursor = "2026-07-15"; require("todo").refresh()'
```

Expected:
- 浮窗内显示 ` 2026 年 7 月 ` 标题、星期表头、7×6 带边框网格
- `7月1日`/`8月1日` 格日期号带 `月日` 格式；6 月填充格日期号为暗色
- 15 日格内两行任务：`古代绘画作业` 末尾带 ` !`；`已完成任务` 整行删除线灰色
- 15 日格整格反色（光标格）
- `h`/`l` 光标格 ±1 天；`j`/`k` ±7 天；跨月时网格标题随之变化；`<`/`>` 整月切换；`t` 回今天
- `q` 关闭；`:qa!` 退出（`a`/`e`/`x`/`d`/`m`/`w` 在本任务后会报错属正常，验证时不要按）

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/todo/ui/month.lua
git commit -m "feat(todo): 月视图网格渲染与光标移动"
```

---

### Task 6: 任务编辑表单 form.lua（接上 a/e/x/d/m 动作）

**Files:**
- Create: `~/.config/nvim/lua/todo/ui/form.lua`

**Interfaces:**
- Consumes: `util.is_valid_date`；init.lua 的 `actions.add/edit_task`（Task 4 已写入，惰性 require 本模块）
- Produces:
  - `form.open(task, cfg, on_save)`：浮动可编辑 buffer，模板行依次为 `title:`/`date:`/`category:`/`priority:`/`done:`/`notes:`（notes 可占多行）
  - `<CR>`（normal）或 `:w`：校验并回调 `on_save(task)` 后关闭；`q`：放弃关闭
  - 校验失败：表单底部虚拟行显示 `⚠ 错误信息`（hl `TodoCalFormError`），不关闭
  - 校验规则：title 非空；date 过 `util.is_valid_date`；category 为空或在 `cfg.categories` 中；priority ∈ high/medium/low；done ∈ true/false

- [ ] **Step 1: 实现 form.lua**

```lua
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
```

- [ ] **Step 2: 手动验证任务增改删**

```bash
rm -f /tmp/todo_form.md
cd ~/.config/nvim && nvim --clean \
  +'lua require("todo").setup({ file = "/tmp/todo_form.md", categories = { nlp = { color = "#7aa2f7" }, course = { color = "#e0af68" } } })' \
  +'Todo'
```

依次验证：
1. 按 `a` → 弹出表单浮窗，`date:` 行为光标格日期；改成 `title: 测试任务`、`category: nlp`、`priority: high`，`notes:` 下写一行备注；按 `<CR>` → 表单关闭，月视图该日格出现 `● 测试任务 !!!`
2. 另一个终端 `cat /tmp/todo_form.md` → 含 `- [ ] 测试任务 @nlp !high` 和缩进备注行
3. 光标移到该日，按 `e` → 表单带回原值；把 title 改为 `测试任务2` → `<CR>` → 视图与文件同步更新
4. 按 `x` → 任务变删除线灰色；再按 `x` 恢复
5. 按 `m` → 输入合法日期（如 2026-08-01）→ 任务移动到新日期格；再 `m` 输入 `abc` → 报错且不生效
6. 按 `d` → 选择「是」→ 任务消失，文件对应行删除
7. 按 `a`，把 `date:` 改成 `2026-13-99` → `<CR>` → 表单底部出现红色 `⚠` 报错且表单不关闭；按 `q` 放弃
8. `:qa!` 退出

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/todo/ui/form.lua
git commit -m "feat(todo): 任务编辑浮动表单"
```

---

### Task 7: 完整周视图（7 列任务列表 + 键位）

**Files:**
- Create: `~/.config/nvim/lua/todo/ui/week.lua`

**Interfaces:**
- Consumes: 同 month（`util.*`、`store.by_date`、`hl.*`、ctx 协议）
- Produces: `week.attach(ctx)`。渲染协议：
  - 无时间轴；7 列等宽 `cw = max(10, floor((win_w-6)/7))`，列间 `│` 分隔（无外框）
  - 第 1 行列标题 ` 周X DD`（今天列 `TodoCalToday`，其余 `TodoCalHeader`）；第 2 行 `─`/`┼` 分隔线
  - 列内每个任务占 2 行：标题行 ` ● 标题`（bullet 分类色，完成整行 `TodoCalDone`），元信息行 `   分类`+优先级标记（分类名 hl `TodoCalOtherMonth`）；内容行数 = win_h-2，超出显示 ` +N`
  - 选中任务（`state.week_sel = {col,row}`）的 2 行整列宽加 `TodoCalCursor`（priority 300）
  - 键位：`h/l` ±1 列、`j/k` 列内 ±1 任务（均 clamp）；`<` `>` ±1 周；`t` 回今天；`a/e/<CR>/x/d/m` 直接作用于选中任务（不弹选择器）；`M` 回月视图（定位到选中列日期）；`w` 无操作；`q/<Esc>` 关闭

- [ ] **Step 1: 实现 week.lua**

```lua
local util = require("todo.util")
local store = require("todo.store")
local hl = require("todo.hl")

local M = {}

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
      local title = util.truncate(t.title, cw - util.strwidth(bullet))
      line1 = {
        { text = bullet, hl = hl.cat(t.category) },
        { text = title },
        { text = string.rep(" ", cw - util.strwidth(bullet) - util.strwidth(title)) },
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
  for i = 1, 7 do
    cols[i] = col_rows(store.by_date(dates[i]), cw, max_rows)
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
      if i == sel.col and (r == sel.row * 2 - 1 or r == sel.row * 2) then
        spans[#spans + 1] = { lnum, cstart, byte, "TodoCalCursor", 300 }
      end
    end
    lines[#lines + 1] = table.concat(parts)
  end

  hl.apply(ctx.buf, lines, spans)
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
  map("h", function() st.week_sel.col = st.week_sel.col - 1; clamp(ctx); ctx.refresh() end)
  map("l", function() st.week_sel.col = st.week_sel.col + 1; clamp(ctx); ctx.refresh() end)
  map("j", function() st.week_sel.row = st.week_sel.row + 1; clamp(ctx); ctx.refresh() end)
  map("k", function() st.week_sel.row = st.week_sel.row - 1; clamp(ctx); ctx.refresh() end)
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
```

- [ ] **Step 2: 手动验证周视图**

```bash
cat > /tmp/todo_week.md <<'EOF'
## 2026-07-15
- [ ] 周中任务 @nlp !high
- [ ] 另一个任务 @course
EOF
cd ~/.config/nvim && nvim --clean \
  +'lua require("todo").setup({ file = "/tmp/todo_week.md", categories = { nlp = { color = "#7aa2f7" }, course = { color = "#e0af68" } } })' \
  +'lua require("todo").open(); require("todo").actions.show_week("2026-07-15")'
```

Expected:
- 7 列，列标题 ` 周一 13` … ` 周日 19`，`│` 分隔；周三 15 列含两个任务（标题行 + 元信息行）
- 第一个任务元信息行 `   nlp !!!`（!!! 红色）；选中任务 2 行反色
- `h`/`l` 列间移动；`j`/`k` 列内任务间移动；`<`/`>` 整周切换（列标题日期变化）；`t` 回本周
- `x` 切换选中任务完成态；`M` 回月视图并定位 15 日；`q` 关闭

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/todo/ui/week.lua
git commit -m "feat(todo): 周视图 7 列任务列表"
```

---

### Task 8: UI 冒烟测试 + 接入用户配置 + 全量验证

**Files:**
- Create: `~/.config/nvim/tests/todo/ui_smoke.lua`
- Modify: `~/.config/nvim/init.lua`（末尾追加 setup 与键位）

**Interfaces:**
- Consumes: 全部模块
- Produces: `:Todo` 命令与 `<leader>td` 键位在用户日常配置中可用（leader 为空格；已确认 `<leader>td` 未被占用——toggleterm 只占了 tb/tg/tp）

- [ ] **Step 1: 写 UI 冒烟测试 ui_smoke.lua**

```lua
package.path = "./lua/?.lua;./lua/?/init.lua;./tests/?.lua;" .. package.path
local h = require("todo.helper")

-- 准备数据文件
local tmp = vim.fn.tempname() .. ".md"
local fd = io.open(tmp, "w")
fd:write("## 2026-07-15\n- [ ] 任务A @nlp !high\n- [x] 任务B\n\n## 2026-07-28\n- [ ] 任务C\n")
fd:close()

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
has("周三 15", "周视图列标题")
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
```

- [ ] **Step 2: 运行确认通过**

Run: `cd ~/.config/nvim && nvim --clean -l tests/todo/ui_smoke.lua && echo "exit=$?"`
Expected: 最后一行 `ui_smoke: 11 passed, 0 failed`，`exit=0`

- [ ] **Step 3: 接入用户配置**

在 `~/.config/nvim/init.lua` 末尾追加：

```lua

require("todo").setup({
  categories = {
    nlp = { color = "#7aa2f7" },
    RL = { color = "#9ece6a" },
    course = { color = "#e0af68" },
    paper = { color = "#f7768e" },
  },
})
vim.keymap.set("n", "<leader>td", "<cmd>Todo<cr>", { desc = "Todo 日历" })
```

- [ ] **Step 4: 全量回归 + 日常使用验证**

```bash
cd ~/.config/nvim
for f in tests/todo/util_spec.lua tests/todo/parser_spec.lua tests/todo/store_spec.lua tests/todo/ui_smoke.lua; do
  nvim --clean -l "$f" || echo "FAILED: $f"
done
echo "all done exit=$?"
```

Expected: 输出 4 行 `*: N passed, 0 failed`，无 `FAILED`。

再用真实配置手动验证：

```bash
nvim +'Todo'
```

Expected: 插件以 `~/todo.md` 打开月视图；`<leader>td` 也能开关；`a` 添加一条今天的任务后 `cat ~/todo.md` 可见对应 Markdown；删除该测试任务。

- [ ] **Step 5: Commit**

```bash
cd ~/.config/nvim
git add tests/todo/ui_smoke.lua init.lua
git commit -m "feat(todo): UI 冒烟测试 + 接入用户配置（:Todo / <leader>td）"
```

---
