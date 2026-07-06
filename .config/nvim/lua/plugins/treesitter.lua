-- Replaces stephenway/postcss.vim, pangloss/vim-javascript,
-- leafgarland/typescript-vim and peitalin/vim-jsx-typescript with
-- treesitter-based highlighting.
--
-- "main" is a from-scratch rewrite required for Neovim >= 0.12 (the old
-- "master" branch / configs.setup() API only supports Neovim 0.10-0.11 and
-- crashes on 0.12, e.g. "attempt to call method 'range' (a nil value)" when
-- parsing markdown injections). It doesn't auto-enable highlight/indent, so
-- that's wired up manually below. See :h nvim-treesitter-commands.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- this plugin does not support lazy-loading
  build = ":TSUpdate",
  config = function()
    local ensure_installed = {
      "javascript",
      "typescript",
      "tsx",
      "css",
      "json",
      "html",
      "lua",
      "vim",
      "vimdoc",
      "markdown",
      "markdown_inline",
    }
    require("nvim-treesitter").install(ensure_installed)

    -- Parser name only differs from vim filetype for these two; everything
    -- else (javascript, css, json, html, lua, vim, markdown) matches by name.
    local ft_to_lang = {
      typescriptreact = "tsx",
      help = "vimdoc",
    }

    vim.api.nvim_create_autocmd("FileType", {
      pattern = {
        "javascript",
        "typescript",
        "typescriptreact",
        "css",
        "json",
        "html",
        "lua",
        "vim",
        "help",
        "markdown",
      },
      callback = function(args)
        local lang = ft_to_lang[args.match] or args.match
        local ok = pcall(vim.treesitter.start, args.buf, lang)
        if ok then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
