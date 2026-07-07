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

NVIM_OPT_DIR="$HOME/.local/opt"
NVIM_BIN_DIR="$HOME/.local/bin"

nvim_version_ok() {
  command -v nvim >/dev/null 2>&1 || return 1
  local v major minor
  v="$(nvim --version | head -n1 | sed -E 's/^NVIM v//')"
  major="$(echo "$v" | cut -d. -f1)"
  minor="$(echo "$v" | cut -d. -f2)"
  [ "$major" -gt 0 ] 2>/dev/null && return 0
  [ "$minor" -ge 12 ] 2>/dev/null
}

install_nvim() {
  local os arch asset
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Linux)
      case "$arch" in
        x86_64) asset="nvim-linux-x86_64" ;;
        aarch64 | arm64) asset="nvim-linux-arm64" ;;
        *) die "no prebuilt Neovim release for Linux/$arch — build from source: https://github.com/neovim/neovim/blob/master/BUILD.md" ;;
      esac
      ;;
    Darwin)
      case "$arch" in
        x86_64) asset="nvim-macos-x86_64" ;;
        arm64) asset="nvim-macos-arm64" ;;
        *) die "no prebuilt Neovim release for macOS/$arch — build from source: https://github.com/neovim/neovim/blob/master/BUILD.md" ;;
      esac
      ;;
    *) die "no prebuilt Neovim release for $os — build from source: https://github.com/neovim/neovim/blob/master/BUILD.md" ;;
  esac

  command -v curl >/dev/null 2>&1 || die "curl not found — needed to download Neovim"
  command -v tar >/dev/null 2>&1 || die "tar not found — needed to extract Neovim"

  local url="https://github.com/neovim/neovim/releases/latest/download/$asset.tar.gz"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  echo "Downloading $url"
  curl -fsSL "$url" -o "$tmp/nvim.tar.gz" || die "download failed — check your connection or install manually: https://github.com/neovim/neovim/releases"
  tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"

  local extracted="$tmp/$asset"
  [ -d "$extracted" ] || extracted="$(find "$tmp" -maxdepth 1 -mindepth 1 -type d | head -n1)"
  [ -d "$extracted" ] || die "couldn't find extracted Neovim directory in the downloaded archive"

  mkdir -p "$NVIM_OPT_DIR" "$NVIM_BIN_DIR"
  rm -rf "$NVIM_OPT_DIR/$asset"
  mv "$extracted" "$NVIM_OPT_DIR/$asset"
  ln -sf "$NVIM_OPT_DIR/$asset/bin/nvim" "$NVIM_BIN_DIR/nvim"

  # Prepend unconditionally (not just when absent) so this freshly-installed
  # binary wins over any older `nvim` earlier in PATH (e.g. an apt-installed
  # one) for the rest of this script. Only warn about the shell profile if
  # it's missing from PATH entirely -- if it's already there but merely not
  # first, prepending here is enough for THIS run, but their normal shell
  # sessions still need it, so still worth flagging that ordering issue.
  case ":$PATH:" in
    *":$NVIM_BIN_DIR:"*)
      if [ "$(command -v nvim)" != "$NVIM_BIN_DIR/nvim" ]; then
        warn "$NVIM_BIN_DIR is on your PATH but not first — an older nvim earlier in PATH will still run instead. Move it earlier in your shell profile."
      fi
      ;;
    *) warn "$NVIM_BIN_DIR is not on your PATH — add this to your shell profile: export PATH=\"$NVIM_BIN_DIR:\$PATH\"" ;;
  esac
  export PATH="$NVIM_BIN_DIR:$PATH"
}

if nvim_version_ok; then
  ok "nvim $(nvim --version | head -n1 | sed -E 's/^NVIM v//') found"
else
  if command -v nvim >/dev/null 2>&1; then
    warn "nvim $(nvim --version | head -n1 | sed -E 's/^NVIM v//') found, but 0.12+ is required (treesitter's main branch crashes on older versions) — installing the latest release"
  else
    warn "nvim not found — installing the latest release"
  fi
  install_nvim
  nvim_version_ok || die "installed Neovim but still can't find a working 0.12+ binary — check $NVIM_BIN_DIR/nvim manually"
  ok "nvim $(nvim --version | head -n1 | sed -E 's/^NVIM v//') installed to $NVIM_BIN_DIR/nvim"
fi

