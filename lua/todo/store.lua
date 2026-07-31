local parser = require("todo.parser")
local util = require("todo.util")

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

-- 完成周期任务：标记完成并在下个周期日期生成新未完成实例（目标日期已有同标题同周期未完成实例则不生成）
function M.complete_and_spawn(id)
  local t = M.find(id)
  if not t then return false, "not found" end
  t.done = true
  if t.cycle then
    local next_date = util.next_occurrence(t.date, t.cycle)
    if next_date then
      local dup = false
      for _, o in ipairs(M.tasks) do
        if o ~= t and not o.done and o.date == next_date and o.title == t.title and o.cycle == t.cycle then
          dup = true
          break
        end
      end
      if not dup then
        M.tasks[#M.tasks + 1] = {
          title = t.title,
          date = next_date,
          category = t.category,
          priority = t.priority,
          done = false,
          notes = t.notes,
          cycle = t.cycle,
        }
      end
    end
  end
  derive_ids()
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

-- 一遍构建 date -> tasks 映射（渲染用，任务保持文件顺序）
function M.by_date_map()
  local map = {}
  for _, t in ipairs(M.tasks) do
    if not map[t.date] then map[t.date] = {} end
    map[t.date][#map[t.date] + 1] = t
  end
  return map
end

return M
