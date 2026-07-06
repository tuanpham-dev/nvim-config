-- Replaces neoclide/coc.nvim with Neovim's native LSP client
-- (vim.lsp.config/vim.lsp.enable, Nvim >= 0.11 — the old
-- require('lspconfig').<server>.setup{} framework is deprecated/removed).
return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = {
        "ts_ls",
        "cssls",
        "html",
        "jsonls",
        "emmet_language_server",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      -- Merge nvim-cmp's extra completion capabilities into every server
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })

      -- Emmet, with the same includeLanguages mapping coc-settings.json used
      vim.lsp.config("emmet_language_server", {
        filetypes = {
          "css",
          "html",
          "javascriptreact",
          "typescriptreact",
          "liquid",
        },
        init_options = {
          includeLanguages = {
            ["vue-html"] = "html",
            javascript = "javascriptreact",
            liquid = "html",
          },
        },
      })

      -- Shopify Liquid/theme-check language server. Requires the Shopify
      -- CLI to be installed (`npm i -g @shopify/cli`, or the Mason package
      -- "shopify-cli"); it bundles Theme Check so no separate theme_check
      -- server is needed.
      vim.lsp.enable("shopify_theme_ls")

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          -- Not covered by Nvim's built-in LSP defaults (see :h lsp-defaults,
          -- which already binds grn/grr/gra/gri/grt/K etc.)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })
    end,
  },
}
