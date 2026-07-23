#!/usr/bin/env sh
# Installs this config on Linux, macOS, or WSL.
set -eu

repo="https://github.com/26zl/nvim"
dest="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
staging=

cleanup() {
  if [ -n "$staging" ] && [ -e "$staging" ]; then
    rm -rf -- "$staging"
  fi
}
trap cleanup EXIT
trap 'cleanup; exit 1' HUP INT TERM

command -v git >/dev/null 2>&1 || {
  echo "git not found - install it first."
  exit 1
}
command -v nvim >/dev/null 2>&1 || echo "Note: Neovim not on PATH - install a supported version before launching (see README)."

origin=
if [ -d "$dest/.git" ]; then
  origin=$(git -C "$dest" remote get-url origin 2>/dev/null || true)
fi

is_repo=false
case "$origin" in
  https://github.com/26zl/nvim | https://github.com/26zl/nvim.git | git@github.com:26zl/nvim | git@github.com:26zl/nvim.git | ssh://git@github.com/26zl/nvim | ssh://git@github.com/26zl/nvim.git)
    is_repo=true
    ;;
esac

if [ "$is_repo" = true ]; then
  echo "==> updating existing config: $dest"
  if [ -f "$dest/lazy-lock.json" ] && [ -z "$(git -C "$dest" ls-files lazy-lock.json)" ]; then
    mv -f "$dest/lazy-lock.json" "$dest/lazy-lock.json.bak"
  fi
  git -C "$dest" fetch origin main
  git -C "$dest" merge --ff-only FETCH_HEAD
else
  parent=$(dirname "$dest")
  mkdir -p "$parent"
  staging=$(mktemp -d "$parent/.nvim-install.XXXXXX")
  echo "==> cloning $repo"
  git clone "$repo" "$staging"

  backup=
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    bak="$dest.bak-$(date +%Y%m%d-%H%M%S)-$$"
    echo "==> existing config found - backing up to $bak"
    mv "$dest" "$bak"
    backup=$bak
  fi

  if ! mv "$staging" "$dest"; then
    if [ -n "$backup" ] && [ ! -e "$dest" ]; then
      mv "$backup" "$dest"
    fi
    exit 1
  fi
  staging=
fi

echo "Done. Launch 'nvim' - plugins install on first run."
