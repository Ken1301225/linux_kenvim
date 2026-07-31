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
  -- 尾部元数据（自尾向首）：!优先级 -> @分类 -> @every 周期（与 serialize 输出顺序对应）
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
  local cyc = rest:match("@every%s+(%S+)%s*$")
  if cyc and util.normalize_cycle(cyc) then
    task.cycle = cyc
    rest = rest:gsub("%s*@every%s+%S+%s*$", "")
  end
  task.title = trim(rest)
  return task
end

-- parse(content) -> tasks(array), unparsed(array of string)
function M.parse(content)
  -- 去掉末尾换行，避免下面迭代时产生幻影空行（空行在 unparsed 中会被保留，导致往返膨胀）
  if content:sub(-1) == "\n" then
    content = content:sub(1, -2)
  end
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
  if t.cycle then
    parts[#parts + 1] = " @every " .. t.cycle
  end
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
