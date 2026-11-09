local root = vim.env.NVIM_REVIEW_ROOT or vim.fn.getcwd()
local plugins = vim.fn.expand("~/.local/share/nvim/lazy/")
for _, name in ipairs({ "vimtex", "nvim-autopairs", "LuaSnip" }) do
  vim.opt.rtp:prepend(plugins .. name)
end
vim.g.vimtex_view_enabled = 0
vim.g.vimtex_compiler_enabled = 0
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")
vim.cmd("runtime plugin/vimtex.vim")
local spec = dofile(root .. "/lua/plugins/nvim-autopairs.lua")
spec.config(nil, spec.opts)

local passed, failed = 0, 0
local function eq(actual, expected, label)
  if vim.deep_equal(actual, expected) then
    passed = passed + 1
  else
    failed = failed + 1
    print("FAIL " .. label .. ": " .. vim.inspect(actual) .. " ~= " .. vim.inspect(expected))
  end
end

local function type_at(line, key, expected, label)
  local pos = assert(line:find("|", 1, true))
  line = line:sub(1, pos - 1) .. line:sub(pos + 1)
  vim.cmd("enew!")
  vim.bo.filetype = "tex"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "\\documentclass{article}", "\\usepackage{amsmath,graphicx}",
    "\\begin{document}", line, "\\end{document}",
  })
  vim.cmd("syntax sync fromstart")
  vim.api.nvim_win_set_cursor(0, { 4, pos - 1 })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i" .. key .. "<Esc>", true, false, true), "xt", false)
  eq(vim.api.nvim_buf_get_lines(0, 3, 4, false)[1], expected, label)
end

type_at("file|name", "_", "file_name", "plain text underscore")
type_at([[file\|name]], "_", [[file\_name]], "escaped underscore")
type_at([[\label{eq:test|name}]], "_", [[\label{eq:test_name}]], "label underscore")
type_at([[\includegraphics{fig|name.pdf}]], "_", [[\includegraphics{fig_name.pdf}]], "image path underscore")
type_at("$x|$", "_", "$x_{}$", "math subscript")
type_at("$x|$", "^", "$x^{}$", "math superscript")
type_at([[$x\|$]], "_", [[$x\_$]], "escaped underscore in math")
type_at([[$\text{file|name}$]], "_", [[$\text{file_name}$]], "text inside math")
type_at([[$x \label{eq:test|name}$]], "_", [[$x \label{eq:test_name}$]], "label inside math")
type_at([[$x \includegraphics{fig|name.pdf}$]], "_", [[$x \includegraphics{fig_name.pdf}$]], "image path inside math")
type_at("% $x|$", "_", "% $x_$", "comment containing math")

local snippets = dofile(root .. "/luasnippets/tex.lua")
local examples = {}
for _, snippet in ipairs(snippets) do
  local doc = table.concat(snippet:get_docstring(), "\n")
  if snippet.trigger == "sec" then
    examples.section = doc:gsub("%$1", "Test"):gsub("%$2", "test"):gsub("%$0", "")
  elseif snippet.trigger == "ref" then
    examples.reference = doc:gsub("%$1", "sec:test"):gsub("%$0", "")
  end
end
eq(examples.section:match("\\label{(.-)}"), "sec:test", "section label key")
eq(examples.reference, "\\ref{sec:test}", "reference key matches label")
if vim.env.NVIM_REVIEW_TEX_OUTPUT then
  local document = table.concat({ "\\documentclass{article}", "\\begin{document}",
    examples.section, examples.reference, "\\end{document}" }, "\n")
  vim.fn.writefile(vim.split(document, "\n", { plain = true }), vim.env.NVIM_REVIEW_TEX_OUTPUT)
end

print(string.format("latex_input_spec: %d passed, %d failed", passed, failed))
vim.cmd(failed == 0 and "qa!" or "cquit 1")
