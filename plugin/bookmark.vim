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

call s:set('g:bookmark_highlight_lines',  0 )
call s:set('g:bookmark_sign',            '⚑')
call s:set('g:bookmark_annotation_sign', '☰')
call s:set('g:bookmark_show_warning',     1 )
call s:set('g:bookmark_auto_save',        1 )
call s:set('g:bookmark_center',           0 )
call s:set('g:bookmark_auto_save_file',   $HOME .'/.vim-bookmarks')
call s:set('g:bookmark_auto_close',       0 )

if g:bookmark_auto_save ==# 1
  augroup bm_auto_save
    autocmd!
    autocmd VimEnter * call s:startup_load_bookmarks(expand("<afile>:p"))
    autocmd VimLeave * call SaveBookmarks(g:bookmark_auto_save_file)
    autocmd BufWinEnter * call s:add_missing_signs(expand("<afile>:p"))
  augroup END
endif

" }}}


" Commands {{{

function! ToggleBookmark()
  call s:refresh_line_numbers()
  let file = expand("%:p")
  if file ==# ""
    return
  endif
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

function! Annotate(...)
  call s:refresh_line_numbers()
  let file = expand("%:p")
  if file ==# ""
    return
  endif

  let current_line = line('.')
  let has_bm = bm#has_bookmark_at_line(file, current_line)
  let bm = has_bm ? bm#get_bookmark_by_line(file, current_line) : 0
  let old_annotation = has_bm ? bm['annotation'] : ""
  let new_annotation = a:0 ># 0 ? a:1 : ""

  " Get annotation from user input if not passed in
  if new_annotation ==# ""
    let input_msg = old_annotation !=# "" ? "Edit" : "Enter"
    let new_annotation = input(input_msg ." annotation: ", old_annotation)
    execute ":redraw!"
  endif

  " Nothing changed, bail out
  if new_annotation ==# "" && old_annotation ==# new_annotation
    return

  " Update annotation
  elseif has_bm
    call bm#update_annotation(file, bm['sign_idx'], new_annotation)
    let result_msg = (new_annotation ==# "")
          \ ? "removed"
          \ : old_annotation !=# ""
          \   ? "updated: ". new_annotation
          \   : "added: ". new_annotation
    call bm_sign#update_at(file, bm['sign_idx'], bm['line_nr'], bm['annotation'] !=# "")
    echo "Annotation ". result_msg

  " Create bookmark with annotation
  elseif new_annotation !=# ""
    call s:bookmark_add(file, current_line, new_annotation)
    echo "Bookmark added with annotation: ". new_annotation
  endif
endfunction
command! -nargs=* Annotate call Annotate(<q-args>, 0)

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

function! ClearAllBookmarks(silent)
  call s:refresh_line_numbers()
  let files = bm#all_files()
  let file_count = len(files)
  let delete = 1
  let in_multiple_files = file_count ># 1
  let supports_confirm = has("dialog_con") || has("dialog_gui")
  if (in_multiple_files && g:bookmark_show_warning ==# 1 && supports_confirm && !a:silent)
    let delete = confirm("Delete ". bm#total_count() ." bookmarks in ". file_count . " buffers?", "&Yes\n&No")
  endif
  if (delete ==# 1)
    call s:remove_all_bookmarks()
    if (!a:silent)
      execute ":redraw!"
      echo "All bookmarks removed"
    endif
  endif
endfunction
command! ClearAllBookmarks call ClearAllBookmarks(0)

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
  belowright copen
  augroup BM_AutoCloseCommand
    autocmd!
    autocmd WinLeave * call s:auto_close()
  augroup END
  let &errorformat = oldformat    " re-apply original format
endfunction
command! ShowAllBookmarks call ShowAllBookmarks()

function! SaveBookmarks(target_file, silent)
  call s:refresh_line_numbers()
  let serialized_bookmarks = bm#serialize()
  call writefile(serialized_bookmarks, a:target_file)
  if (!a:silent)
    echo "All bookmarks saved"
  endif
endfunction
command! -nargs=1 SaveBookmarks call SaveBookmarks(<f-args>, 0)

function! LoadBookmarks(target_file, startup, silent)
  let supports_confirm = has("dialog_con") || has("dialog_gui")
  let has_bookmarks = bm#total_count() ># 0
  let confirmed = 1
  if (supports_confirm && has_bookmarks && !a:silent)
    let confirmed = confirm("Do you want to override your ". bm#total_count() ." bookmarks?", "&Yes\n&No")
  endif
  if (confirmed ==# 1)
    call s:remove_all_bookmarks()
    try
      let data = readfile(a:target_file)
      let new_entries = bm#deserialize(data)
      if !a:startup
        for entry in new_entries
          call bm_sign#add_at(entry['file'], entry['sign_idx'], entry['line_nr'], entry['annotation'] !=# "")
        endfor
        if (!a:silent)
          echo "Bookmarks loaded"
        endif
        return 1
      endif
    catch
      if (!a:startup && !a:silent)
        echo "Failed to load/parse file"
      endif
      return 0
    endtry
  endif
endfunction
command! -nargs=1 LoadBookmarks call LoadBookmarks(<f-args>, 0, 0)

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

function! s:bookmark_add(file, line_nr, ...)
  let annotation = (a:0 ==# 1) ? a:1 : ""
  let sign_idx = bm_sign#add(a:file, a:line_nr, annotation !=# "")
  call bm#add_bookmark(a:file, sign_idx, a:line_nr, getline(a:line_nr), annotation)
endfunction

function! s:bookmark_remove(file, line_nr)
  let bookmark = bm#get_bookmark_by_line(a:file, a:line_nr)
  call bm_sign#del(a:file, bookmark['sign_idx'])
  call bm#del_bookmark_at_line(a:file, a:line_nr)
endfunction

function! s:jump_to_bookmark(type)
  let file = expand("%:p")
  let line_nr = bm#{a:type}(file, line("."))
  if line_nr ==# 0
    echo "No bookmarks found"
  else
    call cursor(line_nr, 1)
    normal! ^
    if g:bookmark_center ==# 1
      normal! zz
    endif
    let bm = bm#get_bookmark_by_line(file, line_nr)
    let annotation = bm['annotation'] !=# "" ? " (". bm['annotation'] . ")" : ""
    execute ":redraw!"
    echo "Jumped to bookmark". annotation
  endif
endfunction

function! s:remove_all_bookmarks()
  let files = bm#all_files()
  for file in files
    let lines = bm#all_lines(file)
    for line_nr in lines
      call s:bookmark_remove(file, line_nr)
    endfor
  endfor
endfunction

function! s:startup_load_bookmarks(file)
	call LoadBookmarks(g:bookmark_auto_save_file, 1, 0)
	call s:add_missing_signs(a:file)
endfunction

" should only be called from autocmd!
function! s:add_missing_signs(file)
  let bookmarks = values(bm#all_bookmarks_by_line(a:file))
  for bookmark in bookmarks
    call bm_sign#add_at(a:file, bookmark['sign_idx'], bookmark['line_nr'], bookmark['annotation'] !=# "")
  endfor
endfunction

function! s:auto_close()
  if (getbufvar(winbufnr('.'), '&buftype') == 'quickfix')
    if (g:bookmark_auto_close)
      q
    endif
    call s:remove_auto_close()
  endif
endfunction

function! s:remove_auto_close()
   augroup BM_AutoCloseCommand
      autocmd!
   augroup END
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
call s:register_mapping('Annotate',          'mi')
call s:register_mapping('NextBookmark',      'mn')
call s:register_mapping('PrevBookmark',      'mp')
call s:register_mapping('ClearBookmarks',    'mc')
call s:register_mapping('ClearAllBookmarks', 'mx')

" }}}
