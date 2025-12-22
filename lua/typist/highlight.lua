local M = {}
local config = require('typist.config')

function M.setup()
  vim.api.nvim_set_hl(0, config.grey_hl, { fg = '#808080', bg = '#2a2a2a' })
  vim.api.nvim_set_hl(0, config.incorrect_hl, { fg = '#ff0000', bg = '#3a0000' })
  vim.api.nvim_set_hl(0, config.correct_hl, { fg = '#00ff00', bg = '#003a00' })
  vim.api.nvim_set_hl(0, config.current_line_hl, { link = 'LineNr' })
end

return M
