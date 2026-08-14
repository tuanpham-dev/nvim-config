return {
  -- Statusline (replaces itchyny/lightline.vim)
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "auto",
        globalstatus = false,
        icons_enabled = false,
        -- Gitsigns debounces current-line blame updates (see the
        -- current_line_blame_opts.delay in plugins/editor.lua) and only
        -- writes the result to vim.b.gitsigns_blame_line_dict once that
        -- timer fires, with no event to notify listeners. Lualine's default
        -- statusline poll is 1000ms, so without this it can lag a full
        -- second behind the inline blame text. Polling every 100ms keeps
        -- the two in sync.
        refresh = { statusline = 100 },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          "branch",
          { "filename", path = 0 },
          "diff",
          function()
            -- conflict_count() can throw (not just return 0) in the brief
            -- window right after a conflicted buffer opens, before
            -- git-conflict's async git-root detection has populated its
            -- internal state -- verified by hitting it directly. Guard the
            -- call itself, not just the require.
            local ok, count = pcall(function()
              return require("git-conflict").conflict_count(0)
            end)
            if not ok or count == 0 then
              return ""
            end
            return "Conflicts: " .. count
          end,
        },
        lualine_c = {
          function()
            local blame = vim.b.gitsigns_blame_line_dict
            if not blame or not blame.abbrev_sha then
              return ""
            end
            return blame.abbrev_sha
          end,
        },
        lualine_x = {},
        lualine_y = { "fileformat", "encoding", "filetype" },
        lualine_z = { "progress", "location" },
      },
    },
  },

  -- Indentation guides (already Lua; ported to the current ibl v3 API)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "BufReadPost",
    opts = {
      indent = { char = "│", highlight = "IndentGuides" },
      scope = { enabled = false },
    },
  },

  -- Dashboard (Lua port of mhinz/vim-startify, using the startify theme)
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
      local startify = require("alpha.themes.startify")
      -- No nerd-font/devicons file icons in the MRU list.
      startify.file_icons.enabled = false
      require("alpha").setup(startify.config)
    end,
  },

  -- VS Code-style scrollbar with colored git-hunk marks on the right edge
  -- (add/change/delete from gitsigns). The gitsigns handler is a separate
  -- module that must be required and set up on its own -- setting
  -- handlers.gitsigns = true alone does not wire it up.
  {
    "petertriho/nvim-scrollbar",
    event = "BufReadPost",
    dependencies = { "lewis6991/gitsigns.nvim" },
    opts = {
      handlers = {
        gitsigns = true,
      },
    },
    config = function(_, opts)
      require("scrollbar").setup(opts)
      require("scrollbar.handlers.gitsigns").setup()
    end,
  },

  -- Session management (replaces vim-startify's session save/restore)
  {
    "folke/persistence.nvim",
    event = "VimEnter",
    opts = {
      dir = vim.fn.stdpath("config") .. "/sessions/",
    },
    config = function(_, opts)
      require("persistence").setup(opts)
      -- Auto-restore the last session on a bare `nvim` launch, mirroring
      -- vim-startify's startify_session_autoload = 1. Deferred via
      -- vim.schedule so the session's :source doesn't wipe the initial
      -- buffer while lazy.nvim is still processing this same VimEnter
      -- event (otherwise lazy errors with "Invalid buffer id: 1").
      if vim.fn.argc() == 0 then
        vim.schedule(function()
          require("persistence").load()
        end)
      end
    end,
  },
}
