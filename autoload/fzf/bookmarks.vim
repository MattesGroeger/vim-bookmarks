""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" color functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:get_color(attr, ...)
    let gui = has('termguicolors') && &termguicolors
    let fam = gui ? 'gui' : 'cterm'
    let pat = gui ? '^#[a-f0-9]\+' : '^[0-9]\+$'
    for group in a:000
        let code = synIDattr(synIDtrans(hlID(group)), a:attr, fam)
        if code =~? pat
            return code
        endif
    endfor
    return ''
endfunction

if &t_Co == 256
    let s:ansi = {'black': 234, 'red': 196, 'green': 46, 'yellow': 226, 'blue': 63, 'magenta': 201, 'cyan': 51}
else
    let s:ansi = {'black': 30, 'red': 31, 'green': 32, 'yellow': 33, 'blue': 34, 'magenta': 35, 'cyan': 36}
endif

function! s:csi(color, fg)
    let prefix = a:fg ? '38;' : '48;'
    if a:color[0] == '#'
        return prefix.'2;'.join(map([a:color[1:2], a:color[3:4], a:color[5:6]], 'str2nr(v:val, 16)'), ';')
    endif
    return prefix.'5;'.a:color
endfunction

function! s:ansi(str, group, default, ...)
    let fg = s:get_color('fg', a:group)
    let bg = s:get_color('bg', a:group)
    let color = s:csi(empty(fg) ? s:ansi[a:default] : fg, 1) .
                \ (empty(bg) ? '' : s:csi(bg, 0))
    return printf("\x1b[%s%sm%s\x1b[m", color, a:0 ? ';1' : '', a:str)
endfunction

for s:color_name in keys(s:ansi)
    execute "function! s:".s:color_name."(str, ...)\n"
                \ "  return s:ansi(a:str, get(a:, 1, ''), '".s:color_name."')\n"
                \ "endfunction"
endfor


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" format functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:pad(t, n)
    if len(a:t) > a:n
        return a:t[:(a:n-1)]."…"
    else
        let spaces = a:n - len(a:t)
        let spaces = printf("%".spaces."s", "")
        return a:t.spaces
    endif
endfunction

function! s:is_annotation(t)
    if a:t =~ "^Annotation: " | return s:green("§ ".a:t[12:]) | endif
endfunction

function! s:format_text(t, f)
    """Format second column with text and filename."""
    let text = a:t | let fname = a:f
    
    " strip leading spaces and tabs
    let text = substitute(text, "^ *", "", "")
    let text = substitute(text, "^\t*", "", "")

    " when colorizing text, the actual string will be longer than the one
    " that is showed, store the difference and add it to the padding
    let slen = len(text)
    let text = substitute(text, "\t", s:cyan("\\\\t"), "g")
    let diff = len(text) - slen

    let annotation = s:is_annotation(text) | let slen = len(text)
    if !empty(annotation) | let text = annotation | let diff = len(text) - slen + 10 | endif

    return s:pad(text, 60+diff)."\t".fname
endfunction

function! s:format_line(b)
    """Format fzf line."""

    let list = []
    let line = split(a:b, ":")
    let fname = fnamemodify(line[0], ":.") | let lnr = line[1] | let text = join(line[2:], ":")

    " colon in fname? it would mess up the line, skip it
    if !filereadable(fname) | return '' | endif

    let text = s:format_text(text, fname)
    return s:yellow(lnr)."\t".text
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" fzf functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! fzf#bookmarks#open(line)
    let line = split(a:line, "\t")
    let fname = line[2] | let lnr = line[0]

    if bufname(bufnr("%")) !=# fname | execute "e ".fname | endif
    execute "normal! ".lnr."gg"
endfunction

function! fzf#bookmarks#list()
    """Show a list of current bookmarks."""

    let list = []
    for b in bm#location_list()
        let line = s:format_line(b)
        if line != '' | call add(list, s:format_line(b)) | endif
    endfor
    return list
endfunction

