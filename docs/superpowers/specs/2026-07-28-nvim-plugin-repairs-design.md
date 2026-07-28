# Neovim Plugin Repairs Design

## Goal

Repair the confirmed Neovim configuration defects without replacing plugins,
changing the existing leader-key layout, or broadening the plugin set.

## Scope

The repair covers these behaviors:

1. Open PDF files with the installed `zathura` executable and avoid dispatching
   a PDF to multiple viewers. Only register image-opening behavior when a
   supported image viewer is available.
2. Add native normal-mode `Ctrl-h/j/k/l` window navigation so the existing tmux
   bindings can hand navigation into Neovim without another plugin.
3. Make the configured Python provider usable by installing `pynvim` into the
   selected Conda base interpreter.
4. Keep the DAP stack unloaded until a debug command or debug key is used.
5. Load Mason/LSP setup before editing a normal file or creating a new one, and
   preserve the `:Mason` command path from the dashboard.
6. Prevent disabled CopilotChat configuration from registering an autocmd.
7. Keep code_runner state local, handle cancelled argument input without
   running a command, and preserve the current C/C++ runner workflow.
8. Remove Trouble's obsolete diagnostic-sign option; the current plugin reads
   signs directly from Neovim's diagnostic configuration.
9. Disable lazy.nvim LuaRocks support because no configured plugin requires it.

Missing Java, Deno, Node provider, Perl provider, and LuaSnip `jsregexp` support
remain out of scope because no enabled workflow currently requires them.

## Implementation

Changes remain within the existing modules:

- `lua/config/basic.lua` owns external file viewers.
- `lua/config/keymap.lua` owns native window navigation.
- `lua/config/lazy.lua` owns lazy.nvim package-manager options.
- `lua/plugins/cppdap.lua` owns DAP loading boundaries.
- `lua/plugins/mason.lua` owns LSP/Mason loading boundaries.
- `lua/plugins/copilotChat.lua`, `coderunner.lua`, and `trouble.lua` receive
  targeted configuration corrections.

No plugin is added, removed, or replaced. The Python package installation is
the only environment-level change.

## Error Handling

External viewers are invoked only when executable. Cancelling the code_runner
argument prompt returns without compiling. Plugin loading remains reachable
through existing commands and key mappings after lazy-loading changes.

## Verification

Automated configuration checks will assert the corrected static contracts and
runtime mappings. Final verification will include:

- the configuration test suite;
- `nvim --headless +qa`;
- `:checkhealth` with no relevant provider or lazy.nvim errors;
- runtime inspection showing DAP is initially unloaded;
- a Lua buffer check for Treesitter and LSP attachment;
- startup-time measurement for comparison with the previous ~176 ms baseline.
