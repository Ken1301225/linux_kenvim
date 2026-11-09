-- Warm, readable infoview highlights for gruvbox-material.
local function apply_colors()
  local groups = {
    leanInfoSelected = { fg = '#FFF2D5', bg = '#765936', bold = true },
    widgetElementHighlight = { fg = '#FFF2D5', bg = '#594B38', bold = true },
    leanInfoDiffwasChanged = { fg = '#FFE0A3', bg = '#594B38', bold = true },
  }
  for _, name in ipairs({
    'leanInfoDiffwasInserted', 'leanInfoDiffwillInsert',
    'leanInfoHypNameInserted', 'leanInfoGoalInserted',
  }) do
    groups[name] = { fg = '#D8E5B0', bg = '#414B35' }
  end
  for _, name in ipairs({
    'leanInfoDiffwillChange', 'leanInfoDiffwasDeleted', 'leanInfoDiffwillDelete',
    'leanInfoHypNameRemoved', 'leanInfoGoalRemoved',
  }) do
    groups[name] = { fg = '#F2C0A7', bg = '#593F39' }
  end
  for name, colors in pairs(groups) do
    vim.api.nvim_set_hl(0, name, colors)
  end
end

apply_colors()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('LeanInfoviewWarmColors', { clear = true }),
  callback = apply_colors,
})
