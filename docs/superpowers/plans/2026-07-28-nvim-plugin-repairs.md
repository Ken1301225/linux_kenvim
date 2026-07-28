# Neovim Plugin Repairs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair the confirmed Neovim configuration defects while preserving the current plugin set and key layout.

**Architecture:** Keep each correction in its existing owner module. Add a headless Lua regression script that loads real plugin specs and inspects runtime autocmds, mappings, lazy-loading contracts, and cancelled runner behavior; use runtime smoke checks for integration behavior that depends on lazy.nvim.

**Tech Stack:** Neovim 0.12.4 Lua API, lazy.nvim 11.17.5, Conda Python 3.13.

**Spec:** `docs/superpowers/specs/2026-07-28-nvim-plugin-repairs-design.md`

## Global Constraints

- Do not add, remove, or replace a Neovim plugin.
- Preserve all existing leader-key bindings and workflows.
- Use native Neovim mappings for tmux window handoff.
- Use the installed `zathura` for PDFs and `xdg-open` as the available image-viewer fallback.
- Run tests from `/home/ken/.config/nvim`.
- Do not alter the optional Java, Deno, Node provider, Perl provider, or LuaSnip `jsregexp` environment.

---

### Task 1: External Viewers And Window Navigation

**Files:**
- Create: `tests/config/basic_spec.lua`
- Modify: `lua/config/basic.lua`
- Modify: `lua/config/keymap.lua`

**Interfaces:**
- Produces: one `BufReadPost` handler per supported external file pattern.
- Produces: normal-mode `<C-h>`, `<C-j>`, `<C-k>`, and `<C-l>` mappings to adjacent windows.

- [ ] **Step 1: Write the failing runtime test**

Create `tests/config/basic_spec.lua`:

```lua
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
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
nvim --clean -l tests/config/basic_spec.lua
```

Expected: non-zero exit; PDF count is `2`, and `<C-h/j/k>` mappings are absent.

- [ ] **Step 3: Implement a single guarded external-opener helper**

Replace the two viewer autocmd blocks in `lua/config/basic.lua` with:

```lua
local function first_executable(candidates)
  for _, candidate in ipairs(candidates) do
    local executable = vim.fn.exepath(candidate)
    if executable ~= "" then
      return executable
    end
  end
end

local function register_external_opener(patterns, candidates)
  local executable = first_executable(candidates)
  if not executable then
    return
  end

  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = patterns,
    callback = function(args)
      local file = vim.api.nvim_buf_get_name(args.buf)
      vim.fn.jobstart({ executable, file }, { detach = true })
      vim.api.nvim_buf_delete(args.buf, { force = true })
    end,
  })
end

register_external_opener({ "*.png", "*.jpg", "*.jpeg", "*.bmp", "*.gif" }, { "feh", "imv", "xdg-open" })
register_external_opener({ "*.pdf" }, { "zathura" })
```

- [ ] **Step 4: Add native Neovim window mappings**

Append to `lua/config/keymap.lua`:

```lua
for _, direction in ipairs({ "h", "j", "k", "l" }) do
  vim.keymap.set("n", "<C-" .. direction .. ">", "<Cmd>wincmd " .. direction .. "<CR>", {
    silent = true,
    desc = "Move to " .. direction .. " window",
  })
end
```

- [ ] **Step 5: Run the test and verify GREEN**

Run: `nvim --clean -l tests/config/basic_spec.lua`

Expected: `basic_spec: 6 passed, 0 failed`, exit code 0.

- [ ] **Step 6: Commit Task 1**

```bash
git add tests/config/basic_spec.lua lua/config/basic.lua lua/config/keymap.lua
git commit -m "fix: repair external viewers and tmux navigation"
```

---

### Task 2: DAP, Mason, And lazy.nvim Loading Boundaries

**Files:**
- Create: `tests/config/lazy_specs.lua`
- Modify: `lua/plugins/cppdap.lua`
- Modify: `lua/plugins/mason.lua`
- Modify: `lua/config/lazy.lua`

**Interfaces:**
- Produces: `nvim-dap-python` as an explicitly lazy dependency.
- Produces: Mason loading on `BufReadPre`, `BufNewFile`, or `:Mason`.
- Produces: lazy.nvim with LuaRocks integration disabled.

