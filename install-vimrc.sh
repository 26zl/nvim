#!/usr/bin/env sh
# Install the plain-Vim companion config on a server (Linux / macOS):
#   curl -fsSL https://github.com/26zl/nvim/raw/main/install-vimrc.sh | sh
#
# Writes ~/.vimrc (backing up an existing one first) so stock Vim mirrors the
# muscle memory of this Neovim config. No plugins, no Neovim required.
set -eu

dest="$HOME/.vimrc"
url="https://github.com/26zl/nvim/raw/main/vimrc"

command -v vim >/dev/null 2>&1 || echo "Note: vim not on PATH — installing anyway for when it is."

if [ -f "$dest" ]; then
  bak="$dest.bak-$(date +%Y%m%d-%H%M%S)"
  echo "==> existing ~/.vimrc found - backing up to $bak"
  cp "$dest" "$bak"
fi

echo "==> downloading vimrc -> $dest"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$dest"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$dest" "$url"
else
  echo "need curl or wget to download"; exit 1
fi

echo "Done. Launch 'vim' - it now mirrors this Neovim setup's basics."
