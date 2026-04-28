local function sanitize_lsp_items(_, items)
    local sanitized = {}

    for _, item in ipairs(items) do
        if type(item.label) == "string" then
            if item.labelDetails ~= nil then
                if type(item.labelDetails) ~= "table" then
                    item.labelDetails = nil
                else
                    if type(item.labelDetails.detail) ~= "string" then
                        item.labelDetails.detail = nil
                    end
                    if type(item.labelDetails.description) ~= "string" then
                        item.labelDetails.description = nil
                    end
                end
            end

            sanitized[#sanitized + 1] = item
        end
    end

    return sanitized
end

return {
    "saghen/blink.cmp",
    version = "*",
    dependencies = {
        "rafamadriz/friendly-snippets",
        "L3MON4D3/LuaSnip",
    },
    event = "VeryLazy",
    opts = {
        snippets = {
            preset = "luasnip",
        },
        completion = {
            documentation = {
                auto_show = true,
            },
        },
        keymap = {
            preset = "super-tab",
        },
        sources = {
            default = { "vimtex", "path", "snippets", "buffer", "lsp" },
            providers = {
                lsp = {
                    transform_items = sanitize_lsp_items,
                },
                vimtex = {
                    name = "vimtex",
                    module = "blink.cmp.sources.complete_func",
                    score_offset = 2,
                    opts = {
                        complete_func = function()
                            if vim.bo.filetype ~= "tex" then
                                return function() end
                            end
                            return vim.bo.omnifunc ~= "" and vim.bo.omnifunc or function() end
                        end,
                    },
                },
            },
        },
        cmdline = {
            sources = function()
                local cmd_type = vim.fn.getcmdtype()
                if cmd_type == "/" then
                    return { "buffer" }
                end
                if cmd_type == ":" then
                    return { "cmdline" }
                end
                return {}
            end,
            keymap = {
                preset = "super-tab",
            },
            completion = {
                menu = {
                    auto_show = true,
                },
            },
        },
    },
    config = function(_, opts)
        -- Load custom Lua snippets from ~/.config/nvim/luasnippets/
        require("luasnip.loaders.from_lua").lazy_load({ paths = { vim.fn.stdpath("config") .. "/luasnippets" } })
        -- Load VSCode-style snippets (friendly-snippets)
        require("luasnip.loaders.from_vscode").lazy_load()
        require("blink.cmp").setup(opts)
    end,
}
