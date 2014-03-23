if exists('g:loaded_bookmarks') || !has('signs') || &cp
  finish
endif
let g:loaded_bookmarks = 1

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


" Initialize
if !exists("g:bm_sign_index")
  let g:bm_sign_index = 9500
  call bm_sign#init()
endif

function! s:compare_lines(line_str1, line_str2)
  let line1 = str2nr(a:line_str1)
  let line2 = str2nr(a:line_str2)
  return line1 ==# line2 ? 0 : line1 > line2 ? 1 : -1
endfunc

" Return all bookmark lines for file
function! s:bookmark_lines(file)
  return sort(bm#all_lines(a:file), "s:compare_lines")
endfunction

" Refresh line numbers for current buffer
" Should happen when:
"  * Leaving buffer (to have quickfix window up to date)
"  * When adding bookmark (to keep next/prev in order)
"  * When populating quickfix window
"  * Before clearing all bookmarks
function! s:refresh_line_numbers()
  let l:file = expand("%:p")

  " Bail out if special unnamed buffer
  if l:file ==# "" || !bm#has_bookmarks_in_file(l:file)
    return
  endif

  let l:bufnr = bufnr(l:file)
  let l:sign_line_map = bm_sign#lines_for_signs(l:file)
  for l:sign_idx in keys(l:sign_line_map)
    let l:line_nr = l:sign_line_map[l:sign_idx]
    let l:content = getbufline(l:bufnr, l:line_nr)
    call bm#update_bookmark_for_sign(l:file, l:sign_idx, l:line_nr, l:content[0])
  endfor
endfunction

function! s:bookmark_add(line_nr)
  let l:file = expand("%:p")
  let l:sign_idx = bm_sign#add(l:file, a:line_nr)
  call bm#add_bookmark(l:file, l:sign_idx, a:line_nr, getline(a:line_nr))
endfunction

function! s:bookmark_remove(line_nr)
  let l:file = expand("%:p")
  let l:bookmark = bm#get_bookmark_by_line(l:file, a:line_nr)
  call bm_sign#del(l:file, l:bookmark['sign_idx'])
  call bm#del_bookmark_at_line(l:file, a:line_nr)
endfunction

function! s:jump_to_bookmark(line_nr)
  call cursor(a:line_nr, 1)
  normal ^
  echo "Jumped to bookmark ". a:line_nr
endfunction

function! s:get_bookmark_lines()
  let l:file = expand("%:p")
  return s:bookmark_lines(l:file)
endfunction

" Commands {{{

function! ToggleBookmark()
  call s:refresh_line_numbers()
  let l:file = expand("%:p")
  let l:current_line = line('.')
  if bm#has_bookmark_at_line(l:file, l:current_line)
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
  let l:lines = bm#all_lines(l:file)
  for line_nr in l:lines
    call s:bookmark_remove(line_nr)
  endfor
  echo "All bookmarks removed"
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
  let l:files = bm#all_files()

  for file in l:files
    let line_nrs = s:bookmark_lines(file)
    for line_nr in line_nrs
      let bookmark = bm#get_bookmark_by_line(file, line_nr)
      call add(locations, file .":". line_nr .":". bookmark['content'])
    endfor
  endfor

  cexpr! locations
  copen
  let &errorformat = oldformat    " re-apply original format
endfunction
command! ShowAllBookmarks call ShowAllBookmarks()

" }}}


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
  autocmd ColorScheme * call bm_sign#define_highlights()
  autocmd BufLeave * call s:refresh_line_numbers()
augroup END

" }}}
