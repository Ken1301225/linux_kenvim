-- 占位实现，Task 5 替换为完整月视图
local M = {}

function M.attach(ctx)
  vim.keymap.set("n", "q", function() ctx.actions.close() end,
    { buffer = ctx.buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", function() ctx.actions.close() end,
    { buffer = ctx.buf, nowait = true, silent = true })
  vim.api.nvim_set_option_value("modifiable", true, { buf = ctx.buf })
  vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, { " TODO（月视图占位）" })
  vim.api.nvim_set_option_value("modifiable", false, { buf = ctx.buf })
end

return M
