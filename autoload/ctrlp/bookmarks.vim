if v:version < 700 || &cp
  finish
endif

call add(g:ctrlp_ext_vars, {
  \ 'init': 'ctrlp#bookmarks#init()',
  \ 'accept': 'ctrlp#bookmarks#accept',
  \ 'lname': 'vim-bookmarks',
  \ 'sname': '',
  \ 'type': 'line',
  \ 'sort': 0,
  \ 'specinput': 0,
  \ })


function! ctrlp#bookmarks#init() abort
    let l:text=[]
    let l:files = sort(bm#all_files())
    for l:file in l:files
        let l:line_nrs = sort(bm#all_lines(l:file), "bm#compare_lines")
        for l:line_nr in l:line_nrs
            let l:bookmark = bm#get_bookmark_by_line(l:file, l:line_nr)
            let l:detail=printf("%s:%d | %s", pathshorten(l:file), l:line_nr,
                  \   l:bookmark.annotation !~ '^\s*$'
                  \     ? "Annotation: " . l:bookmark.annotation
                  \     : (l:bookmark.content !~ '^\s*$' ? l:bookmark.content
                  \                                : "empty line")
                  \ )
            call add(l:text,l:detail)
        endfor
    endfor
    return l:text
endfunction
   
function! ctrlp#bookmarks#accept(mode, str) abort
  if a:mode ==# 'e'
      let l:HowToOpen='e'
  elseif a:mode ==# 't'
      let l:HowToOpen='tabnew'
  elseif a:mode ==# 'v'
      let l:HowToOpen='vsplit'
  elseif a:mode ==# 'h'
      let l:HowToOpen='sp'
  endif
  call ctrlp#exit()
    let l:text=[]
    let l:files = sort(bm#all_files())
    for l:file in l:files
        let l:line_nrs = sort(bm#all_lines(l:file), "bm#compare_lines")
        for l:line_nr in l:line_nrs
            let l:bookmark = bm#get_bookmark_by_line(l:file, l:line_nr)
            let l:content_str=matchstr(a:str,'[^|]\+ | \(Annotation: \|empty line\)\zs.*\ze')
            let l:line_str=matchstr(a:str,'[^|]\+:\zs\d\+\ze | \(Annotation: \|empty line\)')
            if  l:content_str==# l:bookmark.annotation 
                  \ && l:line_str == l:line_nr
                execute l:HowToOpen." ".l:file
                execute ":".l:line_nr
                return
            elseif l:content_str ==# l:bookmark.content && l:line_str == l:line_nr
                execute l:HowToOpen." ".l:file
                execute ":".l:line_nr
                return
            endif
        endfor
    endfor
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#bookmarks#id() abort
  return s:id
endfunction

" vim:nofen:fdl=0:ts=2:sw=2:sts=2
