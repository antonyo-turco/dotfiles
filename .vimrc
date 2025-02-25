
" Vim settings of Antonio Turco, email:<antonyo.turco@gmail.com>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"        _                                                      _            _
" __   _(_)_ __ ___  _ __ ___     _____  ____ _ _ __ ___  _ __ | | _____   _(_)_ __ ___
" \ \ / / | '_ ` _ \| '__/ __|   / _ \ \/ / _` | '_ ` _ \| '_ \| |/ _ \ \ / / | '_ ` _ \
"  \ V /| | | | | | | | | (__   |  __/>  < (_| | | | | | | |_) | |  __/\ V /| | | | | | |
"   \_/ |_|_| |_| |_|_|  \___|___\___/_/\_\__,_|_| |_| |_| .__/|_|\___(_)_/ |_|_| |_| |_|
"                           |_____|                      |_|
" 
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
  finish
endif

" Get the defaults that most users want.
source $VIMRUNTIME/defaults.vim

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file (restore to previous version)
  if has('persistent_undo')
    set undofile	" keep an undo file (undo changes after closing)
  endif
endif

if &t_Co > 2 || has("gui_running")
  " Switch on highlighting the last used search pattern.
  set hlsearch
endif

" Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78
augroup END

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"  _   _ ___ ____   ____  _   _ _   _ _____   ____  ____      _    ____ ___  _   _ _____ ____
" | | | |_ _/ ___| / ___|| | | | \ | |_   _| |  _ \|  _ \    / \  / ___/ _ \| \ | | ____/ ___|
" | |_| || | |     \___ \| | | |  \| | | |   | | | | |_) |  / _ \| |  | | | |  \| |  _| \___ \
" |  _  || | |___   ___) | |_| | |\  | | |   | |_| |  _ <  / ___ \ |__| |_| | |\  | |___ ___) |
" |_| |_|___\____| |____/ \___/|_| \_| |_|   |____/|_| \_\/_/   \_\____\___/|_| \_|_____|____/
" 
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" set number lines on left side of screen
set number

" Highlight cursor line underneath the cursor horizontally.
set cursorline

" Set shift width to 4 spaces.
set shiftwidth=4

" Set tab width to 4 columns.
set tabstop=4

" Use space characters instead of tabs.
set expandtab

" BACKUP, UNDO AND SWAP FILES

" Do not save backup and undo files.
" set nobackup
" set noundofile
"
" Set where undo (.un~), backup (.NAME~) and swap (.swp) files are saved
set undodir=~/.vim/.undo/
set backupdir=~/.vim/.backup/
set directory=~/.vim/.swap/

" Do not let cursor scroll below or above N number of lines when scrolling.
set scrolloff=10

" Do not wrap lines. Allow long lines to extend as far as the line goes.
set nowrap

" While searching though a file incrementally highlight matching characters as you type.
set incsearch

" Ignore capital letters during search.
set ignorecase

" Override the ignorecase option if searching for capital letters.
" This will allow you to search specifically for capital letters.
set smartcase

" Fix indentation so that Vim will maintain the indentation of the precedent
" line
set autoindent
set smartindent

" Show partial command you type in the last line of the screen.
set showcmd

" Show the mode you are on the last line.
set showmode

" Show matching words during a search.
set showmatch

" Use highlighting when doing a search.
set hlsearch

" Set the commands to save in history default number is 20.
set history=1000

" Enable auto completion menu after pressing TAB.
set wildmenu

" Make wildmenu behave like similar to Bash completion.
set wildmode=list:longest

" There are certain files that we would never want to edit with Vim.
" Wildmenu will ignore files with these extensions.
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" Disable audible bell because it's annoying.                                                                             
" set noerrorbells visualbell t_vb= 
                               
" Enable mouse support. You should avoid relying on this too much, 
" but it can sometimes be convenient.
set mouse+=a

" Change cursor shape in different modes
let &t_EI = "\033[2 q" " NORMAL  █
let &t_SI = "\033[5 q" " INSERT  |
let &t_SR = "\033[3 q" " REPLACE _

" Maintain cursor on the same column when scrolling vertically
set virtualedit=all

" PLUGINS ---------------------------------------------------------------- {{{

" Plugin code goes here.

" }}}


" MAPPINGS --------------------------------------------------------------- {{{

" Mappings code goes here.

" Try to prevent bad habits like using the arrow keys for movement. This is
" not the only possible bad habit. For example, holding down the h/j/k/l keys
" for movement, rather than using more efficient movement commands, is also a
" bad habit. The former is enforceable through a .vimrc, while we don't know
" how to prevent the latter.
" Do this in normal mode...
" nnoremap <Left>  :echoe "Use h"<CR>
" nnoremap <Right> :echoe "Use l"<CR>
" nnoremap <Up>    :echoe "Use k"<CR>
" nnoremap <Down>  :echoe "Use j"<CR>
" ...and in insert mode
" inoremap <Left>  <ESC>:echoe "Use h"<CR>
" inoremap <Right> <ESC>:echoe "Use l"<CR>
" inoremap <Up>    <ESC>:echoe "Use k"<CR>
" inoremap <Down>  <ESC>:echoe "Use j"<CR>

" Using home row keys to move to start/end of line
map H ^
map L $ 

" Copy and paste with system clipboard
set clipboard=unnamedplus
vmap <C-c> "+y
vmap <C-v> c<ESC>"+p
imap <C-v> <ESC>"+pa

" }}}


" VIMSCRIPT -------------------------------------------------------------- {{{

" This will enable code folding.
" Use the marker method of folding.
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END

" More Vimscripts code goes here.

" }}}


" STATUS LINE ------------------------------------------------------------ {{{

" Clear status line when vimrc is reloaded.
set statusline=

" Status line left side.
set statusline+=\ %F\ %M\ %Y\ %R

" Use a divider to separate the left side from the right side.
set statusline+=%=

" Status line right side.
set statusline+=\ ascii:\ %b\ hex:\ 0x%B\ row:\ %l\ col:\ %c\ percent:\ %p%%

" Show the status on the second to last line.
set laststatus=2

" }}}
