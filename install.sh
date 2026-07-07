#!/usr/bin/env bash
# nvim-config installer — clones the repo and symlinks ~/.config/nvim to it.
# No sudo; everything lives under $HOME. Safe to re-run: it updates an
# existing install instead of failing.
#
#   curl -fsSL https://raw.githubusercontent.com/tuanpham-dev/nvim-config/main/install.sh | bash
#
# Override the source repo or install location for testing/forks:
#   NVIM_CONFIG_REPO=/path/to/repo NVIM_CONFIG_DIR=/tmp/ncfg bash install.sh
set -euo pipefail

REPO_URL="${NVIM_CONFIG_REPO:-https://github.com/tuanpham-dev/nvim-config.git}"
INSTALL_DIR="${NVIM_CONFIG_DIR:-$HOME/.local/share/nvim-config}"
NVIM_CONFIG_TARGET="$HOME/.config/nvim"

if [ -t 1 ]; then
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
  C_GREEN=""; C_YELLOW=""; C_RED=""; C_BOLD=""; C_RESET=""
fi
ok()   { printf '%s[ ok ]%s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
warn() { printf '%s[warn]%s %s\n' "$C_YELLOW" "$C_RESET" "$1"; }
die()  { printf '%s[fail]%s %s\n' "$C_RED" "$C_RESET" "$1" >&2; exit 1; }
heading() { printf '\n%s%s%s\n' "$C_BOLD" "$1" "$C_RESET"; }

heading "Checking dependencies"

command -v git >/dev/null 2>&1 || die "git not found — install it via your package manager"
ok "git found"

command -v nvim >/dev/null 2>&1 || die "nvim not found — install Neovim 0.12+ first (https://github.com/neovim/neovim/releases)"
NVIM_VERSION="$(nvim --version | head -n1 | sed -E 's/^NVIM v//')"
NVIM_MAJOR="$(echo "$NVIM_VERSION" | cut -d. -f1)"
NVIM_MINOR="$(echo "$NVIM_VERSION" | cut -d. -f2)"
if [ "$NVIM_MAJOR" -eq 0 ] 2>/dev/null && [ "$NVIM_MINOR" -lt 12 ] 2>/dev/null; then
  die "nvim $NVIM_VERSION found, but 0.12+ is required (treesitter's main branch crashes on older versions) — https://github.com/neovim/neovim/releases"
fi
ok "nvim $NVIM_VERSION"

TOOLCHAIN_OK=1
{ command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 || command -v clang >/dev/null 2>&1; } || TOOLCHAIN_OK=0
command -v make >/dev/null 2>&1 || TOOLCHAIN_OK=0
if [ "$TOOLCHAIN_OK" -eq 1 ]; then
  ok "C toolchain + make found"
else
  warn "missing a C compiler and/or make — treesitter parsers and telescope-fzf-native won't build. Debian/Ubuntu: apt install build-essential. macOS: xcode-select --install"
fi

command -v rg >/dev/null 2>&1 && ok "ripgrep found" || warn "ripgrep (rg) not found — Telescope's live grep won't work. Debian/Ubuntu: apt install ripgrep. macOS: brew install ripgrep"

command -v node >/dev/null 2>&1 && ok "node found" || warn "node not found — Mason can't install the LSP servers (ts_ls, cssls, html, jsonls, emmet_language_server) without it. Install Node.js: https://nodejs.org"

heading "Installing to $INSTALL_DIR"

if [ -d "$INSTALL_DIR/.git" ]; then
  ok "existing install found — updating"
  git -C "$INSTALL_DIR" pull --ff-only
else
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi
ok "source ready"

heading "Linking ~/.config/nvim"

if [ -L "$NVIM_CONFIG_TARGET" ] && [ "$(readlink "$NVIM_CONFIG_TARGET")" = "$INSTALL_DIR/.config/nvim" ]; then
  ok "already linked"
elif [ -e "$NVIM_CONFIG_TARGET" ]; then
  BACKUP="$NVIM_CONFIG_TARGET.bak.$(date +%Y%m%d%H%M%S)"
  mv "$NVIM_CONFIG_TARGET" "$BACKUP"
  warn "existing ~/.config/nvim moved to $BACKUP"
  mkdir -p "$(dirname "$NVIM_CONFIG_TARGET")"
  ln -s "$INSTALL_DIR/.config/nvim" "$NVIM_CONFIG_TARGET"
  ok "linked ~/.config/nvim -> $INSTALL_DIR/.config/nvim"
else
  mkdir -p "$(dirname "$NVIM_CONFIG_TARGET")"
  ln -s "$INSTALL_DIR/.config/nvim" "$NVIM_CONFIG_TARGET"
  ok "linked ~/.config/nvim -> $INSTALL_DIR/.config/nvim"
fi

heading "Installing plugins"
nvim --headless "+Lazy! install" +qa 2>&1 | tail -n +1 || warn "plugin install reported issues — run :Lazy inside nvim to check"
ok "plugins installed"

heading "Done"
echo "Open nvim — Mason will install the configured LSP servers on first launch."
echo "Run :checkhealth inside nvim to confirm everything is wired up correctly."
