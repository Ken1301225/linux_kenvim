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
