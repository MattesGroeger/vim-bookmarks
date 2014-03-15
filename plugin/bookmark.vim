" Init vars
if !exists("b:bm_entries")
  let b:bm_entries = {}
  let b:bm_sign_index = 9500
  highlight Bookmark ctermfg=33 ctermbg=NONE
  highlight BookmarkLine ctermfg=232 ctermbg=33
  sign define Bookmark text=⚑ texthl=Bookmark linehl=BookmarkLine
endif

function! s:bookmark_add(line_nr)
  let b:bm_entries[a:line_nr] = {'line_nr': a:line_nr, 'sign_idx': b:bm_sign_index}
  execute "sign place ". b:bm_sign_index ." line=" . a:line_nr ." name=Bookmark file=". expand("%:p")
  let b:bm_sign_index = b:bm_sign_index + 1
endfunction

function! s:bookmark_remove(bookmark)
  execute "sign unplace ". a:bookmark['sign_idx'] ." file=". expand("%:p")
  unlet b:bm_entries[a:bookmark['line_nr']]
endfunction

function! s:jump_to_bookmark(line_nr)
  call cursor(a:line_nr, 1)
  echo "Jumped to bookmark"
endfunction

function! s:compare_lines(line_str1, line_str2)
  let line1 = str2nr(a:line_str1)
  let line2 = str2nr(a:line_str2)
  return line1 ==# line2 ? 0 : line1 > line2 ? 1 : -1
endfunc

function! s:get_bookmark_lines()
  return sort(keys(b:bm_entries), "s:compare_lines")
endfunction

function! ToggleBookmark()
  let current_line = line('.')
  if has_key(b:bm_entries, current_line)
    call s:bookmark_remove(get(b:bm_entries, current_line))
    echo "Bookmark removed"
  else
    call s:bookmark_add(current_line)
    echo "Bookmark added"
  endif
endfunction
command! ToggleBookmark call ToggleBookmark()

function! ClearAllBookmarks()
  let bookmarks = values(b:bm_entries)
  for bookmark in bookmarks
    call s:bookmark_remove(bookmark)
  endfor
  echo "All Bookmarks removed"
endfunction
command! ClearAllBookmarks call ClearAllBookmarks()

function! NextBookmark()
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
      " echo current_line .",". cur_bookmark .",". next_bookmark
      if current_line <=# cur_bookmark && current_line ># next_bookmark
        call s:jump_to_bookmark(next_bookmark)
        return
      endif
      let idx = idx-1
    endwhile
  endif
endfunction
command! PrevBookmark call PrevBookmark()

function! ShowBookmarks()
  let line_nrs = s:get_bookmark_lines()
  let oldformat = &errorformat    " backup original format
  let &errorformat = "%f:%l:%m"   " custom format for bookmarks
  let locations = []
  for line_nr in line_nrs
    let content = getline(line_nr)
    let content = content !=# "" ? content : "empty"
    call add(locations, expand("%:p") .":". line_nr .":". content)
  endfor
  cexpr! locations
  copen
  let &errorformat = oldformat    " re-apply original format
endfunction
command! ShowBookmarks call ShowBookmarks()

" Temporary keymapping
nnoremap <silent> mm :call ToggleBookmark()<cr>
nnoremap <silent> mn :call NextBookmark()<cr>
nnoremap <silent> mp :call PrevBookmark()<cr>
nnoremap <silent> mc :call ClearAllBookmarks()<cr>
nnoremap <silent> ma :call ShowBookmarks()<cr>
