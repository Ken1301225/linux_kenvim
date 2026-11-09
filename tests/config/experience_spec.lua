local passed, failed = 0, 0
local function check(value, label)
  if value then
    passed = passed + 1
  else
    failed = failed + 1
    print("FAIL " .. label)
  end
end

vim.g.mapleader = " "
vim.g.maplocalleader = ","
local tex = dofile("lua/plugins/vimtex.lua")
tex.init()
tex.config()
for i = 1, 2 do
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo.filetype = "tex"
  vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
  check(vim.fn.maparg(",ln", "n", false, true).buffer == 1, "lint mapping in TeX buffer " .. i)
end
vim.fn.setqflist({ { text = "Compilation failed", lnum = 1, bufnr = vim.api.nvim_get_current_buf() } })
vim.cmd("copen")
vim.api.nvim_exec_autocmds("User", { pattern = "VimtexEventCompileFailed" })
vim.wait(100, function() return false end)
check(vim.fn.getqflist({ winid = 0 }).winid ~= 0, "compile failure keeps quickfix visible")
vim.cmd("cclose")

-- Control the external process boundary to test caching without launching a viewer.
local original_executable, original_system, original_open = vim.fn.executable, vim.system, io.open
local geometry_file = vim.fn.tempname()
vim.fn.writefile({ "set window-width 100", "set window-height 100" }, geometry_file)
local launches, completed = 0, nil
vim.fn.executable = function(name)
  if name == "powershell.exe" then return 1 end
  return original_executable(name)
end
vim.system = function(_, opts, callback)
  launches = launches + 1
  check(opts.timeout == 5000, "screen detection has a timeout")
  completed = callback
end
io.open = function(path, mode)
  if path == vim.fn.expand("~/.config/zathura/zathurarc") then path = geometry_file end
  return original_open(path, mode)
end
vim.api.nvim_exec_autocmds("User", { pattern = "VimtexEventCompileSuccess" })
vim.api.nvim_exec_autocmds("User", { pattern = "VimtexEventView" })
check(launches == 1, "screen detection runs once across compile and view")
completed({ code = 0, stdout = '{"Width":1920,"Height":1080}' })
vim.wait(100, function() return vim.fn.readfile(geometry_file)[1] == "set window-width 720" end)
check(vim.deep_equal(vim.fn.readfile(geometry_file), {
  "set window-width 720", "set window-height 1080",
}), "screen result sets viewer dimensions")
vim.fn.executable, vim.system, io.open = original_executable, original_system, original_open
vim.fn.delete(geometry_file)

local conform = dofile("lua/plugins/conform.lua")
if type(conform.opts.formatters_by_ft.python) == "function" then
  local python = conform.opts.formatters_by_ft.python
  check(vim.deep_equal(python(0), { "ruff_organize_imports", "ruff_format" }), "default Python uses Ruff")
  vim.b.python_formatter = "black"
  check(vim.deep_equal(python(0), { "isort", "black" }), "buffer can retain Black")
  vim.b.python_formatter = nil
  vim.g.python_formatter = "black"
  check(vim.deep_equal(python(0), { "isort", "black" }), "project can retain Black")
  vim.g.python_formatter = nil
else
  check(false, "Python formatter supports project override")
end
if conform.config then
  vim.bo.filetype = "python" -- Exercise the default-on formatting toggle independently of TeX.
  vim.opt.rtp:append("/home/ken/.local/share/nvim/lazy/conform.nvim")
  conform.config(nil, conform.opts)
  vim.cmd("FormatToggle")
  check(conform.opts.format_on_save(vim.api.nvim_get_current_buf()) == nil, "buffer toggle disables save formatting")
  vim.cmd("FormatToggle")
  check(conform.opts.format_on_save(vim.api.nvim_get_current_buf()) ~= nil, "buffer toggle restores save formatting")
  vim.cmd("FormatToggle!")
  check(conform.opts.format_on_save(vim.api.nvim_get_current_buf()) == nil, "global toggle disables save formatting")
  vim.cmd("FormatToggle!")
else
  check(false, "format toggle is configured")
end

print(string.format("experience_spec: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