TOOLCHAIN_OK=1
{ command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 || command -v clang >/dev/null 2>&1; } || TOOLCHAIN_OK=0
command -v make >/dev/null 2>&1 || TOOLCHAIN_OK=0
if [ "$TOOLCHAIN_OK" -eq 1 ]; then
  ok "C toolchain + make found"
else
  warn "missing a C compiler and/or make — treesitter parsers and telescope-fzf-native won't build. Debian/Ubuntu: apt install build-essential. macOS: xcode-select --install"
fi

install_tree_sitter_cli() {
  local os arch asset
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Linux)
      case "$arch" in
        x86_64) asset="tree-sitter-linux-x64" ;;
        aarch64 | arm64) asset="tree-sitter-linux-arm64" ;;
        *) warn "no prebuilt tree-sitter CLI for Linux/$arch — most treesitter parsers (lua, json, html, css, vim, markdown, vimdoc) won't compile without it: https://github.com/tree-sitter/tree-sitter/releases"; return 1 ;;
      esac
      ;;
    Darwin)
      case "$arch" in
        x86_64) asset="tree-sitter-macos-x64" ;;
        arm64) asset="tree-sitter-macos-arm64" ;;
        *) warn "no prebuilt tree-sitter CLI for macOS/$arch — most treesitter parsers (lua, json, html, css, vim, markdown, vimdoc) won't compile without it: https://github.com/tree-sitter/tree-sitter/releases"; return 1 ;;
      esac
      ;;
    *) warn "no prebuilt tree-sitter CLI for $os — most treesitter parsers (lua, json, html, css, vim, markdown, vimdoc) won't compile without it: https://github.com/tree-sitter/tree-sitter/releases"; return 1 ;;
  esac

  local url="https://github.com/tree-sitter/tree-sitter/releases/latest/download/$asset.gz"
  mkdir -p "$NVIM_BIN_DIR"
  if ! curl -fsSL "$url" | gunzip > "$NVIM_BIN_DIR/tree-sitter"; then
    warn "failed to download tree-sitter CLI from $url — most treesitter parsers won't compile without it"
    rm -f "$NVIM_BIN_DIR/tree-sitter"
    return 1
  fi
  chmod +x "$NVIM_BIN_DIR/tree-sitter"
  # Prepend unconditionally so this binary is what nvim finds during the
  # rest of this script, same reasoning as install_nvim's PATH handling.
  export PATH="$NVIM_BIN_DIR:$PATH"
}

# Most nvim-treesitter "main"-branch parsers (lua, json, html, css, vim,
# markdown, vimdoc) shell out to the standalone tree-sitter CLI to compile —
# a C compiler alone isn't enough, and this dependency is easy to miss since
# a handful of parsers (javascript/jsx family) build fine without it.
if command -v tree-sitter >/dev/null 2>&1; then
  ok "tree-sitter CLI found"
else
  warn "tree-sitter CLI not found — installing the latest release"
  install_tree_sitter_cli && ok "tree-sitter CLI installed to $NVIM_BIN_DIR/tree-sitter"
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
# `:Lazy! install` blocks until plugin installs/builds finish, but
# nvim-treesitter's own parser installs (kicked off from its plugin config,
# not from lazy itself) run as fire-and-forget async jobs — quitting right
# after Lazy would leave most parsers (lua, json, html, css, vim, markdown,
# vimdoc) mid-compile, since compile time varies per parser and a "count
# stopped growing" stall-detection heuristic fires during the normal gaps
# between parsers finishing, not just at the end (verified empirically: it
# quit with only 2 of 11 parsers actually installed). Wait for this exact
# list instead — keep in sync with `ensure_installed` in
# lua/plugins/treesitter.lua.
TS_WAIT='
vim.wait(120000, function()
  local ok, cfg = pcall(require, "nvim-treesitter.config")
  if not ok then return true end
  local installed = cfg.get_installed()
  local want = {
    "javascript", "typescript", "tsx", "css", "json", "html",
    "lua", "vim", "vimdoc", "markdown", "markdown_inline",
  }
  for _, lang in ipairs(want) do
    if not vim.tbl_contains(installed, lang) then return false end
  end
  return true
end, 500)
'
nvim --headless "+Lazy! install" "+lua $TS_WAIT" +qa 2>&1 | tail -n +1 || warn "plugin install reported issues — run :Lazy inside nvim to check"
ok "plugins installed"

heading "Done"
echo "Open nvim — Mason will install the configured LSP servers on first launch."
echo "Run :checkhealth inside nvim to confirm everything is wired up correctly."
