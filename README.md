# nvim

[![ci](https://github.com/26zl/nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/26zl/nvim/actions/workflows/ci.yml)
[![Neovim 0.11+](https://img.shields.io/badge/Neovim-0.11%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A portable single-file Neovim config (`init.lua`) — the **same setup on any Linux,
macOS, WSL and Windows**. [lazy.nvim](https://github.com/folke/lazy.nvim) manages
plugins, and [Mason](https://github.com/mason-org/mason.nvim) installs the LSP servers
automatically.

## What's inside

- **Nordic** theme (Nord-based), lualine statusline, **bufferline** tabs, which-key (press a key, see what's next)
- **Telescope** (files / live-grep / buffers), **neo-tree** file explorer
- **Treesitter** syntax (auto-installs a parser for any language you open), gitsigns, **lazygit**, indent guides, todo-comments, trouble
- **LSP + completion** (nvim-cmp) for lua, python, ts/js, go, rust, nix, bash,
  yaml, docker, ansible, terraform, c/c++, markdown — add any other via `:Mason`
- **Format-on-save** via conform.nvim (stylua, black/isort, shfmt, prettier, …)
- **mini.nvim**: extra text objects, surround, autopairs
- **Terminal** in a split (`<leader>t`) for logs / commands beside your code

## Requirements

- **Neovim ≥ 0.11** (uses `vim.lsp.config` / `vim.lsp.enable`) — grab the official
  [release tarball or AppImage](https://github.com/neovim/neovim/releases) if your
  package manager ships something older.
- **git**, a **C compiler** (Treesitter + fzf-native build), **ripgrep** + **fd**
  (Telescope), a **clipboard provider** (`wl-clipboard` or `xclip` on Linux; built in
  on macOS/Windows) for the system clipboard, and a **Nerd Font** in your terminal for icons

## Install

One-liner — **backs up any existing config**, clones to the right path, and fast-forwards
(`git pull`) if it's already installed. Then launch `nvim`; plugins install on first run.

**Windows (PowerShell):**

```powershell
irm https://github.com/26zl/nvim/raw/main/install.ps1 | iex
```

**Linux / macOS / WSL:**

```sh
curl -fsSL https://github.com/26zl/nvim/raw/main/install.sh | sh
```

> These fetch and run a script from this repo — read [`install.ps1`](install.ps1) /
> [`install.sh`](install.sh) first if you don't trust them. They install the **config**,
> not Neovim itself: install Neovim **0.11+** and the deps separately (see Requirements).

Run `:Mason` afterwards to watch the language servers install (on NixOS they come from your system config instead).

### Manual clone

```sh
git clone https://github.com/26zl/nvim ~/.config/nvim   # Linux / macOS / WSL
```

```powershell
git clone https://github.com/26zl/nvim $env:LOCALAPPDATA\nvim   # Windows
```

On **WSL / Debian / Ubuntu**, install the deps and a current Neovim first:

```sh
sudo apt update && sudo apt install -y git curl ripgrep fd-find build-essential unzip
curl -fsSLo /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf /tmp/nvim.tar.gz && sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
```

> On **ARM Linux (aarch64)**, swap `x86_64` → `arm64` in both lines above.

## Plain Vim on servers

SSH into a box with only stock `vim`? This repo ships a **plugin-free [`vimrc`](vimrc)**
that mirrors the muscle memory of `init.lua` — Space leader, `<leader>w` / `<leader>q`,
relative numbers, smart-case search, `<Esc>` clears highlight, 2-space indent, persistent
undo — so vanilla Vim on any Linux server doesn't feel alien. No plugins, and it guards
version-specific options so it degrades cleanly on older Vim builds (whatever your distro ships).

```sh
curl -fsSL https://github.com/26zl/nvim/raw/main/install-vimrc.sh | sh   # backs up ~/.vimrc, then installs
# from a clone instead:  cp vimrc ~/.vimrc
```

## Keys (leader = <kbd>Space</kbd>)

| Key                        | Action                        |
| -------------------------- | ----------------------------- |
| `<leader>ff` / `<leader>fg`| find files / grep project     |
| `<leader>e`                | toggle file tree              |
| `gd` / `gr` / `K`          | definition / references / hover |
| `gI` / `gy`                | implementation / type definition |
| `<leader>ca` / `<leader>rn`| code action / rename          |
| `<leader>lf`               | format buffer                 |
| `gc` / `gcc`               | comment (built-in)            |
| `<leader>xx`               | diagnostics (Trouble)         |
| `<leader>t`                | terminal (bottom split)       |
| `[b` / `]b`                | previous / next buffer        |
| `<leader>gg`               | lazygit (needs the binary)    |
| `<leader>ih`               | toggle inlay hints            |

> Install [`lazygit`](https://github.com/jesseduffield/lazygit) for `<leader>gg` — e.g.
> `winget install lazygit`, `brew install lazygit`, `dnf install lazygit`, `pacman -S lazygit`.

## Add a language

Open a file and **Treesitter installs its parser automatically**. For LSP + completion,
run `:Mason`, install the server, and it's enabled on the next launch — no config edit.
Formatters: add one line under `formatters_by_ft` in `init.lua`, or let the LSP format
(the built-in fallback).

## Updating

```text
:Lazy sync     # update plugins  (commit the refreshed lazy-lock.json to pin them)
:TSUpdate      # update Treesitter parsers
:checkhealth   # verify everything is wired up
```
