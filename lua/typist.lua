local config = require('typist.config')
local highlight = require('typist.highlight')

local M = {}

M.BACKSPACE = vim.api.nvim_replace_termcodes("<bs>", true, true, true)
M.ESC = vim.api.nvim_replace_termcodes("<esc>", true, true, true)
M.ENTER = vim.api.nvim_replace_termcodes("<CR>", true, true, true)

local state = {
  buf = nil,
  win = nil,
  lines = {},
  current_pos = { 0, 0 },
  active = false,
  ns = nil,
  -- The extmarks used to highlight the characters
  extmark_ids = {},
  -- The current line indicator displayed in the sign column
  current_line = { index = nil, extmark_id = nil },
}

local function clear_extmarks()
  if state.buf and state.ns then
    vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)
  end
end

local function set_grey_overlay()
  clear_extmarks()

  local line_count = #state.lines
  if line_count == 0 then return end

  vim.api.nvim_buf_set_extmark(state.buf, state.ns, 0, 0, {
    end_row = line_count - 1,
    hl_eol = true,
    hl_group = config.grey_hl,
    priority = 1000,
  })
end

local function update_current_line_sign()
  if not state.active then
    return
  end

  if state.current_line.index == state.current_pos[1] then
    return
  end

  if state.current_line.extmark_id then
    vim.api.nvim_buf_del_extmark(state.buf, state.ns, state.current_line.extmark_id)
  end

  state.current_line.extmark_id = vim.api.nvim_buf_set_extmark(state.buf, state.ns, state.current_pos[1], 0, {
    sign_text = ">>",
    sign_hl_group = config.current_line_hl,
    priority = 3000,
  })

  state.current_line.index = state.current_pos[1]
end

local function update_char(correct)
  local row, col = state.current_pos[1], state.current_pos[2]
  local line = state.lines[row + 1]

  if not line then
    M.stop()
    return
  end

  local hl_group = correct and config.correct_hl or config.incorrect_hl
  local extmark_id = vim.api.nvim_buf_set_extmark(state.buf, state.ns, row, col, {
    end_row = row,
    end_col = col + 1,
    hl_group = hl_group,
    priority = 2000,
  })

  table.insert(state.extmark_ids, extmark_id)

  -- Move to next character
  if col < #line - 1 then
    state.current_pos[2] = col + 1
  else
    if row >= #state.lines - 1 then
      M.stop()
      return
    end
  end

  vim.api.nvim_win_set_cursor(state.win, { state.current_pos[1] + 1, state.current_pos[2] })
  update_current_line_sign()
end

local function handle_backspace()
  if #state.extmark_ids == 0 then
    return
  end

  -- Remove the last extmark
  local extmark_id = table.remove(state.extmark_ids)
  vim.api.nvim_buf_del_extmark(state.buf, state.ns, extmark_id)

  -- Move the cursor back
  local row, col = state.current_pos[1], state.current_pos[2]
  if col > 0 then
    state.current_pos[2] = col - 1
  else
    if row > 0 then
      state.current_pos[1] = row - 1
      local prev_line = state.lines[state.current_pos[1] + 1]
      state.current_pos[2] = #prev_line
    else
      -- Already at the beginning, do nothing
      return
    end
  end

  vim.api.nvim_win_set_cursor(state.win, { state.current_pos[1] + 1, state.current_pos[2] })
  update_current_line_sign()
end

function M.start()
  state.buf = vim.api.nvim_get_current_buf()
  state.win = vim.api.nvim_get_current_win()
  state.lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  state.current_pos = { 0, 0 }
  state.active = true
  state.ns = vim.api.nvim_create_namespace('typist')
  state.extmark_ids = {}
  state.current_line = { index = nil, extmark_id = nil }

  highlight.setup()

  set_grey_overlay()

  vim.wo[state.win].signcolumn = 'yes'
  vim.api.nvim_win_set_cursor(state.win, { 1, 0 })
  update_current_line_sign()

  while state.active do
    if not vim.api.nvim_buf_is_valid(state.buf) or not vim.api.nvim_win_is_valid(state.win) then
      M.stop()
      break
    end

    if vim.api.nvim_get_current_buf() ~= state.buf then
      M.stop()
      break
    end

    -- Force redraw because getcharstr will block the UI
    vim.cmd('redraw')

    local ok, key = pcall(vim.fn.getcharstr)

    if not ok then
      M.stop()
      break
    end

    if key == M.ESC then
      M.stop()
      break
    end

    if key == M.BACKSPACE then
      handle_backspace()
      goto continue
    end

    if key == M.ENTER then
      local row, col = state.current_pos[1], state.current_pos[2]
      local line = state.lines[row + 1]

      if col == #line - 1 or #line == 0 then
        if row < #state.lines - 1 then
          state.current_pos[1] = row + 1
          state.current_pos[2] = 0
          vim.api.nvim_win_set_cursor(state.win, { state.current_pos[1] + 1, state.current_pos[2] })
          update_current_line_sign()
        else
          M.stop()
          break
        end
      end

      goto continue
    end

    if #key ~= 1 then
      goto continue
    end

    local row, col = state.current_pos[1], state.current_pos[2]
    local line = state.lines[row + 1]
    if not line then
      M.stop()
      break
    end

    if col >= #line then
      goto continue
    end

    local expected = line:sub(col + 1, col + 1)
    update_char(key == expected)

    ::continue::
  end
end

function M.stop()
  if not state.active then
    return
  end

  state.active = false

  clear_extmarks()

  state.buf = nil
  state.win = nil
  state.lines = {}
  state.current_pos = { 0, 0 }
  state.ns = nil
  state.extmark_ids = {}
  state.current_line = { index = nil, extmark_id = nil }
end

function M.setup(opts)
  vim.api.nvim_create_user_command('TypistStart', function()
    M.start()
  end, {})

  vim.api.nvim_create_user_command('TypistStop', function()
    M.stop()
  end, {})
end

return M
