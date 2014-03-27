if exists('g:bm_has_any') || !has('signs') || &cp
  finish
endif
let g:bm_has_any = 0
let g:bm_sign_index = 9500

" Configuration {{{

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
call s:set('g:bookmark_sign', '⚑')
call s:set('g:bookmark_show_warning', 1)
" }}}


" Commands {{{

function! ToggleBookmark()
  call s:refresh_line_numbers()
  let file = expand("%:p")
  let current_line = line('.')
  if bm#has_bookmark_at_line(file, current_line)
    call s:bookmark_remove(file, current_line)
    echo "Bookmark removed"
  else
    call s:bookmark_add(file, current_line)
    echo "Bookmark added"
  endif
endfunction
command! ToggleBookmark call ToggleBookmark()

function! ClearBookmarks()
  call s:refresh_line_numbers()
  let file = expand("%:p")
  let lines = bm#all_lines(file)
  for line_nr in lines
    call s:bookmark_remove(file, line_nr)
  endfor
  echo "Bookmarks removed"
endfunction
command! ClearBookmarks call ClearBookmarks()

function! ClearAllBookmarks()
  call s:refresh_line_numbers()
  let files = bm#all_files()
  let file_count = len(files)
  let delete = 1
  let in_multiple_files = file_count ># 1
  let supports_confirm = has("dialog_con") || has("dialog_gui")
  if (in_multiple_files && g:bookmark_show_warning ==# 1 && supports_confirm)
    let delete = confirm("Delete ". bm#total_count() ." bookmarks in ". file_count . " buffers?", "&Yes\n&No")
  endif
  if (delete ==# 1)
    for file in files
      let lines = bm#all_lines(file)
      for line_nr in lines
        call s:bookmark_remove(file, line_nr)
      endfor
    endfor
    execute ":redraw!"
    echo "All bookmarks removed"
  endif
endfunction
command! ClearAllBookmarks call ClearAllBookmarks()

function! NextBookmark()
  call s:refresh_line_numbers()
  call s:jump_to_bookmark('next')
endfunction
command! NextBookmark call NextBookmark()

function! PrevBookmark()
  call s:refresh_line_numbers()
  call s:jump_to_bookmark('prev')
endfunction
command! PrevBookmark call PrevBookmark()

function! ShowAllBookmarks()
  call s:refresh_line_numbers()
  let oldformat = &errorformat    " backup original format
  let &errorformat = "%f:%l:%m"   " custom format for bookmarks
  cgetexpr bm#location_list()
  copen
  let &errorformat = oldformat    " re-apply original format
endfunction
command! ShowAllBookmarks call ShowAllBookmarks()

" }}}


" Private {{{

function! s:lazy_init()
  if g:bm_has_any ==# 0
    augroup bm_refresh
      autocmd!
      autocmd ColorScheme * call bm_sign#define_highlights()
      autocmd BufLeave * call s:refresh_line_numbers()
    augroup END
    let g:bm_has_any = 1
  endif
endfunction

function! s:refresh_line_numbers()
  call s:lazy_init()
  let file = expand("%:p")
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

function! s:bookmark_add(file, line_nr)
  let sign_idx = bm_sign#add(a:file, a:line_nr)
  call bm#add_bookmark(a:file, sign_idx, a:line_nr, getline(a:line_nr))
endfunction

function! s:bookmark_remove(file, line_nr)
  let bookmark = bm#get_bookmark_by_line(a:file, a:line_nr)
  call bm_sign#del(a:file, bookmark['sign_idx'])
  call bm#del_bookmark_at_line(a:file, a:line_nr)
endfunction

function! s:jump_to_bookmark(type)
  let line_nr = bm#{a:type}(expand("%:p"), line("."))
  if line_nr ==# 0
    echo "No bookmarks found"
  else
    call cursor(line_nr, 1)
    normal ^
    echo "Jumped to bookmark"
  endif
endfunction

" }}}


" Maps {{{

function! s:register_mapping(command, shortcut)
  execute "nnoremap <silent> <Plug>". a:command ." :". a:command ."<CR>"
  if !hasmapto("<Plug>". a:command) && maparg(a:shortcut, 'n') ==# ''
    execute "nmap ". a:shortcut ." <Plug>". a:command
  endif
endfunction

call s:register_mapping('ShowAllBookmarks',  'ma')
call s:register_mapping('ToggleBookmark',    'mm')
call s:register_mapping('NextBookmark',      'mn')
call s:register_mapping('PrevBookmark',      'mp')
call s:register_mapping('ClearBookmarks',    'mc')
call s:register_mapping('ClearAllBookmarks', 'mx')

" }}}
