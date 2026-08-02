# Todo Form Empty Notes Line Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the visible `notes:` area immediately editable for tasks whose notes are empty.

**Architecture:** Preserve the six value lines and the virtual `notes:` label, but ensure an empty real buffer line always follows them. Keep parsing and persistence unchanged because the existing parser already trims trailing empty note lines.

**Tech Stack:** Lua, Neovim 0.12 buffer/window APIs, the repository's headless Lua test helper

## Global Constraints

- Keep field labels and `notes:` as non-editable virtual text.
- Do not change form layout, parsing rules, key mappings, validation, or Markdown storage format.
- An untouched empty notes line must save as `notes = ""`.
- Existing one-line and multiline notes must retain their current behavior.

---

### Task 1: Create An Editable Line For Empty Notes

**Files:**
- Modify: `tests/todo/form_spec.lua:30`
- Modify: `lua/todo/ui/form.lua:80`

**Interfaces:**
- Consumes: `task.notes`, `vim.api.nvim_win_set_cursor()`, `vim.api.nvim_buf_set_text()`, and the existing positional `parse_form()` behavior that reads notes from line seven.
- Produces: A todo form buffer with at least seven real lines and an empty line seven whenever `task.notes` is empty or nil.

- [ ] **Step 1: Write the failing behavioral regression test**

Retain the first form window, then assert the empty notes row can be reached and written:

```lua
local buf, win, get = open_form({ title = "", date = "2026-07-15", category = nil,
  priority = "medium", done = false, notes = "" })
local lines = all_lines(buf)
h.eq(lines[1], "", "第 1 行是纯 title 值（无标签）")
h.eq(lines[2], "2026-07-15", "第 2 行是纯 date 值")
h.eq(lines[4], "medium", "第 4 行是纯 priority 值")
h.eq(lines[7], "", "空 notes 仍创建第 7 行")
local notes_cursor_ok = pcall(vim.api.nvim_win_set_cursor, win, { 7, 0 })
h.eq(notes_cursor_ok, true, "光标可进入空 notes 行")
local notes_write_ok = pcall(vim.api.nvim_buf_set_text, buf, 6, 0, 6, 0, { "新备注" })
h.eq(notes_write_ok, true, "空 notes 行可写入")
```

After the existing `<C-s>` save assertions for this form, verify entered notes were parsed:

```lua
h.eq(get() and get().notes, "新备注", "空 notes 行输入后保存")
```

After the existing multiline notes round-trip test, open and save one untouched empty-notes form:

```lua
local empty_buf, _, get_empty = open_form({ title = "空备注", date = "2026-07-15", category = nil,
  priority = "medium", done = false, notes = "" })
press(empty_buf, "n", "<CR>")
h.eq(get_empty() and get_empty().notes, "", "未填写 notes 仍保存为空字符串")
```

- [ ] **Step 2: Run the focused test and verify the expected failure**

Run from the repository root:

```bash
nvim --clean --headless -u NONE -l tests/todo/form_spec.lua
```

Expected: exit code `1` and four failures showing that line seven is `nil`, cursor movement and text insertion return `false`, and the saved notes value is empty instead of `新备注`. The untouched-empty assertion still passes.

- [ ] **Step 3: Implement the minimal empty-line fix**

Add only an `else` branch to the existing notes initialization in `lua/todo/ui/form.lua`:

```lua
if task.notes and task.notes ~= "" then
  for _, l in ipairs(split_lines(task.notes)) do
    lines[#lines + 1] = l
  end
else
  lines[#lines + 1] = ""
end
```

- [ ] **Step 4: Run the focused test and verify it passes**

Run:

```bash
nvim --clean --headless -u NONE -l tests/todo/form_spec.lua
```

Expected: exit code `0` and `form: 25 passed, 0 failed`.

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
git add tests/todo/form_spec.lua lua/todo/ui/form.lua docs/superpowers/plans/2026-08-02-todo-form-empty-notes-line.md
git commit -m "fix(todo): make empty notes line editable"
```
