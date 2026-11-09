local function run()
  vim.wait(1000, function() return package.loaded["conform"] ~= nil end)
  assert(vim.o.undofile and vim.o.signcolumn == "yes" and vim.o.scrolloff == 6)
  vim.cmd("edit lua/plugins/conform.lua")
  assert(vim.bo.filetype == "lua")
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "Lua Treesitter inactive")
  assert(vim.diagnostic.config().update_in_insert == false)

  vim.cmd("enew")
  vim.api.nvim_buf_set_name(0, "/tmp/nvim-experience-format.py")
  vim.bo.filetype = "python"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "import sys", "import os", "x=  1", "print(os.name,sys.version,x)" })
  local format_error
  require("conform").format({ async = false, timeout_ms = 5000 }, function(err) format_error = err end)
  assert(not format_error, tostring(format_error))
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(lines[1] == "import os" and lines[2] == "import sys", vim.inspect(lines))
  assert(vim.tbl_contains(lines, "x = 1"), vim.inspect(lines))
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "Python Treesitter inactive")
  vim.bo.modified = false

  for i = 1, 2 do
    vim.cmd("enew")
    vim.api.nvim_buf_set_name(0, "/tmp/nvim-experience-" .. i .. ".tex")
    vim.bo.filetype = "tex"
    assert(vim.fn.maparg(",ln", "n", false, true).buffer == 1, "TeX lint key missing")
  end
  vim.cmd("enew")
  vim.api.nvim_buf_set_name(0, "/tmp/nvim-experience.lean")
  vim.bo.filetype = "lean"
  require("lazy").load({ plugins = { "lean.nvim" } })
  assert(vim.g.lean_config.mappings == true)
  assert(vim.fn.maparg("<leader>fo", "n") ~= "")
  assert(vim.fn.maparg("<leader>fw", "n") ~= "")
  assert(vim.fn.maparg("<leader>fr", "n") ~= "")
  assert(vim.fn.maparg("<leader>ua", "n") ~= "")
  assert(vim.fn.maparg("<leader>xx", "n"):find("toggle"))
  local messages = vim.api.nvim_exec2("messages", { output = true }).output
  assert(not messages:find('require%("lean"%).setup'), messages)
  assert(not messages:find("Error executing"), messages)
  print("experience_smoke: startup, Lua/Python highlighting, Ruff, TeX buffers, Lean config and mappings passed")
end

local ok, err = xpcall(run, debug.traceback)
for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
if not ok then
  print(err)
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
