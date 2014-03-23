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

" Refresh line numbers for current buffer
function! s:refresh_line_numbers()
  let file = expand("%:p")

  " Bail out if special unnamed buffer
  if file ==# "" || !bm#has_bookmarks_in_file(file)
    return
  endif

  let bufnr = bufnr(file)
  let sign_line_map = bm_sign#lines_for_signs(file)
  for sign_idx in keys(sign_line_map)
    let line_nr = sign_line_map[sign_idx]
    let content = getbufline(bufnr, line_nr)
    call bm#update_bookmark_for_sign(file, sign_idx, line_nr, content[0])
  endfor
endfunction

function! s:bookmark_add(line_nr)
  let file = expand("%:p")
  let sign_idx = bm_sign#add(file, a:line_nr)
  call bm#add_bookmark(file, sign_idx, a:line_nr, getline(a:line_nr))
endfunction

function! s:bookmark_remove(line_nr)
  let file = expand("%:p")
  let bookmark = bm#get_bookmark_by_line(file, a:line_nr)
  call bm_sign#del(file, bookmark['sign_idx'])
  call bm#del_bookmark_at_line(file, a:line_nr)
endfunction

function! s:jump_to_bookmark(line_nr)
  call cursor(a:line_nr, 1)
  normal ^
  echo "Jumped to bookmark ". a:line_nr
endfunction

" Commands {{{

function! ToggleBookmark()
  call s:refresh_line_numbers()
  let file = expand("%:p")
  let current_line = line('.')
  if bm#has_bookmark_at_line(file, current_line)
    call s:bookmark_remove(current_line)
    echo "Bookmark removed"
  else
    call s:bookmark_add(current_line)
    echo "Bookmark added"
  endif
endfunction
command! ToggleBookmark call ToggleBookmark()

function! ClearBookmarks()
  call s:refresh_line_numbers()
  let file = expand("%:p")
  let lines = bm#all_lines(file)
  for line_nr in lines
    call s:bookmark_remove(line_nr)
  endfor
  echo "All bookmarks removed"
endfunction
command! ClearBookmarks call ClearBookmarks()

function! NextBookmark()
  call s:refresh_line_numbers()
  let line_nr = bm#next(expand("%:p"), line("."))
  if line_nr ==# 0
    echo "No bookmarks found"
  else
    call s:jump_to_bookmark(line_nr)
  endif
endfunction
command! NextBookmark call NextBookmark()

function! PrevBookmark()
  call s:refresh_line_numbers()
  let line_nr = bm#prev(expand("%:p"), line("."))
  if line_nr ==# 0
    echo "No bookmarks found"
  else
    call s:jump_to_bookmark(line_nr)
  endif
endfunction
command! PrevBookmark call PrevBookmark()

function! ShowAllBookmarks()
  call s:refresh_line_numbers()
  let oldformat = &errorformat    " backup original format
  let &errorformat = "%f:%l:%m"   " custom format for bookmarks
  cexpr! bm#location_list()
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
