vim.keymap.set({"n","i"}, "<C-z>", "<Cmd>undo<CR>", {silent = true})
vim.g.mapleader = " "

vim.g.maplocalleader = ","

for _, direction in ipairs({"h", "j", "k", "l"}) do
    vim.keymap.set("n", "<C-" .. direction .. ">", "<Cmd>wincmd " .. direction .. "<CR>", {
        silent = true,
        desc = "Move to " .. direction .. " window",
    })
end
