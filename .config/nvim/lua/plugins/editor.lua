return {
  -- File explorer (replaces preservim/nerdtree + vim-nerdtree-tabs +
  -- nerdtree-git-plugin)
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = {
      renderer = {
        -- No nerd-font glyphs; git status is still shown via highlighting.
        highlight_git = true,
        icons = { show = { file = false, folder = false, folder_arrow = false, git = false } },
      },
      filters = { dotfiles = false },
    },
    config = function(_, opts)
      require("nvim-tree").setup(opts)

      -- Close nvim-tree if it's the last window left in the tab
      vim.api.nvim_create_autocmd("QuitPre", {
        callback = function()
          local wins = vim.api.nvim_list_wins()
          local invalid_wins = {}
          for _, w in ipairs(wins) do
            local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
            if bufname:match("NvimTree_") ~= nil then
              table.insert(invalid_wins, w)
            end
          end
          if #invalid_wins == #wins - 1 then
            for _, w in ipairs(invalid_wins) do
              vim.api.nvim_win_close(w, true)
            end
          end
        end,
      })
    end,
  },

  -- Fuzzy finder (replaces junegunn/fzf + junegunn/fzf.vim)
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    opts = {
      defaults = {
        layout_config = { horizontal = { preview_width = 0.6 }, height = 0.7 },
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      require("telescope").load_extension("fzf")
    end,
  },

  -- Git gutter signs (replaces airblade/vim-gitgutter)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,
      },
      current_line_blame_formatter = "  <author>, <author_time:%Y-%m-%d> - <summary>",
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")
        vim.keymap.set("n", "<leader>gb", gitsigns.toggle_current_line_blame, { buffer = bufnr, desc = "Toggle inline git blame" })
        vim.keymap.set("n", "<leader>gB", function() gitsigns.blame_line({ full = true }) end, { buffer = bufnr, desc = "Show full git blame for line" })
      end,
    },
  },

  -- Git commands (kept as-is, still the most complete Git plugin)
  { "tpope/vim-fugitive", cmd = { "G", "Git", "Gdiffsplit", "Gvdiffsplit" } },

  -- VS Code-style merge conflict resolution: highlighted current/incoming
  -- sections with inline "(Current changes)"/"(Incoming changes)" labels,
  -- next/prev navigation (]x/[x), accept current/incoming/both/none
  -- (co/ct/cb/c0), and a quickfix list of all conflicts.
  {
    "akinsho/git-conflict.nvim",
    event = "BufReadPost",
    opts = {
      default_mappings = true,
      default_commands = true,
      disable_diagnostics = false,
      highlights = {
        current = "DiffText",
        incoming = "DiffAdd",
      },
    },
    config = function(_, opts)
      require("git-conflict").setup(opts)
      require("config.conflict_buttons").setup()

      -- git-conflict fires these as plain `User` autocmds with no buffer
      -- data attached, so buffer resolution inside any listener has to use
      -- nvim_get_current_buf() (the pattern its own internal handlers use),
      -- which is valid here since the event always fires while that buffer
      -- is current.
      vim.api.nvim_create_autocmd("User", {
        pattern = { "GitConflictDetected", "GitConflictResolved" },
        callback = function()
          local ok, lualine = pcall(require, "lualine")
          if ok then
            lualine.refresh()
          end
        end,
      })

      vim.keymap.set("n", "<leader>gc", "<cmd>GitConflictListQf<cr>", { desc = "List git conflicts (quickfix)" })
      vim.keymap.set("n", "<leader>gm", "<cmd>Gdiffsplit!<cr>", { desc = "3-way compare (merge conflict)" })
    end,
  },

  -- Surround motions (replaces tpope/vim-surround + tpope/vim-repeat)
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  -- Commenting (replaces tpope/vim-commentary)
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Auto-close/rename HTML/JSX tags, treesitter-based (replaces
  -- alvan/vim-closetag)
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {},
  },

  -- Editorconfig support ships natively in Neovim (vim.g.editorconfig is
  -- true by default), so editorconfig/editorconfig-vim is no longer needed.
}
