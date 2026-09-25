" Claude Code transcript exports (transcript mode `Ctrl+O`, then `v`).
" Claude Code writes them to $TMPDIR-like paths such as
" /private/tmp/claude-501/cc-transcript-<timestamp>.txt, and every user prompt
" starts at column 0 with "❯ " (U+276F). Kept out of vimrc on purpose: this
" only touches those files.

let s:user_prompt_pattern = '^\%u276f '

" Jump to the next (direction 1) or previous (direction -1) user prompt,
" honoring a count, e.g. 3]] skips three prompts ahead.
function! s:JumpToUserPrompt(direction) abort
  let search_flags = a:direction > 0 ? 'W' : 'bW'
  for _ in range(v:count1)
    if search(s:user_prompt_pattern, search_flags) == 0
      break
    endif
  endfor
  normal! zt
endfunction

" One fold per question (the prompt plus Claude's whole answer). The file
" opens folded, so it reads as an outline of my prompts: za toggles one,
" zR opens all, zM closes all.
function! ClaudeTranscriptFoldLevel(line_number) abort
  return getline(a:line_number) =~# s:user_prompt_pattern ? '>1' : '='
endfunction

" Closed fold shows the question itself plus how long the exchange is.
function! ClaudeTranscriptFoldText() abort
  let folded_line_count = v:foldend - v:foldstart + 1
  return getline(v:foldstart) . '  [' . folded_line_count . ' lines]'
endfunction

" Make my questions stand out from Claude's answers: the "❯" line is black on
" amber, its wrapped continuation lines (indented, up to the next blank line)
" are bold amber. cterm colors because vimrc doesn't set termguicolors.
function! s:DefineQuestionHighlights() abort
  highlight ClaudeQuestionFirstLine cterm=bold ctermfg=16 ctermbg=214 gui=bold guifg=#000000 guibg=#ffaf00
  highlight ClaudeQuestionContinued cterm=bold ctermfg=214 gui=bold guifg=#ffaf00
endfunction

" Closed folds get a stronger background version of vimrc's subtle indigo
" Folded highlight while a transcript buffer is active — these folds are the
" whole point of the file (one per question), so they should stand out more
" than an ordinary code fold. Swapped back to vimrc's default on BufLeave.
function! s:ApplyTranscriptFoldHighlight() abort
  highlight Folded cterm=NONE ctermfg=255 ctermbg=55 gui=NONE guifg=#ffffff guibg=#5f00af
endfunction

function! s:RestoreDefaultFoldHighlight() abort
  highlight Folded cterm=bold ctermfg=55 ctermbg=NONE gui=bold guifg=#5f00af guibg=NONE
endfunction

function! s:SetUpClaudeTranscript() abort
  setlocal readonly nomodified

  call s:DefineQuestionHighlights()
  call s:ApplyTranscriptFoldHighlight()
  " me=s makes the region's start zero-width, so the first-line match can
  " still claim the "❯" line inside it.
  syntax region ClaudeQuestionContinued start=/^\%u276f /me=s end=/^\s*$/ contains=ClaudeQuestionFirstLine
  syntax match ClaudeQuestionFirstLine /^\%u276f .*$/ contained

  setlocal foldmethod=expr foldexpr=ClaudeTranscriptFoldLevel(v:lnum)
  setlocal foldlevel=0 foldtext=ClaudeTranscriptFoldText()
  setlocal fillchars+=fold:\

  nnoremap <buffer> <silent> ]] :<C-u>call <SID>JumpToUserPrompt(1)<CR>
  nnoremap <buffer> <silent> [[ :<C-u>call <SID>JumpToUserPrompt(-1)<CR>
  " Outline of every prompt in the location list; Enter jumps to one.
  command! -buffer ClaudePrompts execute 'lvimgrep /' . s:user_prompt_pattern . '/j %' | lopen

  " Make n / N step through prompts right away without typing the symbol.
  let @/ = s:user_prompt_pattern

  " The export can't carry the transcript scroll position, so open on the
  " latest prompt (usually the one being looked for), with only that
  " exchange unfolded.
  normal! G
  call search(s:user_prompt_pattern, 'bW')
  normal! zvzt
endfunction

augroup claude_transcript
  autocmd!
  autocmd BufReadPost */cc-transcript-*.txt call s:SetUpClaudeTranscript()
  " Swap Folded to the stronger transcript variant only while a transcript
  " buffer is actually focused, so other buffers keep vimrc's subtle default.
  autocmd BufEnter */cc-transcript-*.txt call s:ApplyTranscriptFoldHighlight()
  autocmd BufLeave */cc-transcript-*.txt call s:RestoreDefaultFoldHighlight()
  " A :colorscheme change clears custom groups; define them again.
  autocmd ColorScheme * call s:DefineQuestionHighlights()
augroup END
