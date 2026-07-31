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

-- 7. 周期任务 @every
local t7 = parser.parse("## 2026-07-28\n- [ ] 每周健身 @every week @nlp !high\n- [ ] 每 3 天吃药 @every 3d\n")
h.eq(t7[1].cycle, "week", "解析 @every week")
h.eq(t7[1].category, "nlp", "@every 与 @分类共存")
h.eq(t7[1].priority, "high", "@every 与 !优先级共存")
h.eq(t7[1].title, "每周健身", "@every 从标题剥离")
h.eq(t7[2].cycle, "3d", "解析 @every 3d")
-- 序列化往返
local t8, u8 = parser.parse(parser.serialize(t7, {}))
h.eq(t8[1].cycle, "week", "周期往返一致")
h.eq(t8[1].title, "每周健身", "周期任务标题往返")
-- 非法周期不回剥（留在标题里）
local t9 = parser.parse("## 2026-07-28\n- [ ] 看 @every 特价\n")
h.eq(t9[1].cycle, nil, "非法 @every 不解析")
h.eq(t9[1].title, "看 @every 特价", "非法 @every 留在标题")

h.finish("parser")
