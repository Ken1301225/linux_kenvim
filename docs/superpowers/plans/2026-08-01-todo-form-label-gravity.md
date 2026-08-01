# Todo Form Label Gravity Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep every inline todo form label fixed on the left when text is inserted at column zero.

**Architecture:** Preserve the existing value-only form buffer and inline virtual-text labels. Change only the field-label extmark gravity, with a behavioral regression test that exercises Neovim's real extmark update semantics.

**Tech Stack:** Lua, Neovim 0.12 extmark API, the repository's headless Lua test helper

## Global Constraints

- Do not change form layout, parsing, key mappings, validation, or storage format.
- Apply the gravity option only to the six inline field-label extmarks; leave the `notes:` virtual line unchanged.
- Work from `/home/ken/.config/nvim/.worktrees/fix-todo-form-label-gravity` when running commands.

---

### Task 1: Pin Inline Form Labels To Column Zero

**Files:**
- Modify: `tests/todo/form_spec.lua:43`
- Modify: `lua/todo/ui/form.lua:90`

**Interfaces:**
- Consumes: `vim.api.nvim_buf_set_extmark()` and `vim.api.nvim_buf_get_extmark_by_id()` from Neovim.
- Produces: Inline label extmarks whose start position stays at column zero when buffer text is inserted at the same position.

- [ ] **Step 1: Write the failing behavioral regression test**

Replace the label lookup block in `tests/todo/form_spec.lua` with a lookup that retains the title label's namespace and id, then insert text at column zero and assert that the mark does not move:

```lua
-- 2. 标签以 inline 虚拟文本存在，且输入不会把标签推到值后面
local label_found = false
local title_label_ns, title_label_id
for _, ns_id in pairs(vim.api.nvim_get_namespaces()) do
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns_id, 0, -1, { details = true })) do
    local vt = m[4].virt_text
    if vt and vt[1] and vt[1][1] and vt[1][1]:find("title:") and m[4].virt_text_pos == "inline" then
      label_found = true
      title_label_ns = ns_id
      title_label_id = m[1]
    end
  end
end
h.eq(label_found, true, "title 标签为 inline 虚拟文本")

vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, { "新任务" })
local title_mark = vim.api.nvim_buf_get_extmark_by_id(buf, title_label_ns, title_label_id, {})
h.eq(title_mark[2], 0, "输入后 title 标签仍锚定第 0 列")
h.eq(all_lines(buf)[1], "新任务", "输入内容只写入 title 值")
```

- [ ] **Step 2: Run the focused test and verify the expected failure**

Run:

```bash
nvim --clean --headless -u NONE -l tests/todo/form_spec.lua
```

Expected: exit code `1`, with the assertion `输入后 title 标签仍锚定第 0 列` reporting `expected: 0` and `actual: 9` (`新任务` occupies 9 UTF-8 bytes).

- [ ] **Step 3: Implement the minimal gravity fix**

Add `right_gravity = false` only to the inline field-label extmark options in `lua/todo/ui/form.lua`:

```lua
vim.api.nvim_buf_set_extmark(buf, label_ns, i - 1, 0, {
  virt_text = { { LABELS[i], "TodoCalOtherMonth" } },
  virt_text_pos = "inline",
  right_gravity = false,
})
```

- [ ] **Step 4: Run the focused test and verify it passes**

Run:

```bash
nvim --clean --headless -u NONE -l tests/todo/form_spec.lua
```

Expected: exit code `0` and `form: 20 passed, 0 failed`.

- [ ] **Step 5: Run the complete todo test suite**

Run each command from the repository root:

```bash
nvim --clean --headless -u NONE -l tests/todo/util_spec.lua
nvim --clean --headless -u NONE -l tests/todo/parser_spec.lua
nvim --clean --headless -u NONE -l tests/todo/store_spec.lua
nvim --clean --headless -u NONE -l tests/todo/form_spec.lua
nvim --clean --headless -u NONE -l tests/todo/ui_smoke.lua
```

Expected: every command exits `0`, and every final summary reports `0 failed`.

- [ ] **Step 6: Commit the tested fix**

```bash
git add tests/todo/form_spec.lua lua/todo/ui/form.lua docs/superpowers/plans/2026-08-01-todo-form-label-gravity.md
git commit -m "fix(todo): keep form labels before input"
```
