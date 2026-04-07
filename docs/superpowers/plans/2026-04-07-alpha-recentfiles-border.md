# Alpha Recent Files Border Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an ASCII box border around the `alpha` homepage recent-files section while preserving the current `theta` theme layout and clickable recent-file entries.

**Architecture:** Keep the change inside `lua/plugins/alpha_nvim.lua`. Replace the theme's stock recent-files section with a custom group that builds a bordered title line, mutates the generated MRU buttons to render inside the box, and leaves the existing header, quick links, `nvim-tree`, and buffer-return logic unchanged.

**Tech Stack:** Neovim Lua, `goolord/alpha-nvim`

---

## Chunk 1: Bordered Recent Files Section

### Task 1: Replace the stock recent-files section with a bordered version

**Files:**
- Modify: `lua/plugins/alpha_nvim.lua`

- [ ] **Step 1: Define the failing verification target**

Run: a headless Neovim command that loads `lua/plugins/alpha_nvim.lua`, inspects the resulting Alpha layout, and asserts that the recent-files section contains border text such as `┌` or `│`.
Expected: FAIL before implementation because no bordered section exists yet.

- [ ] **Step 2: Add a helper that builds the bordered recent-files group**

Implementation details:
- create fixed-width top and bottom border lines
- render a title line inside the box
- reuse `theta.mru(...)` to get recent-file buttons
- wrap each button label with left/right border characters and pad to a consistent inner width

- [ ] **Step 3: Swap the bordered section into the Alpha layout**

Implementation details:
- replace the stock `theta` recent-files section in `theta.config.layout`
- keep the existing header, quick links, footer, and existing homepage behavior

## Chunk 2: Verification

### Task 2: Validate load and border rendering

**Files:**
- Test: `lua/plugins/alpha_nvim.lua`

- [ ] **Step 1: Run the original minimal load check**

Run: a headless Neovim command that loads the plugin config with `alpha`, `plenary`, and `nvim-tree` on `runtimepath`
Expected: exit code 0

- [ ] **Step 2: Run the border inspection check**

Run: a headless Neovim command that evaluates the custom recent-files section and asserts border characters are present
Expected: PASS
