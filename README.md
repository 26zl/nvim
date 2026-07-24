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
- **Telescope** (files / live-grep / buffers / recent / resume), **neo-tree** file explorer
- **Treesitter** syntax (auto-installs a parser for any language you open), gitsigns, **lazygit**, indent guides, todo-comments, trouble
- **LSP + completion** (nvim-cmp) for lua, python, ts/js, go, rust, nix, bash,
  yaml, docker, ansible, terraform, c/c++, markdown — add any other via `:Mason`
- **Format-on-save** via conform.nvim (stylua, black/isort, shfmt, prettier, …) plus
  **linting** via nvim-lint (shellcheck, markdownlint); a linter you have not installed
  is skipped rather than reported as an error on every save
- **mini.nvim**: extra text objects, surround, autopairs
- **Undo tree** (`<leader>u`) over the persistent undo history
- **Terminal** in a split (`<leader>t`) for logs / commands beside your code
- Indentation is **read from the file** instead of forced, and files above 1.5 MB open
  without syntax, Treesitter or LSP so a stray log or dump stays usable

## Requirements

- **Neovim 0.11.3 or newer** (0.11.x and 0.12.x). Older versions are rejected up
  front instead of starting in a broken state. CI smoke-tests 0.11.3, the latest
  0.11 release, and 0.12.
- **git** and a **C toolchain** for Treesitter parsers and fzf-native: `make` + a C
  compiler on Linux/macOS/WSL; on **Windows** a MinGW toolchain — e.g. MSYS2's
  `mingw-w64-ucrt-x86_64-gcc` + `mingw-w64-ucrt-x86_64-make`, with `C:\msys64\ucrt64\bin` on `PATH`.
  **ripgrep** + **fd**
  (Telescope), a **clipboard provider** (`wl-clipboard` or `xclip` on Linux; built in
  on macOS/Windows) for the system clipboard, and a **Nerd Font** in your terminal for icons
- **A toolchain per language server.** Mason ships prebuilt binaries for lua, rust,
  c/c++ and markdown; the rest are installed through **Node** (python, ts/js, bash,
  yaml, docker, ansible, prettier), **Python** (black/isort), **Go** (gopls) or
  **Rust plus the `nix` binary** (nil — its build script calls `nix` for the builtins).
  `gopls` and `nil` are skipped when their toolchain is missing; the Node and Python
  ones report the failure in `:Mason`.

Run **`:CheckDeps`** inside Neovim for a line-by-line report of which of these
programs are actually on `PATH` — a gap shows up there instead of as a Treesitter
parser that never compiles or a `:Mason` build that quietly failed. `:checkhealth`
covers Neovim's own providers alongside it.

Without a Nerd Font, set `vim.g.have_nerd_font = false` near the top of `init.lua`:
icons fall back to ASCII everywhere instead of rendering as boxes.

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

When the full config *is* available on a server, `:SudaWrite` saves a root-owned file
through `sudo` without reopening Neovim as root, and `:SudaRead` reloads one you opened
without permission to read.

## Keys (leader = <kbd>Space</kbd>)

| Key                        | Action                        |
| -------------------------- | ----------------------------- |
| `<leader>ff` / `<leader>fg`| find files / grep project     |
| `<leader>fo` / `<leader>fr`| recent files / resume last picker |
| `<leader>fw` / `<leader>/` | grep word under cursor / fuzzy find in buffer |
| `<leader>fk`               | search the keymaps            |
| `<leader>e`                | toggle file tree              |
| `gd` / `gr` / `K`          | definition / references / hover |
| `gI` / `gy`                | implementation / type definition |
| `<leader>ca` / `<leader>rn`| code action / rename          |
| `<leader>lf`               | format buffer                 |
| `gc` / `gcc`               | comment (built-in)            |
| `<leader>xx`               | diagnostics (Trouble)         |
| `<leader>t`                | terminal (bottom split)       |
| `<Esc><Esc>` (terminal)    | back to normal mode           |
| `<C-h/j/k/l>`              | move between splits           |
| `<C-Up/Down/Left/Right>`   | resize the split              |
| `<` / `>` (visual)         | indent and keep the selection |
| `[b` / `]b`                | previous / next buffer        |
| `<leader>u`                | undo tree                     |
| `<leader>gg`               | lazygit (needs the binary)    |
| `<leader>ih`               | toggle inlay hints            |

> Install [`lazygit`](https://github.com/jesseduffield/lazygit) for `<leader>gg` — e.g.
> `winget install lazygit`, `brew install lazygit`, `dnf install lazygit`, `pacman -S lazygit`.

## Add a language

Open a file and **Treesitter installs its parser automatically**. For LSP + completion,
run `:Mason`, install the server, and it's enabled on the next launch — no config edit.
Formatters: add one line under `formatters_by_ft` in `init.lua`, or let the LSP format
(the built-in fallback). Linters work the same way under `linters_by_ft`.

## Updating

Pull the latest config first — re-run the installer (it fast-forwards an existing
official clone), or update the clone directly:

```sh
git -C ~/.config/nvim pull --ff-only origin main          # Linux / macOS / WSL
```

```powershell
git -C $env:LOCALAPPDATA\nvim pull --ff-only origin main   # Windows
```

Then refresh plugins and parsers from inside Neovim:

```text
:Lazy sync     # update plugins  (commit the refreshed lazy-lock.json to pin them)
:TSUpdate      # update Treesitter parsers
:checkhealth   # verify everything is wired up
```

Both paths fast-forward from `origin/main`; a clone with local commits or
uncommitted changes to tracked files is left untouched rather than overwritten.
Plugin revisions, including `lazy.nvim` itself, are restored from `lazy-lock.json`.

## Rollback and local state

A replaced config is kept beside the active directory as
`nvim.bak-<timestamp>-<process-id>` (or the corresponding Windows path). To
restore it, move the current directory aside and rename the chosen backup to
`nvim`. Before reverting an updated Git clone, inspect `git reflog` and preserve
any local changes.

Neovim and Vim use persistent undo, which can retain earlier contents of edited
files locally. Use `:setlocal noundofile` before editing sensitive material when
that retention is undesirable.
