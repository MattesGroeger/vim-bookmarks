if exists('g:loaded_bookmarks') || !has('signs') || &cp
  finish
endif
" let g:loaded_bookmarks = 1

function! s:set(var, default)
  if !exists(a:var)
    if type(a:default)
      execute 'let' a:var '=' string(a:default)
    else
      execute 'let' a:var '=' a:default
    endif
  endif
endfunction

call s:set('g:bookmark_highlight_lines', 0)
call s:set('g:bookmark_sign',            '⚑')

function! s:highlight()
  highlight BookmarkSignDefault ctermfg=33 ctermbg=NONE
  highlight BookmarkLineDefault ctermfg=232 ctermbg=33
  highlight default link BookmarkSign BookmarkSignDefault
  highlight default link BookmarkLine BookmarkLineDefault
endfunction


" Initialize
if !exists("g:bm_sign_index")
  let g:bm_sign_index = 9500
  call s:highlight()
  sign define Bookmark texthl=BookmarkSign
  execute "sign define Bookmark text=". g:bookmark_sign
  if g:bookmark_highlight_lines
    sign define Bookmark linehl=BookmarkLine
  else
    sign define Bookmark linehl=
  endif
endif

function! s:compare_lines(line_str1, line_str2)
  let line1 = str2nr(a:line_str1)
  let line2 = str2nr(a:line_str2)
  return line1 ==# line2 ? 0 : line1 > line2 ? 1 : -1
endfunc

