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

os.remove(tmp)
h.finish("store")
