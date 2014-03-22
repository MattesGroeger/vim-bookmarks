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

describe 'model#has_bookmarks_in_file'

  after
    call model#del_all()
  end

  it 'should have no bookmarks'
    Expect model#has_bookmarks_in_file('foo') to_be_false
  end

  it 'should have bookmark'
    call model#add_bookmark('foo', 1, 3, 'bar')
    Expect model#has_bookmarks_in_file('foo') to_be_true
    call model#del_bookmark_at_line('foo', 3)
  end

end
