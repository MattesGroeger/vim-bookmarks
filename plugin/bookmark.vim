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

call s:set('g:bookmark_signs',           1)
call s:set('g:bookmark_highlight_lines', 0)
call s:set('g:bookmark_sign',            '⚑')

function! s:highlight()
  highlight BookmarkSignDefault ctermfg=33 ctermbg=NONE
  highlight BookmarkLineDefault ctermfg=232 ctermbg=33
  highlight default link BookmarkSign BookmarkSignDefault
  highlight default link BookmarkLine BookmarkLineDefault
endfunction

" Initialize
if !exists("g:bm_entries")
  let g:bm_entries = {}
  let g:bm_sign_index = 9500
  call s:highlight()
  if g:bookmark_signs
    sign define Bookmark texthl=BookmarkSign
    execute "sign define Bookmark text=". g:bookmark_sign
  else
    sign define Bookmark texthl=
  end
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

" Return all bookmarks for file
function! s:bookmarks(file)
  if has_key(g:bm_entries, a:file)
    return g:bm_entries[a:file]
  else
    return {}
  endif
endfunction

" Return all bookmark lines for file
function! s:bookmark_lines(file)
  let l:bookmarks = s:bookmarks(a:file)
  return sort(keys(l:bookmarks), "s:compare_lines")
endfunction

" Save bookmark for file
function! s:save_bookmark(file, line_nr, sign_index, content)
  let l:entry = {'line_nr': a:line_nr, 'sign_idx': a:sign_index, 'content': a:content}
  if !has_key(g:bm_entries, a:file)
    let g:bm_entries[a:file] = {}
  endif
  let g:bm_entries[a:file][a:line_nr] = l:entry
endfunction

" Returns whether bookmark exists in file
function! s:has_bookmark(file, line_nr)
  if has_key(g:bm_entries, a:file)
    return has_key(g:bm_entries[a:file], a:line_nr)
  else
    return 0
  endif
endfunction

" Return bookmark for file
function! s:bookmark(file, line_nr)
  return g:bm_entries[a:file][a:line_nr]
endfunction

" Remove bookmark in file
function! s:remove_bookmark(file, line_nr)
  unlet g:bm_entries[a:file][a:line_nr]
endfunction



function! s:bookmark_add(line_nr)
  let l:file = expand("%:p")
  call s:save_bookmark(l:file, a:line_nr, g:bm_sign_index, getline(a:line_nr))
  execute "sign place ". g:bm_sign_index ." line=" . a:line_nr ." name=Bookmark file=". l:file
  let g:bm_sign_index = g:bm_sign_index + 1
endfunction

function! s:bookmark_remove(line_nr)
  let l:file = expand("%:p")
  let l:bookmark = s:bookmark(l:file, a:line_nr)
  execute "sign unplace ". l:bookmark['sign_idx'] ." file=". l:file
  call s:remove_bookmark(l:file, a:line_nr)
endfunction

function! s:jump_to_bookmark(line_nr)
  call cursor(a:line_nr, 1)
  echo "Jumped to bookmark"
endfunction

function! s:get_bookmark_lines()
  let l:file = expand("%:p")
  return s:bookmark_lines(l:file)
endfunction

function! ToggleBookmark()
  let l:file = expand("%:p")
  let l:current_line = line('.')
  if s:has_bookmark(l:file, l:current_line)
    call s:bookmark_remove(l:current_line)
    echo "Bookmark removed"
  else
    call s:bookmark_add(l:current_line)
    echo "Bookmark added"
  endif
endfunction
command! ToggleBookmark call ToggleBookmark()

function! ClearBookmarks()
  let l:file = expand("%:p")
  let l:lines = keys(s:bookmarks(l:file))
  for line_nr in l:lines
    call s:bookmark_remove(line_nr)
  endfor
  echo "All Bookmarks removed"
endfunction
command! ClearBookmarks call ClearBookmarks()

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
  let oldformat = &errorformat    " backup original format
  let &errorformat = "%f:%l:%m"   " custom format for bookmarks
  let locations = []
  let l:files = keys(g:bm_entries)

  for file in l:files
    let line_nrs = s:bookmark_lines(file)
    for line_nr in line_nrs
      let content = getbufline(bufnr(file), line_nr)
      if len(content) ># 0 && content[0] !=# ""
        call add(locations, file .":". line_nr .":". content[0])
      else
        let bm = s:bookmark(file, line_nr)
        call add(locations, file .":". line_nr .":[unloaded buffer] ". bm['content'])
      endif
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
augroup END

" }}}
