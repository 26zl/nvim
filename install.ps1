# Installs this config in %LOCALAPPDATA%\nvim.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = 'https://github.com/26zl/nvim'
$dest = Join-Path $env:LOCALAPPDATA 'nvim'

function Assert-GitSuccess {
    param([Parameter(Mandatory)][string]$Action)
    if ($LASTEXITCODE -ne 0) {
        throw "git failed while $Action (exit $LASTEXITCODE)."
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git not found - install it first: winget install Git.Git'
}
if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Host "Note: Neovim isn't on PATH - install a supported version before launching (see README)." -ForegroundColor Yellow
}

$isRepo = $false
if (Test-Path (Join-Path $dest '.git')) {
    $origin = [string](git -C $dest remote get-url origin 2>$null)
    $isRepo = $LASTEXITCODE -eq 0 -and
              $origin -match '^(?:https://github\.com/26zl/nvim(?:\.git)?|git@github\.com:26zl/nvim(?:\.git)?|ssh://git@github\.com/26zl/nvim(?:\.git)?)$'
}
if ($isRepo) {
    Write-Host "==> updating existing config: $dest" -ForegroundColor Cyan
    $lock = Join-Path $dest 'lazy-lock.json'
    if ((Test-Path $lock) -and -not (git -C $dest ls-files lazy-lock.json)) {
        Move-Item $lock "$lock.bak" -Force
    }
    git -C $dest fetch origin main
    Assert-GitSuccess 'fetching origin/main'
    git -C $dest merge --ff-only FETCH_HEAD
    Assert-GitSuccess 'fast-forwarding the config'
} else {
    $parent = Split-Path -Parent $dest
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $staging = Join-Path $parent ".nvim-install-$([guid]::NewGuid())"
    $backup = $null
    try {
        Write-Host "==> cloning $repo" -ForegroundColor Cyan
        git clone $repo $staging
        Assert-GitSuccess 'cloning the config'

        if (Test-Path $dest) {
            $backup = "$dest.bak-{0:yyyyMMdd-HHmmss}-{1}" -f (Get-Date), $PID
            Write-Host "==> existing config found - backing up to $backup" -ForegroundColor Yellow
            Move-Item $dest $backup
        }
        Move-Item $staging $dest
        $staging = $null
    }
    catch {
        if ($backup -and -not (Test-Path $dest) -and (Test-Path $backup)) {
            Move-Item $backup $dest
        }
        throw
    }
    finally {
        if ($staging -and (Test-Path $staging)) {
            Remove-Item $staging -Recurse -Force
        }
    }
}

Write-Host "Done. Launch 'nvim' - plugins install on first run." -ForegroundColor Green