" Return all bookmark lines for file
function! s:bookmark_lines(file)
  return sort(model#all_lines(a:file), "s:compare_lines")
endfunction

" Refresh line numbers for current buffer
" Should happen when:
"  * Leaving buffer (to have quickfix window up to date)
"  * When adding bookmark (to keep next/prev in order)
"  * When populating quickfix window
"  * Before clearing all bookmarks
function! s:refresh_line_numbers()
  let l:file = expand("%:p")
  let l:bufnr = bufnr(l:file)

  if l:file ==# ""
    return
  endif

  redir => signs_raw
  silent execute ":sign place file=". l:file
  redir END

  let l:lines = split(signs_raw, "\n")
  for l:line in l:lines
    let l:results = matchlist(line, 'line=\(\d\+\)\W\+id=\(\d\+\)\W\+name=bookmark\c')
    if len(l:results) ># 0
      let l:line_nr = l:results[1]
      let l:sign_index = l:results[2]
      let l:content = getbufline(l:bufnr, l:line_nr)
      call model#update_bookmark_for_sign(l:file, l:sign_index, l:line_nr, l:content[0])
    endif
  endfor
endfunction

function! s:bookmark_add(line_nr)
  let l:file = expand("%:p")
  call model#add_bookmark(l:file, g:bm_sign_index, a:line_nr, getline(a:line_nr))
  execute "sign place ". g:bm_sign_index ." line=" . a:line_nr ." name=Bookmark file=". l:file
  let g:bm_sign_index = g:bm_sign_index + 1
endfunction

function! s:bookmark_remove(line_nr)
  let l:file = expand("%:p")
  let l:bookmark = model#get_bookmark_by_line(l:file, a:line_nr)
  execute "sign unplace ". l:bookmark['sign_idx'] ." file=". l:file
  call model#del_bookmark_at_line(l:file, a:line_nr)
endfunction

function! s:jump_to_bookmark(line_nr)
  let l:file = expand("%:p")
  let l:bookmark = model#get_bookmark_by_line(l:file, a:line_nr)
  echo "Jumped to bookmark ". a:line_nr ." (". l:bookmark['sign_idx'] .")"
  execute ":sign jump ". l:bookmark['sign_idx'] ." file=". l:file
endfunction

function! s:get_bookmark_lines()
  let l:file = expand("%:p")
  return s:bookmark_lines(l:file)
endfunction

function! ToggleBookmark()
  call s:refresh_line_numbers()
  let l:file = expand("%:p")
  let l:current_line = line('.')
  if model#has_bookmark_at_line(l:file, l:current_line)
    call s:bookmark_remove(l:current_line)
    echo "Bookmark removed"
  else
    call s:bookmark_add(l:current_line)
    echo "Bookmark added"
  endif
endfunction
command! ToggleBookmark call ToggleBookmark()

function! ClearBookmarks()
  call s:refresh_line_numbers()
  let l:file = expand("%:p")
  let l:lines = model#all_lines(l:file)
  for line_nr in l:lines
    call s:bookmark_remove(line_nr)
  endfor
  echo "All Bookmarks removed"
endfunction
command! ClearBookmarks call ClearBookmarks()

function! NextBookmark()
  call s:refresh_line_numbers()
  let line_nrs = s:get_bookmark_lines()
  if empty(line_nrs)
    echo "No bookmarks found"
    return
  endif
  let current_line = line('.')
  if current_line >=# line_nrs[-1] || current_line <# line_nrs[0]
    call s:jump_to_bookmark(line_nrs[0])
  else
    let idx = 0
    let lines_count = len(line_nrs)
    while idx <# lines_count-1
      let cur_bookmark = line_nrs[idx]
      let next_bookmark = line_nrs[idx+1]
      if current_line >=# cur_bookmark && current_line <# next_bookmark
        call s:jump_to_bookmark(next_bookmark)
        return
      endif
      let idx = idx+1
    endwhile
  endif
endfunction
command! NextBookmark call NextBookmark()

function! PrevBookmark()
  call s:refresh_line_numbers()
  let line_nrs = s:get_bookmark_lines()
  if empty(line_nrs)
    echo "No bookmarks found"
    return
  endif
  let current_line = line('.')
  let lines_count = len(line_nrs)
  let idx = lines_count-1
  if current_line <=# line_nrs[0] || current_line ># line_nrs[-1]
    call s:jump_to_bookmark(line_nrs[idx])
  else
    while idx >=# 0
      let cur_bookmark = line_nrs[idx]
      let next_bookmark = line_nrs[idx-1]
      if current_line <=# cur_bookmark && current_line ># next_bookmark
        call s:jump_to_bookmark(next_bookmark)
        return
      endif
      let idx = idx-1
    endwhile
  endif
endfunction
command! PrevBookmark call PrevBookmark()

function! ShowAllBookmarks()
  call s:refresh_line_numbers()
  let oldformat = &errorformat    " backup original format
  let &errorformat = "%f:%l:%m"   " custom format for bookmarks
  let locations = []
  let l:files = model#all_files()

  for file in l:files
    let line_nrs = s:bookmark_lines(file)
    for line_nr in line_nrs
      let bookmark = model#get_bookmark_by_line(file, line_nr)
      call add(locations, file .":". line_nr .":". bookmark['content'])
    endfor
  endfor

  cexpr! locations
  copen
  let &errorformat = oldformat    " re-apply original format
endfunction
command! ShowAllBookmarks call ShowAllBookmarks()


" Maps {{{

function! s:register_mapping(command, shortcut)
  execute "nnoremap <silent> <Plug>". a:command ." :". a:command ."<CR>"
  if !hasmapto("<Plug>". a:command) && maparg(a:shortcut, 'n') ==# ''
    execute "nmap ". a:shortcut ." <Plug>". a:command
  endif
endfunction

call s:register_mapping('ShowAllBookmarks', 'ma')
call s:register_mapping('ToggleBookmark',   'mm')
call s:register_mapping('NextBookmark',     'mn')
call s:register_mapping('PrevBookmark',     'mp')
call s:register_mapping('ClearBookmarks',   'mc')

" }}}


" Autocommands {{{

augroup bookmark
  autocmd!
  autocmd ColorScheme * call s:highlight()
  autocmd BufLeave * call s:refresh_line_numbers()
augroup END

" }}}
