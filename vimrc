" set custom folding for .vimrc, .ideavimrc, .zshrc, and .tmux.conf - use default markers: triple{ and triple} {{{
autocmd FileType vim,zsh,tmux :setlocal foldmethod=marker
"}}}

" ian's own keymaps {{{
nmap Q <Nop> " 'Q' in normal mode enters Ex mode. You almost never want this.
" to pair up with control W / U / H, and also stay consistent with Mac's default forward delete:
inoremap <C-d> <Del>
" escapes
inoremap jk <Esc>
inoremap kj <Esc>
cnoremap jk <C-C>
cnoremap kj <C-C>
" uncomment to always start (ex-command) search with `very magic` setting enabled: consistent regex 
" (disabled now because it causes the ex-command line input dialog to show up with a significant delay)
nnoremap / /\v
vnoremap / /\v
onoremap / /\v
" cnoremap %s/ %smagic/
" cnoremap \>s/ \>smagic/
" nnoremap :g/ :g/\v
 
" map space and shift-space(only works for MacVim, not terminal Vim) to traverse change-list
nnoremap <Space> g;
nnoremap <S-space> g,

" Try to prevent bad habits like using the arrow keys for movement.
" use `echo` instead of `echoe` for compatibility issues with intelliJ

nnoremap <Left>  :echo "Use h"<CR>
nnoremap <Right> :echo "Use l"<CR>
nnoremap <Up>    :echo "Use k"<CR>
nnoremap <Down>  :echo "Use j"<CR>

inoremap <Left>  <ESC>:echo "Use ^O-h"<CR>
inoremap <Right> <ESC>:echo "Use ^O-l"<CR>
inoremap <Up>    <ESC>:echo "Use ^O-k"<CR>
inoremap <Down>  <ESC>:echo "Use ^O-j"<CR>

" (Control L) -> initially clears/redraws screen: map to :nohlsearch
nnoremap <c-l> :nohlsearch<cr>

" note: only macvim recognizes D and M as command and option key;terminal vim doesn't 
" also these mappings just won't happen automatically so needs to be called as a function; see notion map keys page for the MacVim GitHub open issue.
function MapMacModifierShortcuts()
	inoremap <D-Left> <ESC>:echo "use jkI"<CR>
	inoremap <D-Right> <ESC>:echo "use jkA"<CR>
	inoremap <M-Left> <ESC>:echo "use jkbi"<CR>
	inoremap <M-Right> <ESC>:echo "use jkea"<CR>

	nnoremap <D-Left> <ESC>:echo "use 0"<CR>
	nnoremap <D-Right> <ESC>:echo "use $"<CR>
	nnoremap <M-Left> <ESC>:echo "use B"<CR>
	nnoremap <M-Right> <ESC>:echo "use W"<CR>
endfunction
autocmd VimEnter * call MapMacModifierShortcuts()
"}}}

" other recommended settings (mostly "set"s and "let"s{{{
" be iMproved
set nocompatible
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
" status line at the bottom, even if you only have one window open.
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
" enable highlight search to show all matches, 
" `:noh` to turn off the hilighting until next search (but a hassle if you want to use search to navigate within a line)
" mapped control-l to :nol - see the keymap section
set hlsearch
" Enable searching as you type, rather than waiting till you press enter.
set incsearch
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
" }}}

" ian's own preferences - mostly graphical {{{
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
	colorscheme murphy
endif
" hide terminal Vim's background, effectively making it transparent if you have the terminal background set as transparent.
hi Normal guibg=NONE ctermbg=NONE

set guifont=MesloLGS-NF-Regular:h13
set linespace=3

"default split position:
set splitbelow
set splitright

" customize tab completion behavior - to like zsh ( practical vim tip 32 )
" provides a navigatable list of suggestions. ( tab, C-n, right  to scroll forward
set wildmenu
set wildmode=full
"}}}

"ideaVim ignore 
" ideavim can't parse function and emojis
" functions - during the markdown-notion-vim craze {{{
function SetUpMarkdown()
	set guifont=MesloLGS-NF-Regular:h15
	" paste, change to tab indentation
	normal "+p
	retab!
	" map line insertions to retain indentation on empty lines:
	" the remap only takes effect for the buffer it was defined in.
	inoremap  x
	nnoremap o ox
	nnoremap O Ox
	" insert empty lines.
	g!/\v(^\s*$)|(\n\s*\n)/norm o
endfunction

" function to call when pasting from Algorithm course's PDF slides.
function A()
	" delete the weird dot symbol for dotted lines.
	%s/\v[\n・]{2,}/
	" put each sentence ending with . period in a new line
	s/\v([^.\d]\. )/\1/g
	" turn each line into numbered list
	g/\v^[^	1]/norm I1. 
	" insert empty lines
	g!/\v(^\s*$)|(\n\s*\n)/norm o
