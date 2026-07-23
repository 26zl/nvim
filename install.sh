#!/usr/bin/env sh
# One-line install of this Neovim config (Linux / macOS / WSL):
#   curl -fsSL https://github.com/26zl/nvim/raw/main/install.sh | sh
#
# Clones the repo into ${XDG_CONFIG_HOME:-~/.config}/nvim. An existing config is
# backed up first; if it's already this repo it just fast-forwards (git pull). It
# installs the CONFIG, not Neovim - install Neovim 0.11+ separately (see README;
# on Debian/Ubuntu apt's is too old, use the official tarball). Launch `nvim`
# afterwards and lazy.nvim installs the plugins on first run.
set -eu

repo="https://github.com/26zl/nvim"
dest="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

command -v git >/dev/null 2>&1 || { echo "git not found - install it first."; exit 1; }
command -v nvim >/dev/null 2>&1 || echo "Note: Neovim not on PATH - install 0.11+ before launching (see README)."

if [ -d "$dest/.git" ] && git -C "$dest" remote get-url origin 2>/dev/null | grep -q '26zl/nvim'; then
  echo "==> updating existing config: $dest"
  # a lockfile lazy.nvim generated before the repo tracked it blocks the merge; the repo's pinned one wins
  if [ -f "$dest/lazy-lock.json" ] && [ -z "$(git -C "$dest" ls-files lazy-lock.json)" ]; then
    mv -f "$dest/lazy-lock.json" "$dest/lazy-lock.json.bak"
  fi
  git -C "$dest" pull --ff-only
else
  if [ -e "$dest" ]; then
    bak="$dest.bak-$(date +%Y%m%d-%H%M%S)"
    echo "==> existing config found - backing up to $bak"
    mv "$dest" "$bak"
  fi
  echo "==> cloning $repo -> $dest"
  git clone "$repo" "$dest"
fi

echo "Done. Launch 'nvim' - plugins install on first run."
