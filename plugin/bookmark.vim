" Init vars
if !exists("b:bm_entrie")
  let b:bm_entries = {}
endif

function! s:bookmark_add(line_nr)
  " @todo add sign
  let b:bm_entries[a:line_nr] = {'line_nr': a:line_nr, 'sign_id': 0}
endfunction

function! s:bookmark_remove(bookmark)
  " @todo remove sign
  unlet b:bm_entries[a:bookmark['line_nr']]
endfunction

function! BookmarkToggle()
  let current_line = line('.')
  if has_key(b:bm_entries, current_line)
    call s:bookmark_remove(get(b:bm_entries, current_line))
    echo "Bookmark removed"
  else
    call s:bookmark_add(current_line)
    echo "Bookmark added"
  endif
endfunction
command! BookmarkToggle call BookmarkToggle()

function! ClearAllBookmarks()
  let bookmarks = values(b:bm_entries)
  for bookmark in bookmarks
    call s:bookmark_remove(bookmark)
  endfor
  echo "All Bookmarks removed"
endfunction
command! ClearAllBookmarks call ClearAllBookmarks()

function! s:jump_to_line(line_nr)
  call cursor(a:line_nr, 1)
  echo "Jumped to bookmark"
endfunction

function! NextBookmark()
  let line_nrs = sort(keys(b:bm_entries))
  if empty(line_nrs)
    echo "No bookmarks found"
    return
  endif
  let current_line = line('.')
  if current_line >=# line_nrs[-1] || current_line <# line_nrs[0]
    call s:jump_to_line(line_nrs[0])
  else
    let idx = 0
    let lines_count = len(line_nrs)
    while idx <# lines_count-1
      let cur_bookmark = line_nrs[idx]
      let next_bookmark = line_nrs[idx+1]
      if current_line >=# cur_bookmark && current_line <# next_bookmark
        call s:jump_to_line(next_bookmark)
        return
      endif
      let idx = idx+1
    endwhile
  endif
endfunction
command! NextBookmark call NextBookmark()

function! PrevBookmark()
  let line_nrs = sort(keys(b:bm_entries))
  if empty(line_nrs)
    echo "No bookmarks found"
    return
  endif
  let current_line = line('.')
  let lines_count = len(line_nrs)
  let idx = lines_count-1
  if current_line <=# line_nrs[0] || current_line ># line_nrs[-1]
    call s:jump_to_line(line_nrs[idx])
  else
    while idx >=# 0
      let cur_bookmark = line_nrs[idx]
      let next_bookmark = line_nrs[idx-1]
      " echo current_line .",". cur_bookmark .",". next_bookmark
      if current_line <=# cur_bookmark && current_line ># next_bookmark
        call s:jump_to_line(next_bookmark)
        return
      endif
      let idx = idx-1
    endwhile
  endif
endfunction
command! PrevBookmark call PrevBookmark()

" Temporary keymapping
nnoremap <silent> mm :call BookmarkToggle()<cr>
nnoremap <silent> mn :call NextBookmark()<cr>
nnoremap <silent> mp :call PrevBookmark()<cr>
nnoremap <silent> mc :call ClearAllBookmarks()<cr>
