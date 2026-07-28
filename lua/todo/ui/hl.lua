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
