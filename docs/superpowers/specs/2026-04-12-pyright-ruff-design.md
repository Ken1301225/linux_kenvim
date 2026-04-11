# Pyright And Ruff Integration Design

**Goal:** Combine `pyright` and Ruff so Python editing gets stronger type intelligence, lint fixes, and import organization without increasing noisy diagnostics or conflicting with the existing formatter setup.

**Scope:**
- Update `lua/plugins/mason.lua` to install and configure the Ruff language server.
- Keep `pyright` as the primary language-intelligence server.
- Expose practical buffer-local commands for Ruff fixes and import organization.

**Design:**
- Keep `pyright` responsible for completion, definitions, hover, references, auto-imports, and type checking.
- Add the new built-in `ruff` language server, not deprecated `ruff_lsp`.
- Disable `pyright` organize-imports support so Ruff owns that responsibility.
- Disable Ruff hover and formatting capabilities so they do not compete with `pyright` hover or the existing `none-ls` `black` and `isort` formatter chain.
- Add buffer-local `:LspRuffFixAll` and `:LspRuffOrganizeImports` commands that apply Ruff code actions directly.

**Non-Goals:**
- Replacing `black` or `isort`
- Switching from `pyright` to `basedpyright`
- Reworking unrelated global keymaps or Python tooling
