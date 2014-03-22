describe 'empty model'

  it 'should have no bookmarks'
    Expect model#has_bookmarks_in_file('foo') to_be_false
  end

  it 'should add bookmark'
    Expect model#has_bookmarks_in_file('foo') to_be_false
    Expect model#has_bookmark_at_line('foo', 3) to_be_false

    call model#add_bookmark('foo', 1, 3, 'bar')

    Expect model#has_bookmarks_in_file('foo') to_be_true
    Expect model#has_bookmark_at_line('foo', 3) to_be_true
  end

  after
    call model#del_all()
  end

end

describe 'model with bookmark'

  before
    call model#add_bookmark('foo', 1, 3, 'bar')
  end

  it 'should get bookmark by line'
    let bookmark = model#get_bookmark_by_line('foo', 3)

    Expect bookmark['line_nr']  ==# 3
    Expect bookmark['sign_idx'] ==# 1
    Expect bookmark['content']  ==# 'bar'
  end

  it 'should get bookmark by sign'
    let bookmark = model#get_bookmark_by_sign('foo', 1)

    Expect bookmark['line_nr']  ==# 3
    Expect bookmark['sign_idx'] ==# 1
    Expect bookmark['content']  ==# 'bar'
  end

  it 'should update bookmark'
    call model#update_bookmark_for_sign('foo', 1, 5, 'baz')

    let bookmark = model#get_bookmark_by_line('foo', 5)
    Expect bookmark['line_nr']  ==# 5
    Expect bookmark['sign_idx'] ==# 1
    Expect bookmark['content']  ==# 'baz'
    Expect bookmark ==# model#get_bookmark_by_sign('foo', 1)
  end

  it 'should delete bookmark at line'
    call model#del_bookmark_at_line('foo', 3)

    Expect model#has_bookmark_at_line('foo', 3) to_be_false
  end

  after
    call model#del_all()
  end

end

describe 'model with multiple bookmarks in different files'

  before
    call model#add_bookmark('file1', 1, 12, 'file1/line12')
    call model#add_bookmark('file2', 2, 34, 'file2/line34')
    call model#add_bookmark('file1', 3, 2,  'file1/line10')
    call model#add_bookmark('file1', 4, 45, 'file1/line45')
  end

  it 'should return all bookmarks of file per line'
    let dict1 = model#all_bookmarks_by_line('file1')
    let dict2 = model#all_bookmarks_by_line('file2')

    Expect len(keys(dict1)) ==# 3
    Expect len(keys(dict2)) ==# 1
    Expect dict1[12]['sign_idx'] ==# 1
    Expect dict2[34]['sign_idx'] ==# 2
    Expect dict1[2]['sign_idx']  ==# 3
    Expect dict1[45]['sign_idx'] ==# 4
  end

  it 'should return all lines'
    let lines = model#all_lines('file1')

    Expect lines ==# ['2', '12', '45']
  end

  it 'should return all files with bookmarks'
    let files = model#all_files()

    Expect files ==# ['file1', 'file2']
  end

  after
    call model#del_all()
  end

end

describe 'model#del_all'

  it 'should reset the model'
    call model#add_bookmark('file1', 1, 1, 'line1')
    call model#add_bookmark('file2', 2, 1, 'line1')

    call model#del_all()

    Expect empty(g:line_map) to_be_true
    Expect empty(g:sign_map) to_be_true
    Expect model#has_bookmarks_in_file('file1') to_be_false
    Expect model#has_bookmarks_in_file('file2') to_be_false
  end

end
