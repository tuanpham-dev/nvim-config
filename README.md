# nvim-config

Personal Neovim configuration, managed with [lazy.nvim](https://github.com/folke/lazy.nvim).

## Install

```
curl -fsSL https://raw.githubusercontent.com/tuanpham-dev/nvim-config/main/install.sh | bash
```

This clones the repo to `~/.local/share/nvim-config`, symlinks `~/.config/nvim` to it (backing up any existing config first), and installs all plugins. Safe to re-run — it updates the existing install instead of failing.

### Requirements

- Neovim 0.12+
- `git`
- A C compiler + `make` (for building treesitter parsers and `telescope-fzf-native`)
- `ripgrep` (for Telescope live grep)
- Node.js (for Mason to install LSP servers: `ts_ls`, `cssls`, `html`, `jsonls`, `emmet_language_server`)

The installer checks all of these and warns about anything missing.

### After installing

Open `nvim` — Mason installs the configured LSP servers on first launch. Run `:checkhealth` to confirm everything is wired up correctly.

## Updating

Re-run the install command above at any time, or:

```
git -C ~/.local/share/nvim-config pull --ff-only
```