- [ ] **Step 1: Write the failing specification test**

Create `tests/config/lazy_specs.lua`:

```lua
local failed = 0
local function eq(actual, expected, label)
  if vim.deep_equal(actual, expected) then return end
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
eq(mason.event, { "BufReadPre", "BufNewFile" }, "Mason file events")
eq(mason.cmd, "Mason", "Mason command trigger")

local lazy_source = table.concat(vim.fn.readfile("lua/config/lazy.lua"), "\n")
eq(lazy_source:find("rocks%s*=%s*{%s*enabled%s*=%s*false") ~= nil, true, "LuaRocks disabled")

print(string.format("lazy_specs: %d failed", failed))
os.exit(failed == 0 and 0 or 1)
```

- [ ] **Step 2: Run the test and verify RED**

Run: `nvim --clean -l tests/config/lazy_specs.lua`

Expected: non-zero exit with failures for all three loading contracts.

- [ ] **Step 3: Make nvim-dap-python explicitly lazy**

In its dependency table in `lua/plugins/cppdap.lua`, add:

```lua
lazy = true,
```

- [ ] **Step 4: Add Mason loading triggers**

Add beside the Mason plugin name in `lua/plugins/mason.lua`:

```lua
event = { "BufReadPre", "BufNewFile" },
cmd = "Mason",
```

- [ ] **Step 5: Disable unused LuaRocks support**

Extend `require("lazy").setup` in `lua/config/lazy.lua`:

```lua
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  rocks = {
    enabled = false,
  },
})
```

- [ ] **Step 6: Run unit and runtime loading checks**

Run:

```bash
nvim --clean -l tests/config/lazy_specs.lua
nvim --headless --cmd "set runtimepath^=/home/ken/.config/nvim/.worktrees/nvim-plugin-repairs" -u /home/ken/.config/nvim/.worktrees/nvim-plugin-repairs/init.lua "+lua local c=require('lazy.core.config').plugins; assert(not c['nvim-dap']._.loaded); assert(not c['nvim-dap-python']._.loaded)" +qa
```

Expected: `lazy_specs: 0 failed`; both runtime assertions exit 0.

- [ ] **Step 7: Commit Task 2**

```bash
git add tests/config/lazy_specs.lua lua/plugins/cppdap.lua lua/plugins/mason.lua lua/config/lazy.lua
git commit -m "perf: defer DAP and Mason initialization"
```

---

### Task 3: Correct Disabled And Outdated Plugin Configuration

**Files:**
- Create: `tests/config/plugin_specs.lua`
- Modify: `lua/plugins/copilotChat.lua`
- Modify: `lua/plugins/coderunner.lua`
- Modify: `lua/plugins/trouble.lua`

**Interfaces:**
- Produces: loading the disabled CopilotChat spec has no autocmd side effects.
- Produces: cancelling a C/C++ argument prompt does not invoke code_runner.
- Produces: Trouble uses `use_diagnostic_signs`.

- [ ] **Step 1: Write the failing behavior test**

Create `tests/config/plugin_specs.lua`:

```lua
local passed, failed = 0, 0
local function eq(actual, expected, label)
  if vim.deep_equal(actual, expected) then
    passed = passed + 1
  else
    failed = failed + 1
    print(string.format("FAIL %s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(actual)))
  end
end

local before = #vim.api.nvim_get_autocmds({ event = "BufEnter", pattern = "copilot-*" })
dofile("lua/plugins/copilotChat.lua")
local after = #vim.api.nvim_get_autocmds({ event = "BufEnter", pattern = "copilot-*" })
eq(after, before, "disabled CopilotChat has no autocmd side effect")

local runs = 0
local original_input = vim.ui.input
vim.ui.input = function(_, callback) callback(nil) end
package.loaded["code_runner.commands"] = { run_from_fn = function() runs = runs + 1 end }

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
```

- [ ] **Step 2: Run the test and verify RED**

Run: `nvim --clean -l tests/config/plugin_specs.lua`

Expected: non-zero exit for CopilotChat side effects, cancelled runner execution/globals, and Trouble's old option.

- [ ] **Step 3: Remove the disabled CopilotChat side effect**

Delete the `vim.api.nvim_create_autocmd(...)` expression from the `opts` table in `lua/plugins/copilotChat.lua`. Do not add a replacement while the plugin remains disabled.

