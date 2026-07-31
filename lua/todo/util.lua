local M = {}

M.dow_names = { "星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日" }

-- 周期任务标记（月历/周视图/侧边栏共用）
M.cycle_mark = " ↻"

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

-- 周期性任务的下一次发生日期；cycle 语法：day|week|month|Nd|Nw|Nm，非法返回 nil
function M.next_occurrence(date, cycle)
  if cycle == "day" then return M.add_days(date, 1) end
  if cycle == "week" then return M.add_days(date, 7) end
  if cycle == "month" then
    local y, m, d = M.split_date(date)
    y, m = M.add_months(y, m, 1)
    d = math.min(d, M.days_in_month(y, m))
    return M.make_date(y, m, d)
  end
  local n, u
  if cycle then
    n, u = cycle:match("^(%d+)([dw])$")
  end
  if n and u == "d" then return M.add_days(date, tonumber(n)) end
  if n and u == "w" then return M.add_days(date, tonumber(n) * 7) end
  if cycle then
    n = cycle:match("^(%d+)m$")
  end
  if n then
    local y, m, d = M.split_date(date)
    y, m = M.add_months(y, m, tonumber(n))
    d = math.min(d, M.days_in_month(y, m))
    return M.make_date(y, m, d)
  end
  return nil
end

-- cycle 语法校验：返回规范化值或 nil
function M.normalize_cycle(v)
  if v == nil or v == "" then return nil end
  if v == "day" or v == "week" or v == "month" then return v end
  if v:match("^%d+[dwm]$") then return v end
  return nil
end

return M
