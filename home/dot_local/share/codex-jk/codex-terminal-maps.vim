" Launch with: vim -Nu NONE -i NONE -n -S /absolute/path/codex-terminal-maps.vim
" This file changes only this Vim instance. It does not load or edit ~/.vimrc.
set nocompatible
set timeout ttimeout ttimeoutlen=50
let &timeoutlen = get(g:, 'codex_escape_timeout_ms', 120)

" A clean Vim otherwise defaults to a light terminal on many macOS hosts.
" These colors also give the nested application a truthful dark OSC 11 reply.
set background=dark termguicolors
highlight Normal guifg=#e6e6e6 guibg=#000000 ctermfg=White ctermbg=Black
highlight Terminal guifg=#e6e6e6 guibg=#000000 ctermfg=White ctermbg=Black

" Keep Ctrl-W available to Codex. Ctrl-] is the outer Vim terminal prefix.
" Ctrl-\ then Ctrl-N still enters outer Vim Normal mode for :quit! if needed.
let &termwinkey = "\<C-]>"

" Tests or one-off launches may provide a different executable/argument list.
let s:codex_terminal_command = get(g:, 'codex_terminal_command',
      \ ['codex', '-c', 'tui.vim_mode_default=true'])

" Closing the sole terminal window when the child exits also exits Vim.
let s:terminal_buffer = term_start(s:codex_terminal_command,
      \ {'curwin': 1, 'term_finish': 'close', 'norestore': 1})
if s:terminal_buffer <= 0
  cquit
endif

" Terminal mappings otherwise also transform pasted text. Preserve paste bytes.
function! s:SetTerminalPaste(active) abort
  let b:terminal_pasting = a:active
  return a:active ? "\<PasteStart>" : "\<PasteEnd>"
endfunction

tnoremap <buffer> <expr> <PasteStart> <SID>SetTerminalPaste(1)
tnoremap <buffer> <expr> <PasteEnd> <SID>SetTerminalPaste(0)
" Read Codex's rendered state; do not guess mode from previously typed keys.
function! s:CodexIsInsert() abort
  if get(b:, 'terminal_pasting', 0)
    return 0
  endif
  let terminal_buffer = bufnr('%')
  " Allow one render frame after a preceding mode change. A 1 ms wait misses
  " fast A-j-k input; 20 ms is still much shorter than the old chord delay.
  call term_wait(terminal_buffer, 20)
  let terminal_cursor = term_getcursor(terminal_buffer)
  let terminal_size = term_getsize(terminal_buffer)
  let insert_footer_row = 0
  if len(terminal_cursor) >= 3 && len(terminal_size) == 2
    " The bottommost mode label must be below the active editing cursor.
    for screen_row in range(1, terminal_size[0])
      let screen_line = term_getline(terminal_buffer, screen_row)
      if screen_line =~# 'Vim: \(Insert\|Normal\|Replace\)\>'
        let insert_footer_row = screen_line =~# 'Vim: Insert\>' ? screen_row : 0
      endif
    endfor
  endif
  let is_insert = len(terminal_cursor) >= 3
        \ && get(terminal_cursor[2], 'visible', 0)
        \ && get(terminal_cursor[2], 'shape', 0) == 3
        \ && insert_footer_row > terminal_cursor[0]
  if exists('g:codex_mode_debug_path')
    call writefile([json_encode({
          \ 'cursor': terminal_cursor, 'insert_footer_row': insert_footer_row,
          \ 'insert_detected': is_insert ? v:true : v:false})],
          \ g:codex_mode_debug_path, 'a')
  endif
  return is_insert
endfunction

" Only Insert mode expands a lone key into an ambiguous internal prefix.
" Plain j/k have no longer public mapping, so Normal motions do not wait
" for timeoutlen. <Plug> expansions still work through a nonrecursive mapping.
tnoremap <buffer> <expr> j <SID>CodexIsInsert() ? "\<Plug>(CodexInsertJ)" : 'j'
tnoremap <buffer> <expr> k <SID>CodexIsInsert() ? "\<Plug>(CodexInsertK)" : 'k'
tnoremap <buffer> <Plug>(CodexInsertJ) j
tnoremap <buffer> <Plug>(CodexInsertK) k
tnoremap <buffer> <expr> <Plug>(CodexInsertJ)k <SID>CodexIsInsert() ? "\<Esc>" : 'jk'
tnoremap <buffer> <expr> <Plug>(CodexInsertK)j <SID>CodexIsInsert() ? "\<Esc>" : 'kj'

" Mode detection depends on rendered state, not a synchronized Codex mode API.
" Missing/ambiguous indicators preserve literal input. Redraw races remain possible.
