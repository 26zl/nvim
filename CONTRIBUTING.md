# Contributing

This is a single-file Neovim config (`init.lua`) plus installer scripts and a
plugin-free `vimrc`. It has to keep working on Linux, macOS, WSL and Windows with
Neovim 0.12 and newer, so CI (`.github/workflows/ci.yml`) lints everything and
smoke-tests the config on several Neovim versions. Run the same checks locally before
opening a pull request.

## Try a change without touching your own setup

Neovim honours the XDG variables on every platform, so a scratch copy of the repo can
be booted in isolation, exactly as CI does:

```sh
sandbox=$(mktemp -d)
mkdir -p "$sandbox/config" && cp -R . "$sandbox/config/nvim"
export XDG_CONFIG_HOME="$sandbox/config" XDG_DATA_HOME="$sandbox/data" \
  XDG_STATE_HOME="$sandbox/state" XDG_CACHE_HOME="$sandbox/cache"
nvim --headless "+Lazy! restore" +qa   # installs the pinned plugins
nvim                                    # try it interactively
```

The same variables work from PowerShell (`$env:XDG_CONFIG_HOME = ...`). Treesitter
parsers are downloaded and built in the background on the first start (they need
`tree-sitter`, `curl`, `tar` and a C compiler); `:checkhealth nvim-treesitter` lists
what is installed. Delete the sandbox when you are done.

## Checks

Lint and format with the versions CI uses:

- `stylua --check .` — StyLua 2.5.2, configured by `stylua.toml` (tabs); run
  `stylua .` to format
- `luacheck init.lua tests/lockfile.lua` — luacheck 1.2.0, configured by `.luacheckrc`
- `shellcheck install.sh install-vimrc.sh tests/installers.sh tests/fixtures/*`
- `Invoke-ScriptAnalyzer -Path install.ps1 -ExcludeRule PSAvoidUsingWriteHost` and
  the same for `tests/install.ps1` — PSScriptAnalyzer 1.25.0 in PowerShell

Tests:

- `sh tests/installers.sh` — the Unix installers and the `vimrc`, with a fake `git`
  and `curl` from `tests/fixtures`; needs `nvim` and `vim` on `PATH`
- `pwsh ./tests/install.ps1` — the Windows installer with a mocked `git`
- Lockfile: after `+Lazy! restore` in a sandbox, run
  `NVIM_LOCKFILE=$PWD/lazy-lock.json NVIM_LOCK_TEST=$PWD/tests/lockfile.lua nvim --headless '+lua dofile(vim.env.NVIM_LOCK_TEST)' +qa`
  to verify that every plugin is a Git checkout at its locked commit

## Plugins and the lockfile

`lazy-lock.json` pins every plugin, including `lazy.nvim` itself (`init.lua` checks
out the locked commit when it bootstraps). To update plugins run `:Lazy update`, use
the config for a while, then commit the new `lazy-lock.json`. A new plugin goes into
the spec in `init.lua` and must appear in the lockfile with a full 40-character
commit; CI fails otherwise. GitHub Actions versions are kept current by Dependabot.

## Pull requests

- Branch from `main` and open the pull request against `main`; CI must be green.
- Keep the config in one file and portable: branch on `is_windows` / `is_nixos` rather
  than assuming a platform, and prefer `vim.fn.stdpath()` and forward slashes for paths.
- When you add a keymap or a new external tool, update the Keys table and the
  Requirements section of the README (and `external_tools` for `:CheckDeps`).
- Commit messages are short imperative sentences that say why, as in `git log`.
