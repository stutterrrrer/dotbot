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

" Closed folds are drawn with the global Folded group, which can't be set per
" buffer: borrow the question colors while a transcript is the current buffer
" and put the original back on leaving it.
function! s:UseQuestionColorsForFolds() abort
  if !exists('s:original_folded_highlight')
    let s:original_folded_highlight = hlget('Folded')
  endif
  highlight! link Folded ClaudeQuestionFirstLine
endfunction

function! s:RestoreFoldColors() abort
  if exists('s:original_folded_highlight')
    call hlset(s:original_folded_highlight)
    unlet s:original_folded_highlight
  endif
endfunction

function! s:SetUpClaudeTranscript() abort
  setlocal readonly nomodified

  call s:DefineQuestionHighlights()
  " me=s makes the region's start zero-width, so the first-line match can
  " still claim the "❯" line inside it.
  syntax region ClaudeQuestionContinued start=/^\%u276f /me=s end=/^\s*$/ contains=ClaudeQuestionFirstLine
  syntax match ClaudeQuestionFirstLine /^\%u276f .*$/ contained
  call s:UseQuestionColorsForFolds()
  autocmd! claude_transcript * <buffer>
  autocmd claude_transcript BufEnter <buffer> call s:UseQuestionColorsForFolds()
  autocmd claude_transcript BufLeave <buffer> call s:RestoreFoldColors()

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
  " A :colorscheme change clears custom groups; define them again.
  autocmd ColorScheme * call s:DefineQuestionHighlights()
augroup END
