return {
  "tuanpham-dev/vim-plastic",
  lazy = false,
  priority = 1000,
  config = function()
    vim.g.plastic_allow_italics = 1
    vim.cmd.colorscheme("plastic")
    -- Set eagerly (not just via the ColorScheme autocmd in autocmds.lua)
    -- since indent-blankline reads this group synchronously during its own
    -- setup, which can run before any autocmd-based highlight is applied.
    vim.api.nvim_set_hl(0, "IndentGuides", { fg = "#2e323a", bg = "NONE" })
  end,
}
