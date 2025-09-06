return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim"
    },
    event = "VeryLazy",
   config = function ()
       local registry = require("mason-registry")

       local function install(name)
           local succ,package = pcall(registry.get_package,name)
           if succ and not package:is_installed() then
               package:install()
            end
        end
        install("stylua")
        install("black")
        install("isort")

       local null_ls = require("null-ls")
       null_ls.setup({
           sources = {
               null_ls.builtins.formatting.stylua,
               null_ls.builtins.formatting.black,
               null_ls.builtins.formatting.isort,
           }
       })
   end,
   keys = {
       {"<leader>lf" , vim.lsp.buf.format }
   }
}
