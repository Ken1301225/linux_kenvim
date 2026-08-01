# Todo Calendar 插件设计

日期：2026-07-28
位置：作为 nvim 配置内的模块 `~/.config/nvim/lua/todo/`

## 目标

在 Neovim 内提供一个日历式 TODO 插件：

- 月视图：7 列 × 6 行带边框的日历网格（参考系统日历截图），任务显示在对应日期格内
- 周视图：7 列等宽任务列表（无时间轴）
- 任务支持：标题、日期、分类（带颜色）、完成状态、优先级、备注
- 数据持久化为可读、可手写编辑的 Markdown 文件

## 技术路线

纯 Lua 实现，零新增插件依赖：

- 主视图：scratch buffer + extmark 自绘网格（box-drawing 边框、高亮）
- 编辑任务：浮动表单 buffer（类 oil.nvim——字段各占一行，直接编辑后确认保存）
- 简单单字段输入（如移动任务到某日期）：`vim.ui.input`

## 模块结构

```
lua/todo/
  init.lua     -- setup() / open() / close() / toggle()，视图状态与切换
  config.lua   -- 默认配置 + 校验（存储路径、分类及颜色、窗口尺寸）
  parser.lua   -- Markdown ⇄ 任务列表；纯函数，不依赖 vim API（可单测）
  store.lua    -- 加载 / 保存 / 任务 CRUD；内存缓存
  util.lua     -- 日期计算、按显示宽度截断/补齐（处理中文宽字符）
  ui/month.lua -- 月视图渲染 + 键位
  ui/week.lua  -- 周视图渲染 + 键位
  ui/form.lua  -- 任务编辑浮动表单
  ui/hl.lua    -- 高亮组定义（今天、光标格、分类色、完成态）
tests/todo/
  parser_spec.lua -- parser 往返解析测试
  util_spec.lua   -- 宽度/日期函数测试
run via: nvim -l tests/todo/<file>   （无头、零依赖断言）
```

## 数据模型

任务（Lua table）：

```lua
{
  id = "2026-08-01-3",      -- 派生：日期 + 节内行序（加载时生成，不落盘）
  title = "AAAI 截稿",
  date = "2026-08-01",      -- YYYY-MM-DD
  category = "paper",       -- 对应 config 中定义的分类名，可为 nil
  priority = "high",        -- "high" | "medium" | "low"，默认 medium
  done = false,
  notes = "备注内容",        -- 可多行，存为单个字符串
}
```

## Markdown 存储格式

默认路径 `~/todo.md`（`setup({ file = ... })` 可改）。

```markdown
## 2026-07-15
- [ ] 古代绘画作业 @course !medium
  备注：第三章 1-5 题
- [x] AAAI 截稿 @paper !high
```

规则：

- `## YYYY-MM-DD` 为日期分节，节内每行一个任务（`- [ ]` 未完成 / `- [x]` 已完成）
- 任务行内元数据：`@分类名`（至多一个）、`!high|!medium|!low`（至多一个），其余文本为标题
- 任务行之后、缩进 ≥ 2 空格的行为备注（可多于一行，保留换行）
- id 不落盘；加载时按 `date-行序` 派生；每次增删改后重新派生，UI 渲染后按 id 重新定位光标
- 保存时全量重写：日期升序、节内按原顺序；无法解析的行原样保留在文件尾部 `## (unparsed)` 节
- 解析必须容错：非法日期节、未知分类、未知优先级均不报错，尽力保留

## 配置

```lua
require("todo").setup({
  file = "~/todo.md",
  categories = {
    nlp    = { color = "#7aa2f7" },
    RL     = { color = "#9ece6a" },
    course = { color = "#e0af68" },
    paper  = { color = "#f7768e" },
  },
  default_category = nil,
  win = { width = 0.9, height = 0.85 }, -- 浮窗占屏幕比例
})
```

分类只在配置中预定义（名字 + 颜色）；数据文件只存分类名。未知分类名解析时保留文本但不渲染颜色。

## 界面

