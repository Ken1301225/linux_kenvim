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
