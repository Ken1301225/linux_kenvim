# Pyright And Ruff Integration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Ruff alongside Pyright so Python editing gains fast linting and import organization without increasing tool conflicts.

**Architecture:** Keep all Python LSP wiring inside `lua/plugins/mason.lua`. Use `pyright` for language intelligence and type checking, and add the built-in Ruff server for diagnostics and code actions only. Preserve the existing `none-ls` formatting setup by explicitly avoiding Ruff formatting.

**Tech Stack:** Neovim Lua, `mason.nvim`, `mason-lspconfig.nvim`, `nvim-lspconfig`, `pyright`, Ruff

---

## Chunk 1: Ruff Integration

### Task 1: Install and configure Ruff in the Mason/LSP setup

**Files:**
- Modify: `lua/plugins/mason.lua`

- [ ] **Step 1: Extend the common LSP setup helper**

Implementation details:
- preserve any server-specific `on_attach`
- keep common capability setup and formatting disable logic

- [ ] **Step 2: Refine `pyright` responsibilities**

Implementation details:
- keep the current low-noise type-checking configuration
- disable Pyright organize-imports support

- [ ] **Step 3: Add Ruff with minimal overlapping capabilities**

Implementation details:
- install the `ruff` package
- disable Ruff hover and formatting capabilities
- keep Ruff available for diagnostics and code actions

## Chunk 2: Practical Commands

### Task 2: Add buffer-local commands for Ruff code actions

**Files:**
- Modify: `lua/plugins/mason.lua`

- [ ] **Step 1: Add `:LspRuffFixAll`**

Implementation details:
- apply `source.fixAll.ruff` code actions for the current buffer

- [ ] **Step 2: Add `:LspRuffOrganizeImports`**

Implementation details:
- apply `source.organizeImports.ruff` code actions for the current buffer

## Chunk 3: Verification

### Task 3: Validate the updated config module

**Files:**
- Test: `lua/plugins/mason.lua`

- [ ] **Step 1: Run a targeted headless module load**

Run: `nvim --headless -u NONE -i NONE "+lua local spec = dofile('/home/ken/.config/nvim/lua/plugins/mason.lua'); assert(type(spec) == 'table'); assert(type(spec.config) == 'function')" "+qa"`
Expected: exit code 0
