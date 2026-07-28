vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 0
vim.opt.autoread = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.colorcolumn = "90"
vim.opt.clipboard = "unnamedplus"
vim.opt.nrformats = "bin,hex,alpha"
vim.opt.termguicolors = true
vim.o.exrc = true

local function first_executable(candidates)
    for _, candidate in ipairs(candidates) do
        local executable = vim.fn.exepath(candidate)
        if executable ~= "" then
            return executable
        end
    end
end

local function register_external_opener(patterns, candidates)
    local executable = first_executable(candidates)
    if not executable then
        return
    end

    vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = patterns,
        callback = function(args)
            local file = vim.api.nvim_buf_get_name(args.buf)
            vim.fn.jobstart({executable, file}, {detach = true})
            vim.api.nvim_buf_delete(args.buf, {force = true})
        end,
    })
end

register_external_opener({"*.png", "*.jpg", "*.jpeg", "*.bmp", "*.gif"}, {"feh", "imv", "xdg-open"})
register_external_opener({"*.pdf"}, {"zathura"})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "copilot-chat",
  callback = function()
    vim.bo.filetype = "markdown"
  end,
})

vim.opt.fileformats = {"unix", "dos"}

-- 禁用内置的 code action lightbulb (💡)
vim.lsp.config.code_action = {
  lightbulb = {
    enable = false,
  },
}


vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  pattern = "*",
  command = "if mode() != 'c' | checktime | endif",
})
