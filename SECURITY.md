# Security

This repository is a Neovim configuration: `init.lua`, a plain-Vim `vimrc`, and
installer scripts that clone the repository and bootstrap `lazy.nvim` at the commit
pinned in `lazy-lock.json`. Only the `main` branch is maintained.

If you find a security problem — in the installer scripts, in the plugin bootstrap,
or a pinned plugin commit you believe is compromised — report it privately through
GitHub's vulnerability reporting for this repository:
<https://github.com/26zl/nvim/security/advisories/new>. Please do not open a public
issue for it; it is handled from there.

Ordinary bugs and feature requests belong in the issue tracker. Vulnerabilities in a
plugin or language server itself should be reported to that project; a pull request
that bumps `lazy-lock.json` once the fix is released is welcome.
