return {
  -- Custom Liquid (Shopify) syntax/indent plugins — no Lua-native
  -- replacement needed, kept as-is.
  { "tuanpham-dev/vim-liquid", ft = "liquid" },
  { "tuanpham-dev/vim-html-indent", ft = { "html", "liquid" } },

  -- Forwards yanks to the client clipboard over OSC 52 (see the
  -- TextYankPost autocmd in config/autocmds.lua) — picked up by
  -- tmux-server's xterm-engine OSC 52 handler when running inside tmux/ssh.
  { "ojroques/vim-oscyank", branch = "main", event = "TextYankPost" },
}
