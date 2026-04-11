# Surround And Pyright Config Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add leader-based surround mappings and refine `pyright` so Python editing is stronger but less noisy.

**Architecture:** Keep the existing plugin layout. Put surround keymap and ergonomics changes entirely in `lua/plugins/surround.lua`, and keep all Python LSP tuning inside the existing `pyright` setup in `lua/plugins/mason.lua`.

**Tech Stack:** Neovim Lua, `kylechui/nvim-surround`, `mason.nvim`, `nvim-lspconfig`, `pyright`

---

## Chunk 1: Surround Ergonomics

### Task 1: Replace default surround keymaps with a leader-based layout

**Files:**
- Modify: `lua/plugins/surround.lua`

- [ ] **Step 1: Disable the plugin's default mappings**

Implementation details:
- set `vim.g.nvim_surround_no_mappings = true` in plugin init

- [ ] **Step 2: Bind the plugin's official `<Plug>` mappings to `<leader>s...`**

Implementation details:
- normal mode add/delete/change mappings
- visual mode add mappings
- linewise variants for current line and visual selections

- [ ] **Step 3: Apply small ergonomic defaults**

Implementation details:
- keep highlight feedback enabled with a short duration
- use sticky cursor movement after surround operations

## Chunk 2: Pyright Tuning

### Task 2: Make pyright stronger without making it noisy

**Files:**
- Modify: `lua/plugins/mason.lua`

- [ ] **Step 1: Raise pyright checking from `basic` to `standard`**

Implementation details:
- keep `diagnosticMode = "openFilesOnly"`
- keep import and library type support enabled

- [ ] **Step 2: Silence common low-signal diagnostics**

Implementation details:
- suppress missing type stubs and missing module source warnings
- suppress unknown-type family diagnostics that often feel like false positives in partially typed projects

- [ ] **Step 3: Enable Python inlay hints when supported**

Implementation details:
- hook into `on_attach`
- guard the call so non-supporting servers are unaffected

## Chunk 3: Verification

### Task 3: Validate the updated configuration

**Files:**
- Test: `lua/plugins/surround.lua`
- Test: `lua/plugins/mason.lua`

- [ ] **Step 1: Run Lua syntax checks**

Run: `luac -p lua/plugins/surround.lua && luac -p lua/plugins/mason.lua`
Expected: exit code 0

- [ ] **Step 2: Run a headless Neovim startup check**

Run: `nvim --headless "+qa"`
Expected: exit code 0
