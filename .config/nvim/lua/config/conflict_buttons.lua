-- VS Code-style clickable button bar for git-conflict.nvim: renders
-- "[Accept Current] [Accept Incoming] [Accept Both] [Accept None]" as a
-- virtual line above each conflict's `<<<<<<<` marker, and makes it
-- mouse-clickable.
--
-- Neovim has no native clickable virtual text, so clicks are detected with
-- getmousepos(): a click landing on the bar reports the SAME buffer line as
-- the marker it's attached to (virt_lines have no buffer line of their own),
-- but a smaller `winrow` than that line's real screen row -- the delta is
-- how many screen rows above the marker the click landed. `wincol` is a
-- screen column that includes the number/sign/fold gutter, so the gutter
-- width (win textoff) must be subtracted to get the column inside the bar
-- text. Both details were verified empirically against a real window
-- (number+relativenumber+signcolumn) before writing this, not assumed.
local M = {}

local ns = vim.api.nvim_create_namespace("conflict_buttons")
local group = vim.api.nvim_create_augroup("ConflictButtons", { clear = true })

local BUTTONS = {
  { label = "Accept Current", hl = "DiffText", action = "ours", key = "co" },
  { label = "Accept Incoming", hl = "DiffAdd", action = "theirs", key = "ct" },
  { label = "Accept Both", hl = "Normal", action = "both", key = "cb" },
  { label = "Accept None", hl = "Comment", action = "none", key = "c0" },
}

-- Bar text/highlights and each button's [start_col, end_col) are identical
-- for every conflict, so build them once.
local bar_parts, bar_segments = {}, {}
do
  local col = 0
  for i, btn in ipairs(BUTTONS) do
    local text = string.format("[%s (%s)]", btn.label, btn.key)
    table.insert(bar_parts, { text, btn.hl })
    table.insert(bar_segments, { start_col = col, end_col = col + #text, action = btn.action })
    col = col + #text
    if i < #BUTTONS then
      table.insert(bar_parts, { " ", "Normal" })
      col = col + 1
    end
  end
end

-- bufnr -> { [reported_0idx_line] = marker_0idx_line }. Usually the same
-- value (see the line-0 special case in render() for why they can differ).
local active = {}

local function scan_marker_lines(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local markers = {}
  for i, line in ipairs(lines) do
    if line:match("^<<<<<<<") then
      table.insert(markers, i - 1)
    end
  end
  return markers
end

local function render(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local markers = scan_marker_lines(bufnr)
  active[bufnr] = {}
  for _, line in ipairs(markers) do
    if line == 0 then
      -- virt_lines_above is invisible and unclickable on the buffer's very
      -- first line -- nvim has nowhere to scroll to reveal a row "before"
      -- line 1 (verified empirically). Render the bar below instead for
      -- this one case. A click on a below-placed virt_lines row is
      -- attributed by getmousepos() to the FOLLOWING real line, not this
      -- one, so the lookup key is offset by 1.
      vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
        virt_lines = { bar_parts },
      })
      active[bufnr][line + 1] = line
    else
      vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
        virt_lines = { bar_parts },
        virt_lines_above = true,
      })
      active[bufnr][line] = line
    end
  end
end

local function clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  active[bufnr] = nil
end

-- Returns "" (swallow the click, action already taken) or "<LeftMouse>"
-- (not a bar click, let Neovim's default click handling run).
local function handle_click(bufnr)
  local mp = vim.fn.getmousepos()
  local markers = active[bufnr]
  if not markers then
    return "<LeftMouse>"
  end

  local reported_line = mp.line - 1 -- getmousepos() line is 1-indexed
  local marker_line = markers[reported_line]
  if not marker_line then
    return "<LeftMouse>"
  end

  local real_row = vim.fn.screenpos(mp.winid, mp.line, 1).row
  if mp.winrow >= real_row then
    return "<LeftMouse>" -- clicked the real marker line itself, not the bar
  end

  local textoff = vim.fn.getwininfo(mp.winid)[1].textoff
  local text_col = mp.wincol - textoff - 1 -- 0-indexed column within the bar text

  for _, seg in ipairs(bar_segments) do
    if text_col >= seg.start_col and text_col < seg.end_col then
      -- expr-mapping callbacks run under textlock: window/cursor changes and
      -- buffer mutations (both of which git-conflict.choose() needs to do)
      -- raise E565 there (verified empirically -- it hangs headless nvim on
      -- an unattended error prompt). Defer the actual work past textlock.
      local winid, cursor_line = mp.winid, marker_line + 1
      vim.schedule(function()
        -- Unlike a real click, intercepting <LeftMouse> does not move the
        -- cursor on its own (also verified empirically) -- choose() acts on
        -- whichever conflict the cursor is in, so move it there first.
        vim.api.nvim_set_current_win(winid)
        vim.api.nvim_win_set_cursor(winid, { cursor_line, 0 })
        require("git-conflict").choose(seg.action)
      end)
      return ""
    end
  end

  return "" -- click landed in a gap between buttons; swallow it anyway
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "GitConflictDetected",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      -- GitConflictDetected can re-fire for a buffer that's already wired
      -- (e.g. its internal conflict_mappings_set flag resets); guard against
      -- stacking duplicate TextChanged autocmds and keymaps.
      if vim.b[bufnr].conflict_buttons_active then
        render(bufnr)
        return
      end
      vim.b[bufnr].conflict_buttons_active = true

      render(bufnr)
      vim.keymap.set("n", "<LeftMouse>", function()
        return handle_click(bufnr)
      end, { buffer = bufnr, expr = true, desc = "Conflict button click" })
      vim.api.nvim_create_autocmd("TextChanged", {
        group = group,
        buffer = bufnr,
        callback = function()
          render(bufnr)
        end,
      })
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "GitConflictResolved",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.b[bufnr].conflict_buttons_active = false
      clear(bufnr)
      pcall(vim.keymap.del, "n", "<LeftMouse>", { buffer = bufnr })
    end,
  })
end

return M
