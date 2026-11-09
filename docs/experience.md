# Editing Shortcuts

Leader is Space; local leader is comma.

| Key / command | Action |
| --- | --- |
| Space fo | Recent files |
| Space fw | Search for the word under the cursor |
| Space fr | Resume the last Telescope search |
| Space ua | Toggle automatic formatting for this buffer |
| :FormatToggle! | Toggle automatic formatting globally |
| Space lf | Format manually, including when automatic formatting is off |
| Space xx | Open or close project diagnostics |
| ,ln | Run chktex in each TeX buffer |

Python defaults to Ruff for import sorting and formatting. Ruff uses the
project's own configuration. For a project that requires Black and isort, set
`vim.g.python_formatter = "black"` in its trusted `.nvim.lua`, or run
`:lua vim.b.python_formatter = "black"` for only the current buffer. This is an
explicit override; Black configuration files are not detected automatically.
Set the value to `nil` to return to Ruff.

Saving waits at most one second for formatting. Use Space lf for unusually large
files. The buffer and global automatic-formatting switches are independent:
automatic formatting runs only when both allow it.

Persistent undo keeps editing history across restarts. Diagnostics refresh after
leaving Insert mode. VimTeX opens compilation errors without taking focus; warnings
alone do not open the error list. Viewer screen dimensions are detected
asynchronously once per Neovim session.

Treesitter uses the installed plugin's current API and installs missing configured
parsers. A filetype without a parser keeps its usual syntax highlighting.
