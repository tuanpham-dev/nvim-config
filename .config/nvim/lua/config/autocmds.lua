local autocmd = vim.api.nvim_create_autocmd

-- Timestamp backup files on every write
autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.o.backupext = "@" .. os.date("%Y-%m-%d.%H:%M")
  end,
})

-- Custom indentation for file types
autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.shiftwidth = 4
  end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Leave insert mode when inactive
autocmd("CursorHoldI", { pattern = "*", command = "stopinsert" })

-- Enter insert mode on new terminal created
autocmd("TermOpen", { pattern = "term://*", command = "startinsert" })
autocmd({ "BufEnter", "BufNew" }, { pattern = "term://*", command = "startinsert" })

-- Leave insert mode after restoring a session
autocmd("SessionLoadPost", { pattern = "*", command = "stopinsert" })

-- indent-blankline guide color, re-applied if the colorscheme changes at
-- runtime (set once eagerly in plugins/colorscheme.lua at startup)
autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "IndentGuides", { fg = "#343845", bg = "NONE" })
  end,
})

-- Forward every yank into the unnamed register to the client clipboard via
-- OSC 52 (vim-oscyank, see plugins/misc.lua) — leaves clipboard=unnamedplus
-- untouched, so this only fires on an actual yank, not every delete.
autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    if vim.v.event.operator == "y" and vim.v.event.regname == "" then
      vim.cmd('OSCYankRegister "')
    end
  end,
})
