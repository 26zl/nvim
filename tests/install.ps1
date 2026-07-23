$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "nvim-install-tests-$([guid]::NewGuid())"
$originalLocalAppData = $env:LOCALAPPDATA
$gitLog = Join-Path $testRoot 'git.log'

function global:git {
    $operation = if ($args[0] -eq '-C') { [string]$args[2] } else { [string]$args[0] }
    if ($operation -eq 'remote') {
        $global:LASTEXITCODE = 0
        return $env:NVIM_TEST_GIT_ORIGIN
    }

    Add-Content -LiteralPath $env:NVIM_TEST_GIT_LOG -Value $operation
    if ($env:NVIM_TEST_GIT_FAIL -eq '1') {
        $global:LASTEXITCODE = 42
        return
    }

    if ($operation -eq 'clone') {
        $destination = [string]$args[-1]
        New-Item -ItemType Directory -Path (Join-Path $destination '.git') -Force | Out-Null
    }
    $global:LASTEXITCODE = 0
}

function global:nvim {}

function Initialize-TestFixture {
    if (Test-Path $testRoot) {
        Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path (Join-Path $testRoot 'nvim/.git') -Force | Out-Null
    $env:LOCALAPPDATA = $testRoot
    $env:NVIM_TEST_GIT_LOG = $gitLog
    $env:NVIM_TEST_GIT_FAIL = '0'
    [System.IO.File]::WriteAllText($gitLog, '')
}

try {
    Initialize-TestFixture
    $env:NVIM_TEST_GIT_ORIGIN = 'https://github.com/26zl/nvim-copy'
    & (Join-Path $repoRoot 'install.ps1') *> $null
    $gitCalls = @(Get-Content -LiteralPath $gitLog)
    if ($gitCalls -contains 'pull' -or $gitCalls -notcontains 'clone') {
        throw 'Foreign origin was updated instead of replaced.'
    }
    Write-Output 'ok - foreign origin is replaced instead of pulled'

    Initialize-TestFixture
    $env:NVIM_TEST_GIT_ORIGIN = 'https://github.com/26zl/nvim'
    $env:NVIM_TEST_GIT_FAIL = '1'
    $threw = $false
    try {
        & (Join-Path $repoRoot 'install.ps1') *> $null
    }
    catch {
        $threw = $true
    }
    if (-not $threw) {
        throw 'Git failure did not terminate the installer.'
    }
    Write-Output 'ok - git failure terminates the installer'
}
finally {
    Remove-Item Function:\git -ErrorAction SilentlyContinue
    Remove-Item Function:\nvim -ErrorAction SilentlyContinue
    if (Test-Path $testRoot) {
        Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Item Env:\NVIM_TEST_GIT_LOG, Env:\NVIM_TEST_GIT_ORIGIN, Env:\NVIM_TEST_GIT_FAIL -ErrorAction SilentlyContinue
    $env:LOCALAPPDATA = $originalLocalAppData
}

# Both assertions above succeeded; clear the non-zero $LASTEXITCODE left by the
# mocked git failure in test 2 so the pwsh CI step does not inherit it.
exit 0