### 窗口

- `require("todo").toggle()` 打开/关闭；居中浮窗，尺寸按 `win` 配置比例
- 月/周视图共用同一个浮窗与 buffer，切换视图即重绘

### 月视图

- 顶部标题行：` 2026 年 7 月 `（居中），其下星期表头 `星期一 … 星期日`
- 网格：box-drawing 字符（`┌ ┬ ┐ ├ ┼ ┤ └ ┴ ┘ │ ─`）画出 7×6 带边框格子
- 单元格：宽 = (浮窗宽 − 8 条竖线) / 7，高固定 7 行（1 行日期号 + 5 行任务 + 1 行 `+N` 溢出提示）
- 首格为当月 1 号所在周一；上月/下月填充格日期号显示为暗色（如 `6 月 29 日` 缩写为首日格式，其余显示日号）
- 任务行：分类色 `●` 前缀 + 标题（按显示宽度截断，中文按宽字符处理）
- 高亮：今天的日期号加粗变色；光标所在格整格反色；完成任务灰色 + 删除线
- 优先级标记：标题后 `!!!`/`!!`/`!`（high/medium/low），可随优先级变色

### 周视图

- 7 列等宽，列间 `│` 分隔；列首 `周一 07-28` 样式标题，今天列标题高亮
- 列内纵向列出任务（可两行：标题行 + 元信息行 `●分类 !优先级`），超出列高显示 `+N`
- 无时间轴、无跨列滚动（v1）

### 编辑表单（浮动小窗）

```
title: AAAI 截稿
date: 2026-08-01
category: paper
priority: high
done: false
notes:
备注第一行
备注第二行
```

- 普通 buffer 直接编辑；`<CR>`（或 `:w`）校验并保存，`q` 放弃
- 校验：date 必须合法；category 必须在配置中（空允许）；priority ∈ high/medium/low；done ∈ true/false
- 校验失败在表单底部报错行，不关闭

## 键位（两视图通用，buffer-local）

| 键 | 功能 |
|---|---|
| `h` `l` | 月：±1 天；周：±1 列 |
| `j` `k` | 月：±7 天；周：列内上下选任务 |
| `<` `>` | 月：上/下月；周：上/下周 |
| `t` | 回到今天 |
| `a` | 在光标日期新增任务（弹编辑表单） |
| `e` / `<CR>` | 编辑光标处任务（月视图若一格多任务，先用 `vim.ui.select` 选） |
| `x` | 切换完成状态 |
| `d` | 删除任务（`vim.ui.select` 确认） |
| `m` | 移动任务：`vim.ui.input` 输入日期 |
| `w` / `M` | 切到周视图（含光标日）/ 回月视图 |
| `q` / `<Esc>` | 关闭 |

## 错误处理

- 文件不存在：首次打开视为空列表；首次保存时创建（含父目录）
- 文件被外部修改：保存前比较 mtime，冲突时 `vim.ui.select` 提示 覆盖/放弃重载
- 解析失败行不丢弃，保留于 `(unparsed)` 节

## 测试

- `parser.lua`、`util.lua` 纯函数测试：`nvim -l tests/todo/parser_spec.lua` 无头运行，自写简易断言（失败打印并退出码非 0）
- 覆盖：空文件、单任务全字段、多任务多日期、备注多行、往返一致（parse→serialize→parse 等价）、非法行容错、中文宽度截断、月末/闰年日期计算
- UI 层手动验证（打开/切换/增删改/移动/重启加载）

---

## 附录 A（2026-07-29）：notify 层级修复 / 性能优化 / 侧边栏

### A.1 浮窗 zindex（bug 修复）

- 背景：nvim-notify 弹窗不显式设置 zindex（默认 50），与日历浮窗同值时被按创建顺序压在下方，导致 todo 打开期间通知不可见
- 日历浮窗与侧边栏浮窗 `zindex = 40`；表单浮窗显式 `zindex = 50`（同时保证表单始终在日历之上）

### A.2 性能优化

