<#
  One-line install of this Neovim config (Windows, PowerShell):
    irm https://github.com/26zl/nvim/raw/main/install.ps1 | iex

  Clones the repo into %LOCALAPPDATA%\nvim. An existing config is backed up first;
  if it's already this repo it just fast-forwards (git pull). It installs the CONFIG,
  not Neovim - install Neovim 0.11+ separately (winget install Neovim.Neovim).
  Launch `nvim` afterwards and lazy.nvim installs the plugins on first run.
#>

$repo = 'https://github.com/26zl/nvim'
$dest = Join-Path $env:LOCALAPPDATA 'nvim'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "git not found - install it first: winget install Git.Git" -ForegroundColor Red
    return
}
if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Host "Note: Neovim isn't on PATH - install 0.11+ (winget install Neovim.Neovim) before launching." -ForegroundColor Yellow
}

$isRepo = (Test-Path (Join-Path $dest '.git')) -and
          ((git -C $dest remote get-url origin 2>$null) -match 'github\.com[:/]26zl/nvim')
if ($isRepo) {
    Write-Host "==> updating existing config: $dest" -ForegroundColor Cyan
    # a lockfile lazy.nvim generated before the repo tracked it blocks the merge; the repo's pinned one wins
    $lock = Join-Path $dest 'lazy-lock.json'
    if ((Test-Path $lock) -and -not (git -C $dest ls-files lazy-lock.json)) {
        Move-Item $lock "$lock.bak" -Force
    }
    git -C $dest pull --ff-only
} else {
    if (Test-Path $dest) {
        $bak = "$dest.bak-{0:yyyyMMdd-HHmmss}" -f (Get-Date)
        Write-Host "==> existing config found - backing up to $bak" -ForegroundColor Yellow
        Move-Item $dest $bak
    }
    Write-Host "==> cloning $repo -> $dest" -ForegroundColor Cyan
    git clone $repo $dest
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Done. Launch 'nvim' - plugins install on first run." -ForegroundColor Green
} else {
    Write-Host "git reported exit $LASTEXITCODE - see the output above." -ForegroundColor Red
}
