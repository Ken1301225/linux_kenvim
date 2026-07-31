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

-- by_date_map
store.add({ title = "甲", date = "2026-07-01", priority = "medium", done = false, notes = "" })
store.add({ title = "乙", date = "2026-07-01", priority = "medium", done = false, notes = "" })
store.add({ title = "丙", date = "2026-07-02", priority = "medium", done = false, notes = "" })
local dm = store.by_date_map()
h.eq(#dm["2026-07-01"], 2, "by_date_map 同日两个")
h.eq(dm["2026-07-02"][1].title, "丙", "by_date_map 内容")

-- 周期任务完成：生成下一个实例
store.add({ title = "每周健身", date = "2026-07-28", category = "nlp",
  priority = "high", done = false, notes = "备注", cycle = "week" })
local ok5, err5 = store.complete_and_spawn("2026-07-28-1")
h.eq(ok5, true, "complete_and_spawn 成功")
h.eq(err5, nil, "无错误")
h.eq(store.tasks[4].done, true, "原实例完成")
h.eq(#store.tasks, 5, "生成新实例后共 5 个（甲乙丙+原实例+新实例）")
local spawned = store.by_date("2026-08-04")[1]
h.eq(spawned ~= nil, true, "下周同日期生成新实例")
h.eq(spawned.done, false, "新实例未完成")
h.eq(spawned.cycle, "week", "新实例保留周期")
h.eq(spawned.title, "每周健身", "新实例同标题")
h.eq(spawned.notes, "备注", "新实例保留备注")
-- 目标日期已有未完成实例则不重复生成：07-28 改回未完成再完成
store.tasks[4].done = false
local ok6 = store.complete_and_spawn("2026-07-28-1")
h.eq(ok6, true, "再完成一次成功")
h.eq(#store.tasks, 5, "下个日期已有未完成实例时不重复生成")
-- 非周期任务走普通 toggle 语义（complete_and_spawn 也安全）
store.add({ title = "普通", date = "2026-07-10", priority = "medium", done = false, notes = "" })
local ok7 = store.complete_and_spawn("2026-07-10-1")
h.eq(ok7, true, "非周期任务 complete_and_spawn 安全")
h.eq(store.by_date("2026-07-10")[1].done, true, "非周期任务完成")

os.remove(tmp)
h.finish("store")
