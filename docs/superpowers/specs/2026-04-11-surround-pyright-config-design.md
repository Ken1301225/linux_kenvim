# Surround And Pyright Config Design

**Goal:** Make surround operations easier to reach with `<leader>`-based mappings and tune `pyright` so Python editing feels closer to Pylance while avoiding noisy diagnostics.

**Scope:**
- Update `lua/plugins/surround.lua` to replace the default `nvim-surround` mappings with `<leader>s...` mappings.
- Update `lua/plugins/mason.lua` to strengthen `pyright` analysis, keep auto-import support, and suppress common low-signal warnings.

**Design:**
- Disable `nvim-surround` default mappings through the plugin's global switch, then bind the official `<Plug>` mappings to a consistent `<leader>s...` prefix.
- Keep the surround feature set intact: add, delete, replace, visual surround, and linewise variants remain available.
- Make surround edits feel smoother by keeping the cursor "sticky" and shortening highlight delay for feedback.
- Raise `pyright` from `basic` to `standard` type checking, keep `autoImportCompletions`, `autoSearchPaths`, and `useLibraryCodeForTypes`, and keep diagnostics scoped to open files.
- Reduce common false-positive or low-value diagnostics by overriding noisy unknown-type and missing-stub/module-source rules.
- Enable Python inlay hints when the server supports them to provide richer inline type information without adding extra external tools.

**Non-Goals:**
- Switching from `pyright` to `basedpyright`
- Adding external Python tools such as Ruff, pylsp, or debug adapters
- Reworking unrelated LSP or keymap behavior
