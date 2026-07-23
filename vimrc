" Plain-Vim companion to this Neovim config (init.lua). Drop it on a server as
" ~/.vimrc so stock Vim feels familiar. No plugins; guards version-specific options
" so it degrades cleanly on older Vim builds (any distro) and over SSH.

if !has('nvim')
  set nocompatible
endif

syntax on
filetype plugin indent on

" Leader — same as Neovim (Space).
let mapleader = ' '
let maplocalleader = ' '

" Options mirrored from init.lua.
set number
if exists('+relativenumber')
  set relativenumber
endif
set ignorecase smartcase
set incsearch hlsearch
set expandtab shiftwidth=2 tabstop=2 softtabstop=2
set autoindent smartindent
set scrolloff=8
set splitright splitbelow
set cursorline
set hidden
set backspace=indent,eol,start
set wildmenu wildmode=longest:full,full
set laststatus=2
set showcmd
set timeoutlen=400
set updatetime=250
set ttimeout ttimeoutlen=50

if has('mouse')
  " Matches Neovim. Use ':set mouse=' if you need terminal select/copy over SSH.
  set mouse=a
endif

if has('unnamedplus')
  set clipboard=unnamedplus
elseif has('clipboard')
  set clipboard=unnamed
endif

" Use persistent undo only when its private directory is writable.
if has('persistent_undo')
  let s:undodir = expand('~/.vim/undo')
  if !isdirectory(s:undodir)
    silent! call mkdir(s:undodir, 'p', 0700)
  endif
  if isdirectory(s:undodir) && filewritable(s:undodir) == 2
    let &undodir = s:undodir
    set undofile
  endif
endif

" Plugin-free echo of Telescope: :find <part><Tab> and :b <part><Tab> to jump around.
set path+=**

" Compact statusline so Vim doesn't feel bare next to lualine.
set statusline=%f\ %m%r%h%w%=%y\ %{&ff}\ %l:%c\ %p%%

" Keymaps that behave identically without plugins.
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <Esc> :nohlsearch<CR>

" Truecolor over SSH/tmux is unreliable, so no termguicolors here; just a safe
" dark builtin (ignored if the Vim build doesn't ship it).
set background=dark
silent! colorscheme habamax
