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
    },
    event = "VeryLazy",
    opts = {
        completion = {
            documentation = {
                auto_show = true,
            },
        },
        keymap = {
            preset = "super-tab",
        },
        sources = {
            default = { "path", "snippets", "buffer", "lsp" },
            providers = {
                lsp = {
                    transform_items = sanitize_lsp_items,
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
}
