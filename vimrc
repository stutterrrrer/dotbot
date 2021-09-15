" ########### 78+ = ian's addition #############

" ############################ vundle plugin, line 1-30  ############################
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins: call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
"plugin list
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'instant-markdown/vim-instant-markdown'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" ############################  non-plugin stuff after this line ############################

" ############################ MIT's recommended setting line 31 - 75 ###########################
" Turn on syntax highlighting.
syntax on
" Disable the default Vim startup message.
set shortmess+=I
" Show line numbers.
set number
set relativenumber
" Always show the status line at the bottom, even if you only have one window open.
set laststatus=2
" The backspace key has slightly unintuitive behavior by default. For example,
" by default, you can't backspace before the insertion point set with 'i'.
" This configuration makes backspace behave more reasonably, in that you can
" backspace over anything.
set backspace=indent,eol,start
" See `:help hidden` for more information on this. (uncomment to disable
" protection against unsaved buffer )
" set hidden

" case-insensitive search when entering all lower-case pattern.
" search becomes case-sensitive if it contains any capital letters.
set ignorecase
set smartcase
" Enable searching as you type, rather than waiting till you press enter.
set incsearch
" Unbind some useless/annoying default key bindings.
nmap Q <Nop> " 'Q' in normal mode enters Ex mode. You almost never want this.
" Disable audible bell because it's annoying.
set noerrorbells visualbell t_vb=

" (uncomment to) Enable mouse support. You should avoid relying on this too much, but it can
" sometimes be convenient.
" set mouse+=a

" Try to prevent bad habits like using the arrow keys for movement.
" Do this in normal mode...
nnoremap <Left>  :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up>    :echoe "Use k"<CR>
nnoremap <Down>  :echoe "Use j"<CR>
" ...and in insert mode
inoremap <Left>  <ESC>:echoe "Use h"<CR>
inoremap <Right> <ESC>:echoe "Use l"<CR>
inoremap <Up>    <ESC>:echoe "Use k"<CR>
inoremap <Down>  <ESC>:echoe "Use j"<CR>

" ############################ ian's own additions ############################
" markdown files setup: 
function SetUpMarkdown()
	" paste, change to tab indentation, insert line break (need code block exception)
	normal "+p
	:retab!
	:g/.\n\n\@!/norm ox
	" to retain indentation on empty lines:
	" the remap only takes effect for the buffer it was defined in.
	inoremap  x
	nnoremap o ox
	nnoremap O Ox
endfunction
autocmd FileType markdown call SetUpMarkdown()
" l register, l for line break; o register, o for obliterate; c register, c for code block
autocmd BufEnter *.markdown let @o = 'ggVG"+x:!rm %:q!' | let @l = 'ox' | let @c = ':g/^\s*$/d'
autocmd BufLeave *.markdown let @o = '' | let @l = '' | let @c = ''
autocmd BufWinLeave *.markdown let @o = '' | let @l = '' | let @c = '' | :!open -a Notion\ Enhanced

" set tab size to 4;
" meaning that 1 `\t` character will be displayed as 4 columns on the screen.
" so that's what you get when pressisng the tab key in insert mode
set tabstop=4
" set shift size to 4 too;
" meaning the indent level will be 4 columns wide.
" so that's what you get when you do '>>' in normal mode.
" but there's no `\t` character when you do this. right?
set shiftwidth=4
" display tabs indicator as vertical bar:
set listchars=tab:\|\ 
set list

inoremap jk <Esc>
cnoremap jk <C-C>
let &t_SI="\033[5 q" " start insert mode, vertical cursor
let &t_EI="\033[1 q" " end insert mode, blinking block

"transparency variable only works for MacVim
if has("gui_running")
	" MacVim is a GUI I guess; sets the theme for MacVim
	colorscheme murphy
	set transparency=18
else
	" sets the theme for terminal vim
	colorscheme zellner
endif
" disable terminal Vim's background, effectively making it transparent if you have the terminal background set as transparent.
hi Normal guibg=NONE ctermbg=NONE

set guifont=MesloLGS-NF-Regular:h13
set linespace=3

" to pair up with control W / U / H, and also stay consistent with Mac's default forward delete:
inoremap <C-d> <Del>