- [ ] **Step 4: Localize runner command tables and stop on cancellation**

In both C and C++ runner functions, declare their command table with `local` and begin each input callback with:

```lua
if input == nil then
  return
end
```

- [ ] **Step 5: Replace Trouble's obsolete option**

Change:

```lua
use_lsp_diagnostic_signs = true,
```

to:

```lua
use_diagnostic_signs = true,
```

- [ ] **Step 6: Run the test and verify GREEN**

Run: `nvim --clean -l tests/config/plugin_specs.lua`

Expected: `plugin_specs: 6 passed, 0 failed`, exit code 0.

- [ ] **Step 7: Commit Task 3**

```bash
git add tests/config/plugin_specs.lua lua/plugins/copilotChat.lua lua/plugins/coderunner.lua lua/plugins/trouble.lua
git commit -m "fix: correct plugin configuration side effects"
```

---

### Task 4: Python Provider And Full Verification

**Files:**
- Environment: `/home/ken/miniconda3` Python installation
- Verify only: all modified files and existing Todo tests

**Interfaces:**
- Produces: `import pynvim` succeeds in the configured Python provider.

- [ ] **Step 1: Verify the provider currently fails**

Run:

```bash
/home/ken/miniconda3/bin/python -c "import pynvim"
```

Expected before installation: `ModuleNotFoundError: No module named 'pynvim'`.

- [ ] **Step 2: Install pynvim into the configured interpreter**

Run:

```bash
/home/ken/miniconda3/bin/python -m pip install pynvim
```

Expected: successful installation into `/home/ken/miniconda3`.

- [ ] **Step 3: Verify the provider import**

Run:

```bash
/home/ken/miniconda3/bin/python -c "import pynvim; print(pynvim.__file__)"
```

Expected: exit 0 and a path under `/home/ken/miniconda3`.

- [ ] **Step 4: Run all configuration and existing tests**

Run:

```bash
nvim --clean -l tests/config/basic_spec.lua
nvim --clean -l tests/config/lazy_specs.lua
nvim --clean -l tests/config/plugin_specs.lua
nvim --clean -l tests/todo/util_spec.lua
nvim --clean -l tests/todo/parser_spec.lua
nvim --clean -l tests/todo/store_spec.lua
nvim --clean -l tests/todo/ui_smoke.lua
```

Expected: every process exits 0 with zero failed assertions.

- [ ] **Step 5: Run startup and integration smoke checks**

Run:

```bash
nvim --headless --cmd "set runtimepath^=/home/ken/.config/nvim/.worktrees/nvim-plugin-repairs" -u /home/ken/.config/nvim/.worktrees/nvim-plugin-repairs/init.lua +qa
nvim --headless --cmd "set runtimepath^=/home/ken/.config/nvim/.worktrees/nvim-plugin-repairs" -u /home/ken/.config/nvim/.worktrees/nvim-plugin-repairs/init.lua --startuptime /tmp/nvim-repaired-startup.log +qa
nvim --headless --cmd "set runtimepath^=/home/ken/.config/nvim/.worktrees/nvim-plugin-repairs" -u /home/ken/.config/nvim/.worktrees/nvim-plugin-repairs/init.lua "+lua local c=require('lazy.core.config').plugins; assert(not c['nvim-dap']._.loaded); assert(not c['nvim-dap-python']._.loaded)" +qa
nvim --headless --cmd "set runtimepath^=/home/ken/.config/nvim/.worktrees/nvim-plugin-repairs" -u /home/ken/.config/nvim/.worktrees/nvim-plugin-repairs/init.lua "+checkhealth" "+w! /tmp/nvim-repaired-health.txt" +qa
```

Expected: all commands exit 0; DAP assertions pass; health output has no Python provider or lazy.nvim LuaRocks error.

- [ ] **Step 6: Verify health output and repository state**

Run:

```bash
rg -n "ERROR|use_lsp_diagnostic_signs|ModuleNotFoundError" /tmp/nvim-repaired-health.txt lua tests/config
git diff --check
git status --short
```

Expected: no relevant error matches, no whitespace errors, and only intentional changes remain.

- [ ] **Step 7: Record environment verification**

No repository commit is required for the Python package installation. Record the installed `pynvim` path and measured startup time in the final handoff.
