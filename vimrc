" ########### 30+ = ian's addition #############

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
Plugin 'instant-markdown/vim-instant-markdown'
Plugin 'kshenoy/vim-signature'

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

" ############################ markdown setup ############################
function SetUpMarkdown()
	set guifont=MesloLGS-NF-Regular:h15
	" paste, change to tab indentation
	normal "+p
	:retab!
	" convert mooc.fi's in-line code to code fence
	:g/\v^`.+\{$/norm :s/`/O```c#
	:g/\v^\}`$/norm :s/`/o```
	" match and select whole code block, then sub out all new line characters
	" `\S` in the first pattern can't be changed to `c#`: cases where notion's java block is pasted in
	:g/\v^\s*```\S\_.{-}```/,/\v^\s*```$/s/\n/NEWLINE
	" insert lines after, exclude (empty or white-space only lines), or those that already have a (empty or white-space only line) below.
	:g!/\v(^\s*$)|(\n\s*\n)/norm ox
	" sub the 1-line code fences back to what they should be
	:g/\v^\s*```(\s|\S)+```/s/NEWLINE//g
	" map line insertions to retain indentation on empty lines:
	" the remap only takes effect for the buffer it was defined in.
	inoremap  x
	nnoremap o ox
	nnoremap O Ox
endfunction
autocmd FileType markdown call SetUpMarkdown()
" l register, l for line break; o register, o for obliterate;
autocmd BufEnter *.markdown let @o = 'ggVG"+x:!rm %:q!' | let @l = 'ox'
autocmd BufLeave *.markdown let @o = '' | let @l = ''
autocmd BufWinLeave *.markdown let @o = '' | let @l = '' | :!open -a Notion\ Enhanced


" ############################ other stuff ############################
" (uncomment to) Enable mouse support. You should avoid relying on this too much, but it can
" sometimes be convenient.
" set mouse+=a
" Turn on syntax highlighting.
syntax on
" Disable the default Vim startup message.
set shortmess+=I
" Show line numbers.
set number
set relativenumber
" Always show status line at the bottom, even if you only have one window open.
set laststatus=2
" backspace over anything.
set backspace=indent,eol,start
" See `:help hidden` for more information on this. (uncomment to disable
" protection against unsaved buffer )
" set hidden

" case-insensitive search when entering all lower-case pattern.
" search becomes case-sensitive if it contains any capital letters.
set ignorecase
set smartcase
" enable highlight search to show all matches, `:noh` to turn off the
" hilighting until next search
set hlsearch
" Enable searching as you type, rather than waiting till you press enter.
set incsearch
" Unbind some useless/annoying default key bindings.
nmap Q <Nop> " 'Q' in normal mode enters Ex mode. You almost never want this.
" Disable audible bell because it's annoying.
set noerrorbells visualbell t_vb=
" auto-indent tells vim to apply the indentation of the current line to the next
set autoindent
set smartindent
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

let &t_SI="\033[5 q" " start insert mode, vertical cursor
let &t_EI="\033[1 q" " end insert mode, blinking block

"transparency variable only works for MacVim
if has("gui_running")
	" MacVim is a GUI I guess; sets the theme for MacVim
	" colorscheme murphy
	" colorscheme desert
	colo evening
	set transparency=18
else
	" sets the theme for terminal vim
	colorscheme zellner
endif
" hide terminal Vim's background, effectively making it transparent if you have the terminal background set as transparent.
hi Normal guibg=NONE ctermbg=NONE

set guifont=MesloLGS-NF-Regular:h13
set linespace=3

" ############################ ian's own keymaps ############################
" to pair up with control W / U / H, and also stay consistent with Mac's default forward delete:
inoremap <C-d> <Del>
" escapes
inoremap jk <Esc>
inoremap kj <Esc>
cnoremap jk <C-C>
cnoremap kj <C-C>
" uncomment to always start (ex-command) search with `very magic` setting enabled: consistent regex (disabled now because it causes the input dialog to show up with a significant delay
nnoremap / /\v
vnoremap / /\v
" cnoremap %s/ %smagic/
" cnoremap \>s/ \>smagic/
" nnoremap :g/ :g/\v
 
" Try to prevent bad habits like using the arrow keys for movement.
" use `echo` instead of `echoe` for compatibility issues with intelliJ
" Do this in normal mode...
nnoremap <Left>  :echo "Use h"<CR>
nnoremap <Right> :echo "Use l"<CR>
nnoremap <Up>    :echo "Use k"<CR>
nnoremap <Down>  :echo "Use j"<CR>

nnoremap <D-Left> <ESC>:echo "use 0"<CR>
nnoremap <D-Right> <ESC>:echo "use $"<CR>
nnoremap <M-Left> <ESC>:echo "use B"<CR>
nnoremap <M-Right> <ESC>:echo "use W"<CR>
" ...and in insert mode
inoremap <Left>  <ESC>:echo "Use ^O-h"<CR>
inoremap <Right> <ESC>:echo "Use ^O-l"<CR>
inoremap <Up>    <ESC>:echo "Use ^O-k"<CR>
inoremap <Down>  <ESC>:echo "Use ^O-j"<CR>

inoremap <D-Left> <ESC>:echo "use jkI"<CR>
inoremap <D-Right> <ESC>:echo "use jkA"<CR>
inoremap <M-Left> <ESC>:echo "use jkbi"<CR>
inoremap <M-Right> <ESC>:echo "use jkea"<CR>
