#!/usr/bin/env sh
set -u

repo_root=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
fixtures="$repo_root/tests/fixtures"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/nvim-install-tests.XXXXXX")
failures=0

cleanup() {
  find "$test_root" -depth -delete
}
trap cleanup EXIT HUP INT TERM

run_test() {
  name=$1
  shift
  if "$@"; then
    printf 'ok - %s\n' "$name"
  else
    printf 'not ok - %s\n' "$name" >&2
    failures=$((failures + 1))
  fi
}

fresh_install_creates_parent() {
  case_root="$test_root/fresh"
  home="$case_root/home"
  log="$case_root/git.log"
  mkdir -p "$home"

  PATH="$fixtures:$PATH" \
    HOME="$home" \
    XDG_CONFIG_HOME="$home/.config" \
    FAKE_GIT_LOG="$log" \
    FAKE_GIT_REQUIRE_PARENT=1 \
    sh "$repo_root/install.sh" >/dev/null 2>&1 || return 1

  grep -qx clone "$log" && [ -d "$home/.config/nvim/.git" ]
}

foreign_origin_is_replaced() {
  case_root="$test_root/foreign-origin"
  home="$case_root/home"
  destination="$home/.config/nvim"
  log="$case_root/git.log"
  mkdir -p "$destination/.git"

  PATH="$fixtures:$PATH" \
    HOME="$home" \
    XDG_CONFIG_HOME="$home/.config" \
    FAKE_GIT_LOG="$log" \
    FAKE_GIT_ORIGIN="https://github.com/26zl/nvim-copy" \
    sh "$repo_root/install.sh" >/dev/null 2>&1 || return 1

  grep -qx clone "$log" && ! grep -qx pull "$log"
}

failed_vimrc_download_preserves_destination() {
  case_root="$test_root/vimrc-failure"
  home="$case_root/home"
  expected="$case_root/expected"
  mkdir -p "$home"
  printf '%s\n' "existing vimrc" >"$home/.vimrc"
  cp "$home/.vimrc" "$expected"

  if PATH="$fixtures:$PATH" HOME="$home" FAKE_CURL_FAIL=1 \
    sh "$repo_root/install-vimrc.sh" >/dev/null 2>&1; then
    return 1
  fi

  cmp -s "$expected" "$home/.vimrc"
}

successful_vimrc_download_keeps_backup() {
  case_root="$test_root/vimrc-success"
  home="$case_root/home"
  mkdir -p "$home"
  printf '%s\n' "existing vimrc" >"$home/.vimrc"

  PATH="$fixtures:$PATH" \
    HOME="$home" \
    FAKE_CURL_CONTENT="new vimrc" \
    sh "$repo_root/install-vimrc.sh" >/dev/null 2>&1 || return 1

  grep -qx "new vimrc" "$home/.vimrc" || return 1
  backup=$(find "$home" -maxdepth 1 -name '.vimrc.bak-*' -type f -print -quit)
  [ -n "$backup" ] && grep -qx "existing vimrc" "$backup"
}

bootstrap_failure_is_clear() {
  if ! nvim --clean --headless \
    "+lua if vim.fn.has('nvim-0.11.3') == 1 and vim.fn.has('nvim-0.12') == 0 then vim.cmd('qa') else vim.cmd('cq') end" \
    >/dev/null 2>&1; then
    return 0
  fi

  case_root="$test_root/bootstrap"
  config="$case_root/config/nvim"
  output="$case_root/output.log"
  mkdir -p "$config" "$case_root/data" "$case_root/state" "$case_root/cache" "$case_root/home"
  cp "$repo_root/init.lua" "$config/init.lua"
  cp "$repo_root/lazy-lock.json" "$config/lazy-lock.json"

  status=0
  PATH="$fixtures:$PATH" \
    FAKE_GIT_FAIL_OPERATION=clone \
    XDG_CONFIG_HOME="$case_root/config" \
    XDG_DATA_HOME="$case_root/data" \
    XDG_STATE_HOME="$case_root/state" \
    XDG_CACHE_HOME="$case_root/cache" \
    HOME="$case_root/home" \
    nvim --headless +qa >"$output" 2>&1 || status=$?

  [ "$status" -ne 0 ] &&
    grep -Fq "Failed to clone lazy.nvim" "$output" &&
    ! grep -Fq "module 'lazy' not found" "$output"
}

unsupported_neovim_version_is_rejected() {
  if ! nvim --clean --headless \
    "+lua if vim.fn.has('nvim-0.12') == 1 then vim.cmd('qa') else vim.cmd('cq') end" \
    >/dev/null 2>&1; then
    return 0
  fi

  case_root="$test_root/version-guard"
  config="$case_root/config/nvim"
  output="$case_root/output.log"
  mkdir -p "$config" "$case_root/data" "$case_root/state" "$case_root/cache" "$case_root/home"
  cp "$repo_root/init.lua" "$config/init.lua"

  status=0
  PATH="$fixtures:$PATH" \
    FAKE_GIT_FAIL_OPERATION=clone \
    XDG_CONFIG_HOME="$case_root/config" \
    XDG_DATA_HOME="$case_root/data" \
    XDG_STATE_HOME="$case_root/state" \
    XDG_CACHE_HOME="$case_root/cache" \
    HOME="$case_root/home" \
    nvim --headless +qa >"$output" 2>&1 || status=$?

  [ "$status" -ne 0 ] &&
    grep -Fq "Neovim 0.11.3 through 0.11.x" "$output"
}

vimrc_handles_unwritable_undo_directory() {
  HOME=/dev/null vim -Nu "$repo_root/vimrc" -n -es -i NONE -c 'qa!'
}

vimrc_uses_supported_clipboard_options() {
  HOME="$test_root/vim-home" vim -Nu "$repo_root/vimrc" -n -es -i NONE \
    -c "if !has('unnamedplus') && &clipboard =~# 'unnamedplus' | cquit | endif" \
    -c 'qa!'
}

run_test "fresh install creates its parent directory" fresh_install_creates_parent
run_test "foreign origin is replaced instead of pulled" foreign_origin_is_replaced
run_test "failed vimrc download preserves the live file" failed_vimrc_download_preserves_destination
run_test "successful vimrc download keeps a backup" successful_vimrc_download_keeps_backup
run_test "lazy.nvim clone failure is explicit" bootstrap_failure_is_clear
run_test "unsupported Neovim versions are rejected clearly" unsupported_neovim_version_is_rejected
run_test "vimrc tolerates an unwritable undo directory" vimrc_handles_unwritable_undo_directory
run_test "vimrc only enables supported clipboard options" vimrc_uses_supported_clipboard_options

[ "$failures" -eq 0 ]
