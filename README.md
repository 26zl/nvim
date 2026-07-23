# nvim

[![ci](https://github.com/26zl/nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/26zl/nvim/actions/workflows/ci.yml)
[![Neovim 0.11.3+](https://img.shields.io/badge/Neovim-0.11.3%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io)
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

- **Neovim 0.11.3 or newer** (0.11.x and 0.12.x). Older versions are rejected up
  front instead of starting in a broken state. CI smoke-tests 0.11.3, the latest
  0.11 release, and 0.12.
- **git**, a **C compiler**, `make` on Unix or **CMake** on Windows (Treesitter +
  fzf-native), **ripgrep** + **fd**
  (Telescope), a **clipboard provider** (`wl-clipboard` or `xclip` on Linux; built in
  on macOS/Windows) for the system clipboard, and a **Nerd Font** in your terminal for icons
- **Rust/Cargo** when Mason should install the Nix language server outside NixOS

## Install

The simplest auditable installation is a manual clone:

```sh
mkdir -p ~/.config
git clone https://github.com/26zl/nvim ~/.config/nvim   # Linux / macOS / WSL
```

```powershell
git clone https://github.com/26zl/nvim $env:LOCALAPPDATA\nvim   # Windows
```

The installer scripts back up a non-repository config, clone through a staging
directory, and fast-forward an existing official clone. Download and review the
script before running it because `main` is a mutable source.

**Windows (PowerShell):**

```powershell
$installer = Join-Path $env:TEMP 'install-nvim.ps1'
Invoke-WebRequest https://github.com/26zl/nvim/raw/main/install.ps1 -OutFile $installer
Get-Content $installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer
Remove-Item $installer
```

**Linux / macOS / WSL:**

```sh
installer=$(mktemp)
curl -fsSL https://github.com/26zl/nvim/raw/main/install.sh -o "$installer"
less "$installer"
sh "$installer"
rm "$installer"
```

The scripts install the config, not Neovim or its system dependencies. Launch
`nvim` after installation; plugins install on first run.

Run `:Mason` afterwards to watch the language servers install (on NixOS they come from your system config instead).

On distributions whose package manager ships an older Neovim, grab a current
build from the official [Neovim releases](https://github.com/neovim/neovim/releases)
(0.11.3 or newer) and verify the asset's published SHA-256 digest before installing.

## Plain Vim on servers

SSH into a box with only stock `vim`? This repo ships a **plugin-free [`vimrc`](vimrc)**
that mirrors the muscle memory of `init.lua` — Space leader, `<leader>w` / `<leader>q`,
relative numbers, smart-case search, `<Esc>` clears highlight, 2-space indent, persistent
undo — so vanilla Vim on any Linux server doesn't feel alien. No plugins, and it guards
version-specific options so it degrades cleanly on older Vim builds (whatever your distro ships).

```sh
installer=$(mktemp)
curl -fsSL https://github.com/26zl/nvim/raw/main/install-vimrc.sh -o "$installer"
less "$installer"
sh "$installer"   # downloads atomically and backs up an existing ~/.vimrc
rm "$installer"
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

The repository installer uses an explicit fast-forward from `origin/main`; it
will not merge or overwrite divergent local work. Plugin revisions, including
`lazy.nvim` itself, are restored from `lazy-lock.json`.

## Rollback and local state

A replaced config is kept beside the active directory as
`nvim.bak-<timestamp>-<process-id>` (or the corresponding Windows path). To
restore it, move the current directory aside and rename the chosen backup to
`nvim`. Before reverting an updated Git clone, inspect `git reflog` and preserve
any local changes.

Neovim and Vim use persistent undo, which can retain earlier contents of edited
files locally. Use `:setlocal noundofile` before editing sensitive material when
that retention is undesirable.
