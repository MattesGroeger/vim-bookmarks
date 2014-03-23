let g:bm_sign_index = 1
let g:bookmark_sign = 'xy'
let g:bookmark_highlight_lines = 0

describe 'uninitialized signs'

  it 'should initialize'
    call bm_sign#init()

    Expect g:bm_sign_index ==# 1
    Expect util#redir_execute(":sign list Bookmark") ==#
          \ "sign Bookmark text=xy linehl= texthl=BookmarkSign"
    Expect split(util#redir_execute(":highlight BookmarkSignDefault"), '\n')[0] ==#
          \ "BookmarkSignDefault xxx ctermfg=33"
    Expect split(util#redir_execute(":highlight BookmarkLineDefault"), '\n')[0] ==#
          \ "BookmarkLineDefault xxx ctermfg=232 ctermbg=33"
  end

  it 'should initialize with line highlight'
    let g:bookmark_highlight_lines = 1

    call bm_sign#init()

    Expect util#redir_execute(":sign list Bookmark") ==#
          \ "sign Bookmark text=xy linehl=BookmarkLine texthl=BookmarkSign"
  end

end

describe "initialized signs"

  before
    let g:bm_sign_index = 1
    call bm_sign#init()
    execute ":new"
    execute ":e LICENSE.txt"
    let s:test_file = expand("%:p")
  end

  it 'should add signs'
    call bm_sign#add(s:test_file, 2)
    call bm_sign#add(s:test_file, 10)

    let signs = util#redir_execute(":sign place file=". s:test_file)
    let lines = bm_sign#lines_for_signs(s:test_file)

    Expect g:bm_sign_index ==# 3
    Expect len(split(signs, '\n')) ==# 4
    Expect lines ==# {'1': '2', '2': '10'}
  end

  it 'should delete signs'
    let idx1 = bm_sign#add(s:test_file, 2)
    let idx2 = bm_sign#add(s:test_file, 10)
    call bm_sign#del(s:test_file, idx1)
    call bm_sign#del(s:test_file, idx2)

    let signs = util#redir_execute(":sign place file=". s:test_file)
    let lines = bm_sign#lines_for_signs(s:test_file)

    Expect lines ==# {}
    Expect len(split(signs, '\n')) ==# 1
  end

  after
    execute ":q!"
  end

end
