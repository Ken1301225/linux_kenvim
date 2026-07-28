local passed, failed = 0, 0

local function eq(actual, expected, label)
  if vim.deep_equal(actual, expected) then
    passed = passed + 1
  else
    failed = failed + 1
    print(string.format("FAIL %s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(actual)))
  end
end

dofile("lua/config/basic.lua")
dofile("lua/config/keymap.lua")

local autocmds = vim.api.nvim_get_autocmds({ event = "BufReadPost" })
local patterns = {}
for _, autocmd in ipairs(autocmds) do
  patterns[autocmd.pattern] = (patterns[autocmd.pattern] or 0) + 1
end

eq(patterns["*.pdf"], 1, "PDF has exactly one opener")
eq(patterns["*.png"], 1, "PNG has an available opener")

for _, direction in ipairs({ "h", "j", "k", "l" }) do
  local mapping = vim.fn.maparg("<C-" .. direction .. ">", "n", false, true)
  eq(mapping.rhs, "<Cmd>wincmd " .. direction .. "<CR>", "normal Ctrl-" .. direction)
end

print(string.format("basic_spec: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
