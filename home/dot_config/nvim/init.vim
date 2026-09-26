" Reuse the classic ~/.vim tree (autoload/, plugin/ - including
" claude-transcript.vim) instead of duplicating it under
" ~/.config/nvim. Must be set before Neovim's own startup plugin-scan
" pass, so plugin/*.vim in there still auto-loads.
set runtimepath^=~/.vim
set runtimepath+=~/.vim/after

" vimrc already branches on has('nvim') for vim-plug's data_dir, so
" nvim gets its own plugin install under stdpath('data') - no
" conflict with plain Vim's ~/.vim/plugged.
source ~/.vimrc
