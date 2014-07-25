## vim-bookmarks [![Build Status](https://travis-ci.org/MattesGroeger/vim-bookmarks.svg)](https://travis-ci.org/MattesGroeger/vim-bookmarks) [![Release](http://img.shields.io/github/release/MattesGroeger/vim-bookmarks.svg)](https://github.com/MattesGroeger/vim-bookmarks/releases)

This vim plugin allows toggling bookmarks per line. A quickfix window gives access to all bookmarks. Annotations can be added as well. These are special bookmarks with a comment attached. They are useful for preparing code reviews. All bookmarks will be restored on the next startup.

![Preview](https://raw.github.com/MattesGroeger/vim-bookmarks/master/preview.gif)

#### Bright Colors Example

[![Screenshot Bright Colors](https://raw.github.com/MattesGroeger/vim-bookmarks/master/screenshot-bright-small.png)](https://raw.github.com/MattesGroeger/vim-bookmarks/master/screenshot-bright.png)

```vim
highlight BookmarkSign ctermbg=NONE ctermfg=160
highlight BookmarkLine ctermbg=194 ctermfg=NONE
let g:bookmark_sign = '♥'
let g:bookmark_highlight_lines = 1
```

### Features

* Toggle bookmarks per line ⚑
* Add annotations per line ☰
* Navigate all bookmarks with quickfix window
* Bookmarks will be restored on next startup
* Fully customisable (signs, sign column, highlights, mappings)
* Works independently from [vim marks](http://vim.wikia.com/wiki/Using_marks)

## Installation

Before installation, please check your Vim supports signs by running `:echo has('signs')`.  `1` means you're all set; `0` means you need to install a Vim with signs support. If you're compiling Vim yourself you need the 'big' or 'huge' feature set. [MacVim][] supports signs.

Use your favorite plugin manager:

* [Pathogen][]
  * `git clone https://github.com/MattesGroeger/vim-bookmarks.git ~/.vim/bundle/vim-bookmarks`
* [Vundle][]
  1. Add `Plugin 'MattesGroeger/vim-bookmarks'` to .vimrc
  2. Run `:PluginInstall`
* [NeoBundle][]
  1. Add `NeoBundle 'MattesGroeger/vim-bookmarks'` to .vimrc
  2. Run `:NeoBundleInstall`
* [vim-plug][vimplug]
  1. Add `Plug 'MattesGroeger/vim-bookmarks'` to .vimrc
  2. Run `:PlugInstall`

## Usage

After installation you can directly start using it. You can do this by either using the default shortcuts or the commands:

| Action                                          | Shortcut    | Command                      |
|-------------------------------------------------|-------------|------------------------------|
| Add/remove bookmark at current line             | `mm`        | `:BookmarkToggle`            |
| Add/edit/remove annotation at current line      | `mi`        | `:BookmarkAnnotate <TEXT>`   |
| Jump to next bookmark in buffer                 | `mn`        | `:BookmarkNext`              |
| Jump to previous bookmark in buffer             | `mp`        | `:BookmarkPrev`              |
| Show all bookmarks                              | `ma`        | `:BookmarkShowAll`           |
| Clear bookmarks in current buffer only          | `mc`        | `:BookmarkClear`             |
| Clear bookmarks in all buffers                  | `mx`        | `:BookmarkClearAll`          |
| Save all bookmarks to a file                    |             | `:BookmarkSave <FILE_PATH>`  |
| Load bookmarks from a file                      |             | `:BookmarkLoad <FILE_PATH>`  |

You can change the shortcuts as you like, just read on...

## Customization

### Key Bindings

You can overwrite any of the default mappings. Just put the following into your `~/.vimrc` and adjust as you like:

```
nmap <Leader><Leader> <Plug>BookmarkToggle
nmap <Leader>i <Plug>BookmarkAnnotate
nmap <Leader>a <Plug>BookmarkShowAll
nmap <Leader>j <Plug>BookmarkNext
nmap <Leader>k <Plug>BookmarkPrev
nmap <Leader>c <Plug>BookmarkClear
nmap <Leader>x <Plug>BookmarkClearAll
```

### Colors

Overwrite the default hightlight groups by adding this to your colorscheme or `.vimrc`:

```
highlight BookmarkSign ctermbg=whatever ctermfg=whatever
highlight BookmarkAnnotationSign ctermbg=whatever ctermfg=whatever
highlight BookmarkLine ctermbg=whatever ctermfg=whatever
highlight BookmarkAnnotationLine ctermbg=whatever ctermfg=whatever
```

### Options

Put any of the following options into your `~/.vimrc` in order to overwrite the default behaviour.

| Option                                         | Default                  | Description                                             |
|------------------------------------------------|--------------------------|---------------------------------------------------------|
| `let g:bookmark_sign = '>>'`                   | ⚑                        | Sets bookmark icon for sign column                      |
| `let g:bookmark_annotation_sign = '##'`        | ☰                        | Sets bookmark annotation icon for sign column           |
| `let g:bookmark_auto_save = 0`                 | 1                        | Enables/disables automatic saving for bookmarks         |
| `let g:bookmark_auto_save_file = '/bookmarks'` | $HOME .'/.vim-bookmarks' | Sets file for auto saving                               |
| `let g:bookmark_auto_close = 1`                | 0                        | Automatically close bookmarks split when jumping to a bookmark |
| `let g:bookmark_highlight_lines = 1`           | 0                        | Enables/disables line highlighting                      |
| `let g:bookmark_show_warning = 0`              | 1                        | Enables/disables warning when clearing all bookmarks    |
| `let g:bookmark_center = 1`                    | 0                        | Enables/disables line centering when jumping to bookmark|

### Silent saving and loading

Call functions BookmarkSave, BookmarkLoad and BookmarkClearAll with the last argument set to 0 to perform these operations silently. You may use this to manage your bookmark list transparently from within your custom script.

## FAQ

> Why are the colours in the sign column weird?

Your colorscheme is configuring the `SignColumn` highlight group weirdly. To change that add this to your `.vimrc`: `highlight SignColumn ctermbg=whatever`.

> What happens if I also use another plugin which uses signs (e.g. Syntastic)?

Vim only allows one sign per line. Therefore bookmarks will override any existing sign. When removing the bookmark the original sign will show up again. In other words vim-bookmarks won't remove another plugin's signs.

> Why aren't any signs showing at all?

Make sure your vim supports signs: `:echo has('signs')` should give `1`

## Changelog

See the [release page](https://github.com/MattesGroeger/vim-bookmarks/releases) for all changes.

## Credits & Contribution

This plugin was developed by [Mattes Groeger][blog] under the [MIT License][license]. Pull requests are very welcome.

The following plugins were a great inspiration to me:
* [vmark.vim][vmark] by Michael Zhou
* [vim-gitgutter][gitgutter] by Andrew Stewart


  [pathogen]: https://github.com/tpope/vim-pathogen
  [vundle]: https://github.com/gmarik/vundle
  [neobundle]: https://github.com/Shougo/neobundle.vim
  [vimplug]: https://github.com/MattesGroeger/vim-plug
  [macvim]: http://code.google.com/p/macvim/
  [license]: https://github.com/MattesGroeger/vim-bookmarks/blob/master/LICENSE
  [blog]: http://blog.mattes-groeger.de
  [vmark]: http://www.vim.org/scripts/script.php?script_id=4076
  [gitgutter]: https://github.com/airblade/vim-gitgutter
