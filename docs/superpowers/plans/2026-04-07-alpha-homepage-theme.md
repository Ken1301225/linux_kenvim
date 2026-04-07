# Alpha Homepage Theme Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Switch the Neovim homepage to an Alpha theme that shows recent files immediately, opens `nvim-tree` when the homepage appears, and returns to the homepage when the last normal buffer is deleted.

**Architecture:** Keep the plugin layout unchanged and concentrate the homepage behavior inside `lua/plugins/alpha_nvim.lua`. Use Alpha's built-in `theta` MRU section instead of a button-triggered recent-files action, then add small local helpers and autocmds to coordinate homepage rendering and `nvim-tree` opening without changing unrelated plugin files.

**Tech Stack:** Neovim Lua, `goolord/alpha-nvim`, `nvim-tree.lua`

---

## Chunk 1: Homepage Theme And Tree Behavior

### Task 1: Replace the dashboard homepage with a theme that renders recent files

**Files:**
- Modify: `lua/plugins/alpha_nvim.lua`

- [ ] **Step 1: Inspect the current homepage plugin file**

Run: `sed -n '1,220p' lua/plugins/alpha_nvim.lua`
Expected: existing dashboard-style Alpha config with header, buttons, and footer

- [ ] **Step 2: Replace the dashboard setup with a `theta`-based setup**

Implementation details:
- require `alpha.themes.theta`
- keep the existing ASCII header
- keep quick links for file finding, new file, plugin management, quit, and config access
- remove the separate "Recent files" button because the theme will render recent files directly

- [ ] **Step 3: Add a helper that opens `nvim-tree` when Alpha is visible**

Implementation details:
- define a local helper in `lua/plugins/alpha_nvim.lua`
- schedule `NvimTreeOpen` so it runs after Alpha draws
- guard against re-opening if the current filetype is not `alpha`

- [ ] **Step 4: Save and review the file for syntax and event ordering**

Expected: theme config remains self-contained and uses only local helpers/autocmds

## Chunk 2: Return To Homepage After Last Buffer Delete

### Task 2: Detect when no normal file buffers remain and reopen Alpha

**Files:**
- Modify: `lua/plugins/alpha_nvim.lua`

- [ ] **Step 1: Add a helper that decides whether any normal listed editing buffers remain**

Implementation details:
- iterate `vim.api.nvim_list_bufs()`
- ignore invalid, unloaded, unlisted, special `buftype`, `alpha`, and `NvimTree` buffers

- [ ] **Step 2: Add an autocmd that reopens Alpha when the last normal buffer disappears**

Implementation details:
- trigger from `BufDelete` and schedule the actual check
- if no normal buffers remain, run `Alpha`
- immediately reuse the same helper that opens `nvim-tree`
- guard against recursion when Alpha is already shown

- [ ] **Step 3: Keep the behavior generic**

Expected: it works for `:bdelete`, `<leader>bd`, and other flows that delete the last normal buffer

## Chunk 3: Verification

### Task 3: Run non-interactive validation

**Files:**
- Test: `lua/plugins/alpha_nvim.lua`

- [ ] **Step 1: Run a headless Neovim startup check**

Run: `nvim --headless "+Lazy! load alpha-nvim nvim-tree.lua" "+qa"`
Expected: exit code 0

- [ ] **Step 2: Run a Lua syntax parse on the modified plugin file**

Run: `luac -p lua/plugins/alpha_nvim.lua`
Expected: exit code 0
