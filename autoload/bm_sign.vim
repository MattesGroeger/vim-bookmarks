" Sign {{{

function! bm_sign#init()
  call bm_sign#define_highlights()
  sign define Bookmark texthl=BookmarkSign
  execute "sign define Bookmark text=". g:bookmark_sign
  if g:bookmark_highlight_lines
    sign define Bookmark linehl=BookmarkLine
  else
    sign define Bookmark linehl=
  endif
endfunction

function! bm_sign#define_highlights()
  highlight BookmarkSignDefault ctermfg=33 ctermbg=NONE
  highlight BookmarkLineDefault ctermfg=232 ctermbg=33
  highlight default link BookmarkSign BookmarkSignDefault
  highlight default link BookmarkLine BookmarkLineDefault
endfunction

function! bm_sign#add(file, line_nr)
  let l:sign_idx = g:bm_sign_index
  execute "sign place ". l:sign_idx ." line=" . a:line_nr ." name=Bookmark file=". a:file
  let g:bm_sign_index += 1
  return l:sign_idx
endfunction

function! bm_sign#del(file, sign_idx)
  execute "sign unplace ". a:sign_idx ." file=". a:file
endfunction

" Returns dict with {'sign_idx': 'line_nr'}
function! bm_sign#lines_for_signs(file)
  let l:bufnr = bufnr(a:file)
  let signs_raw = util#redir_execute(":sign place file=". a:file)
  let l:lines = split(signs_raw, "\n")
  let l:result = {}
  for l:line in l:lines
    let l:results = matchlist(l:line, 'line=\(\d\+\)\W\+id=\(\d\+\)\W\+name=bookmark\c')
    if len(l:results) ># 0
      let l:result[l:results[2]] = l:results[1]
    endif
  endfor
  return l:result
endfunction

" }}}
