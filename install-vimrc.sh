#!/usr/bin/env sh
# Installs the plugin-free Vim companion config on Linux or macOS.
set -eu

dest="$HOME/.vimrc"
url="https://github.com/26zl/nvim/raw/main/vimrc"
tmp=$(mktemp "$HOME/.vimrc.tmp.XXXXXX")

cleanup() {
  if [ -n "$tmp" ] && [ -e "$tmp" ]; then
    rm -f -- "$tmp"
  fi
}
trap cleanup EXIT
trap 'cleanup; exit 1' HUP INT TERM

command -v vim >/dev/null 2>&1 || echo "Note: vim not on PATH — installing anyway for when it is."

echo "==> downloading vimrc"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$tmp"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$tmp" "$url"
else
  echo "need curl or wget to download"
  exit 1
fi

[ -s "$tmp" ] || {
  echo "downloaded vimrc is empty"
  exit 1
}

if [ -e "$dest" ] || [ -L "$dest" ]; then
  [ -f "$dest" ] || {
    echo "$dest exists but is not a regular file"
    exit 1
  }
  bak="$dest.bak-$(date +%Y%m%d-%H%M%S)-$$"
  echo "==> existing ~/.vimrc found - backing up to $bak"
  cp "$dest" "$bak"
fi

mv "$tmp" "$dest"
tmp=
echo "Done. Launch 'vim' - it now mirrors this Neovim setup's basics."
