# nvim-config

Personal Neovim configuration, managed with [lazy.nvim](https://github.com/folke/lazy.nvim).

## Install

```
curl -fsSL https://raw.githubusercontent.com/tuanpham-dev/nvim-config/main/install.sh | bash
```

This clones the repo to `~/.local/share/nvim-config`, symlinks `~/.config/nvim` to it (backing up any existing config first), and installs all plugins. Safe to re-run — it updates the existing install instead of failing.

If you just pushed a change to `install.sh` and re-running picks up the old behavior, GitHub's raw-content CDN is likely still serving a cached copy (typically clears in a few minutes). Force a fresh fetch instead of waiting:

```
curl -fsSL "https://raw.githubusercontent.com/tuanpham-dev/nvim-config/main/install.sh?$(date +%s)" | bash
```

### Requirements

- `git`
- A C compiler + `make` (for building treesitter parsers and `telescope-fzf-native`)
- `ripgrep` (for Telescope live grep)
- Node.js (for Mason to install LSP servers: `ts_ls`, `cssls`, `html`, `jsonls`, `emmet_language_server`)

The installer downloads these automatically if missing, since a fresh machine usually won't have either yet:
- **Neovim 0.12+** — treesitter's `main` branch requires it and crashes on older versions. Downloaded from the [official releases](https://github.com/neovim/neovim/releases) to `~/.local/opt/nvim-<platform>`, symlinked into `~/.local/bin/nvim`.
- **tree-sitter CLI** — most parsers (`lua`, `json`, `html`, `css`, `vim`, `markdown`, `vimdoc`) need the standalone CLI to compile, not just a C compiler. Downloaded from [tree-sitter releases](https://github.com/tree-sitter/tree-sitter/releases) to `~/.local/bin/tree-sitter`.

Everything else (C toolchain, ripgrep, Node.js) is checked and warned about, not auto-installed.

If `~/.local/bin` isn't on your `PATH` (or is, but after an older system `nvim`), the installer warns you to fix your shell profile — it still works for the current run either way.

### After installing

Open `nvim` — Mason installs the configured LSP servers on first launch. Run `:checkhealth` to confirm everything is wired up correctly.

## Updating

Re-run the install command above at any time, or:

```
git -C ~/.local/share/nvim-config pull --ff-only
```