- **渲染与键位分离**：`view.attach(ctx)`（注册键位）仅在打开/切换视图时执行；`view.render(ctx)` 每次刷新执行
- **光标快速通道**：月/周视图中 `h/j/k/l` 未越出当前网格范围时，只删除并重建光标高亮 extmark（约 14 次 API 调用），不重写 buffer 文本；跨月/翻页/数据变化仍走全量渲染
- **渲染索引**：`store.by_date_map()` 每次渲染一次性构建 `date→tasks` 映射，取代逐格 `by_date` 的 O(42N) 查询

### A.3 侧边栏

- 新模块 `lua/todo/ui/sidebar.lua`；打开时与日历同时出现，左栏右历，两个等高血压浮窗；总宽仍由 `win.width` 决定，栏宽 `win.sidebar_width`（默认 34）
- 内容：仅未完成任务，按日期升序分组（过期任务在最前）；日期头格式 ` YYYY-MM-DD 星期X`，过期 `TodoCalPriHigh`、今天 `TodoCalToday`、其余 `TodoCalHeader`；任务行 = 分类色 `●` + 标题 + 优先级标记；空态显示灰色 ` 没有未完成的任务`
- `state.focus = "calendar"|"sidebar"`；`Tab` 在两窗间切换焦点；`q`/`<Esc>` 在任一窗口关闭整个界面
- 侧边栏键位：`j/k` 任务间移动（选中行整行反色）；`<CR>` 日历光标跳到该任务日期（焦点留在侧边栏）；`a/e/x/d/m` 语义同日历（`x` 完成后任务即从栏中消失）；`a` 使用选中任务日期（无选中则今天）
- `state.side_sel_id` 记录选中任务 id，渲染时按 id 恢复选中，id 消失则回退到首个任务
- 动作复用 `actions.edit_task/toggle_task/remove_task/move_task`；新增 `actions.jump_to_date(date)` 与 `actions.focus_toggle()`

### A.4 周期性任务（2026-07-29）

- 数据：任务行尾新增 `@every <周期>` 令牌，语法 `day | week | month | Nd | Nw | Nm`（N≥1 为自定义周期，如 `3d` 每 3 天、`2w` 每两周、`2m` 每两月）
- 数据模型：`task.cycle`（Lua 关键字 `repeat` 不可用作字段名）；`util.normalize_cycle(v)` 校验语法，`util.next_occurrence(date, cycle)` 计算下次日期（月末夹取到当月天数，闰年正确）
- 解析/序列化：剥离顺序自尾向首为 `!优先级` → `@分类` → `@every`；非法周期令牌不回剥（留在标题）
- 完成行为：`store.complete_and_spawn(id)` —— 当前实例标完成，同时在 `next_occurrence` 日期生成同标题/分类/优先级/备注/周期的未完成新实例；目标日期已有同标题同周期未完成实例则不生成（防止同日反复完成导致重复）
- 动作接入：`actions.toggle_task` 检测「未完成 + 有周期」时走 `complete_and_spawn`，否则普通 toggle
- UI：月历/周视图/侧边栏任务行显示 `↻` 标记（`util.cycle_mark`）；表单新增 `repeat` 字段行（第 6 行，备注顺延至第 7 行起），语法校验失败不关闭表单

### A.5 侧边栏底部命令栏与溢出（2026-07-29）

- 侧边栏底部固定展示常用命令速查（静态）：`a 新建 / e 编辑 / x 完成 / d 删除 / m 移期 / <CR> 跳转 / Tab 切窗 / q 关闭`，与内容区间用 `─` 分隔线
- 布局：内容区行数 = 窗口高 − 分隔线(1) − 命令栏(3) − 溢出槽(1)；命令栏后空行补齐到窗口高度，保证命令栏始终钉在窗口底部
- 任务超出内容区时在最后一行显示 ` +N`（`TodoCalOverflow`）
- `todo.open()` 增加孤儿窗口防护：日历已关但侧边栏残留（如 `<C-w>q` 手动关日历）时先关闭残留窗口再重建
