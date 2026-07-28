local passed, failed = 0, 0

local function eq(actual, expected, label)
    if vim.deep_equal(actual, expected) then
        passed = passed + 1
    else
        failed = failed + 1
        print(string.format("FAIL %s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(actual)))
    end
end

local before = #vim.api.nvim_get_autocmds({event = "BufEnter", pattern = "copilot-*"})
dofile("lua/plugins/copilotChat.lua")
local after = #vim.api.nvim_get_autocmds({event = "BufEnter", pattern = "copilot-*"})
eq(after, before, "disabled CopilotChat has no autocmd side effect")

local runs = 0
local original_input = vim.ui.input
vim.ui.input = function(_, callback)
    callback(nil)
end
package.loaded["code_runner.commands"] = {
    run_from_fn = function()
        runs = runs + 1
    end,
}

local runner = dofile("lua/plugins/coderunner.lua")
_G.c_base, _G.cpp_base = nil, nil
runner.opts.filetype.c()
runner.opts.filetype.cpp()
eq(runs, 0, "cancelled runner does not execute")
eq(_G.c_base, nil, "C runner does not create a global")
eq(_G.cpp_base, nil, "C++ runner does not create a global")

vim.ui.input = original_input
package.loaded["code_runner.commands"] = nil

local trouble_source = table.concat(vim.fn.readfile("lua/plugins/trouble.lua"), "\n")
eq(trouble_source:find("use_diagnostic_signs%s*=%s*true") ~= nil, true, "Trouble supported sign option")
eq(trouble_source:find("use_lsp_diagnostic_signs") == nil, true, "Trouble obsolete option removed")

print(string.format("plugin_specs: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
