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
vim.o.exrc = true

-- 自动用 feh 打开图片，zathura 打开 PDF
vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = {"*.png", "*.jpg", "*.jpeg", "*.bmp", "*.gif","*.pdf"},
    callback = function()
        -- 保存当前缓冲区位置，防止跳转影响
        local file = vim.fn.expand("<afile>")
        -- 调用系统 feh 打开
        vim.fn.jobstart({"feh", file}, {detach = true})
        -- 关闭当前 buffer
        vim.cmd("bdelete!")
    end
})

vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = {"*.pdf"},
    callback = function()
        local file = vim.fn.expand("<afile>")
        vim.fn.jobstart({"mupdf", file}, {detach = true})
        vim.cmd("bdelete!")
    end
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "copilot-chat",
  callback = function()
    vim.bo.filetype = "markdown"
  end,
})