endfunction

" this stuff is for method declarations / errors thrown copied from Oracle docs to Notion to Vim
function Oracle()
	" if the first line (method declaration) doesn't end with ), then join from first line to the next line that does end with ) - this happens when the method has multiple parameters.
	/\%1l\v[^)]$/,/\v\)$/j
	" proper in-line code with embeded links:
	%s/\v`\[(.{-})\]\((.{-})\)`/[`\1`](\2)/g
	" change notion's code fences to in-line code.
	%s/\v\n\n```\n/ `
	%s/\v\n```\n\n/` 
	" inserts empty lines before each bold words. (Paramteters,Returns,Throws), then make it a numbered list
	%s/\v([^:])\*\*/\11. **/g
	" find all lines that aren't numbered or indented, them number it.
	g/\v^[^	1]/norm I1. 
	
	" the See Also section:
	%s/\v • //g
	" put each throw into a new line
	g/\v\*\*Throws:/s/\v(\S)(\[`.{-}`\]\(https:.{-}\))/\1	1. \2/g
	"" put the text following the bold words into new indented lines, and make it a numbered list
	%s/\v:\*\*/:\*\*	1. /g
	"" delete all lines that's only numbered but has no content.
	g/\v^\s?1\. $/d
endfunction

" the function to call if editing notes pasted from Mooc.fi
function Mooc()
	" convert mooc.fi's in-line code to code fence
	" the back-slash is unnecessary within the [\/*] bracket, but without it the syntax highlighting would be thrown off, so
	:g/\v^`(\/[\/*]|.+[{;]$)/norm :s/`/O```c#
	:g/\v(^}`$|;`$)/norm :s/`/o```
	" when pasted in from notion: change java fences to c# fences to avoid the unpredictable markdown anchor disabling code highlight.
	:g/\v^\s*```java$/s/java/c#
	" match and select whole code block, then sub out all new line characters
	" `\S` in the first pattern can't be changed to `c#`: cases where notion's java block is pasted in
	:g/\v^\s*```\S\_.{-}```/,/\v^\s*```$/s/\n/NEWLINE
	" insert lines after, exclude (empty or white-space only lines), or those that already have a (empty or white-space only line) below.
	:g!/\v(^\s*$)|(\n\s*\n)/norm ox
	" sub the 1-line code fences back to what they should be
	:g/\v^\s*```(\s|\S)+```/s/NEWLINE//g
	" remove the last newline after the end of each code fence: with the join `:j` command
	:g/\v^\s*```$/j 
endfunction

autocmd FileType markdown call SetUpMarkdown()
" see the macros fold section for o register macro in markdown filetype

function Valley()
	# these are for the description file
	%s/输入/input /g
	%s/输出/output /g
	%s/描述/description /g
	%s/样例/sample /g
	%s/提示/Note: /g
	%s/\v([eE]xample.{-}:)\n+/\1
	# this is for the java file
	%s/\v\/\*\_.{-}\*\//\/*********************************\/
endfunction
"}}}

" macros: commands saved in registers {{{
" todo: make this file specific - e.g. when file type is python use # to match comment lines
" ex-command - in a java file: remove all lines that are just comments
" saves this command in the register c - c for comments
" to remove only selected areas: select, type : for command mode, ^C to paste
" this command after the '<,'> selection marker, then enter to run
let @c= 'g/\v^\s*\/\//d'

" the markdown stuff
" o register, o for obliterate;
autocmd BufEnter *.markdown let @o = 'ggVG"+x:!rm %:q!'
autocmd BufLeave *.markdown let @o = ''
autocmd BufWinLeave *.markdown let @o = '' | :!open -a Notion\ Enhanced
"}}}

" emoji (and other) abbreviataions {{{
" inoreabbrev means abbreviataion but only in insert mode, and no recursion
" od: orange diamond; cd:crystal diamond
inoreabbrev :star: ⭐️
inoreabbrev :pin: 📌
inoreabbrev :od: 🔶
inoreabbrev :bd: 🔷
inoreabbrev :rd: ♦️
inoreabbrev :cd: 💠
inoreabbrev :cross: ❌
" add to command line mode too for substitutions.
cnoreabbrev :star: ⭐️
cnoreabbrev :pin: 📌
cnoreabbrev :od: 🔶
cnoreabbrev :bd: 🔷
cnoreabbrev :rd: ♦️
cnoreabbrev :cd: 💠
cnoreabbrev :cross: ❌
" }}}

"ideaVim ignore end
