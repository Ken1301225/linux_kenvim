local failed = 0

local function eq(actual, expected, label)
    if vim.deep_equal(actual, expected) then
        return
    end
    failed = failed + 1
    print(string.format("FAIL %s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(actual)))
end

local dap = dofile("lua/plugins/cppdap.lua")
local dap_python
for _, dependency in ipairs(dap.dependencies) do
    if type(dependency) == "table" and dependency[1] == "mfussenegger/nvim-dap-python" then
        dap_python = dependency
    end
end
eq(dap_python and dap_python.lazy, true, "nvim-dap-python is lazy")

local mason = dofile("lua/plugins/mason.lua")
eq(mason.event, {"BufReadPre", "BufNewFile"}, "Mason file events")
eq(mason.cmd, "Mason", "Mason command trigger")

local lazy_source = table.concat(vim.fn.readfile("lua/config/lazy.lua"), "\n")
eq(lazy_source:find("rocks%s*=%s*{%s*enabled%s*=%s*false") ~= nil, true, "LuaRocks disabled")

print(string.format("lazy_specs: %d failed", failed))
os.exit(failed == 0 and 0 or 1)
