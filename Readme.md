## vim-bookmarks

This plugin allows to add and remove line-based bookmarks with just one (!) keystroke. Bookmarks will be highlighted in the vim sign column (default).

### Features

* Toggle bookmarks per line
* Shows indicator in vim sign column
* Optional line highlighting
* Navigate all bookmarks with vim quickfix window
* Jump between bookmarks in current buffer (previous/next)
* Fully customisable (signs, sign column, line highlights, mappings)
* Preserves signs from other plugins

### Screenshot

![screenshot](https://raw.github.com/MattesGroeger/vim-bookmarks/master/screenshot.png)

1. Bookmars are indicated in sign column
2. Easily naviagate all bookmarks (`ma`)

## Installation

Before installation, please check your Vim supports signs by running `:echo has('signs')`.  `1` means you're all set; `0` means you need to install a Vim with signs support. If you're compiling Vim yourself you need the 'big' or 'huge' feature set. [MacVim][] supports signs.

Use your favorite plugin manager:

* [Pathogen][]
  * `git clone https://github.com/MattesGroeger/vim-bookmarks.git ~/.vim/bundle/vim-bookmarks`
* [Vundle][]
  1. Add `Bundle 'MattesGroeger/vim-bookmarks'` to .vimrc
  2. Run `:BundleInstall`
* [NeoBundle][]
  1. Add `NeoBundle 'MattesGroeger/vim-bookmarks'` to .vimrc
  2. Run `:NeoBundleInstall`
* [vim-plug][vimplug]
  1. Add `Plug 'MattesGroeger/vim-bookmarks'` to .vimrc
  2. Run `:PlugInstall`

## Usage

After installation you can directly start using it. You can do this by either using the default shortcuts or the commands:

| Action                                          | Shortcut    | Command                |
|-------------------------------------------------|-------------|------------------------|
| Add/remove bookmark at current line             | `mm`        | `:ToggleBookmark`      |
| Jump to next bookmark in buffer                 | `mn`        | `:NextBookmark`        |
| Jump to previous bookmark in buffer             | `mp`        | `:PrevBookmark`        |
| Show all bookmarks                              | `ma`        | `:ShowAllBookmarks`    |
| Clear bookmarks in buffer                       | `mc`        | `:ClearBookmarks`      |

You can change the shortcuts as you like, just read on...

## Customization

### Custom shortcuts

You can overwrite any of the default mappings. Just put the following into your `~/.vimrc` and adjust as you like:

```
nmap <Leader><Leader> <Plug>ToggleBookmark
nmap <Leader>a <Plug>ShowAllBookmarks
nmap <Leader>j <Plug>NextBookmark
nmap <Leader>k <Plug>PrevBookmark
nmap <Leader>c <Plug>ClearBookmarks
```

### Custom options

Put any of the following options into your `~/.vimrc` in order to overwrite the default behaviour.

#### Different sign

```
let g:bookmark_sign = '>>'
```

#### Enable line highlighting

Hightlight the whole line (default off).

```
let g:bookmark_highlight_lines = 1
```

### Custom colors

Overwrite the default colors by adding this to your colorscheme or `.vimrc`:

```
highlight BookmarkSign ctermbg=whatever ctermfg=whatever
highlight BookmarkLine ctermbg=whatever ctermfg=whatever
```

## FAQ

> Why are the colours in the sign column weird?

Your colorscheme is configuring the |hl-SignColumn| highlight group weirdly. Please see |BookmarksCustomisation| on customising the sign column.

> What happens if I also use another plugin which uses signs (e.g. Syntastic)?

Vim only allows one sign per line. Therefore bookmarks will override any existing sign. When removing the bookmark the original sign will show up again. In other words vim-bookmarks won't remove another plugin's signs.

> Why aren't any signs showing at all?

Here are some things you can check:

* Your git config is compatible with the version of git which your Vim is calling (`:echo system('git --version')`).
* Your Vim supports signs (`:echo has('signs')` should give `1`).

## Changelog

See the [release page](https://github.com/MattesGroeger/vim-bookmarks/releases) for all changes.

## Credits & Contribution

This plugin was developed by [Mattes Groeger][blog] under the [MIT License][license]. Pull requests are very welcome.

The following plugins where a great inspiration to me:
* [vmark.vim][vmark] by Michael Zhou
* [vim-gitgutter][gitgutter] by Andrew Stewart


  [pathogen]: https://github.com/tpope/vim-pathogen
  [vundle]: https://github.com/gmarik/vundle
  [neobundle]: https://github.com/Shougo/neobundle.vim
  [vimplug]: https://github.com/MattesGroeger/vim-plug
  [macvim]: http://code.google.com/p/macvim/
  [license]: https://github.com/MattesGroeger/vim-bookmarks/blob/master/LICENSE.txt
  [blog]: http://blog.mattes-groeger.de
  [vmark]: http://www.vim.org/scripts/script.php?script_id=4076
  [gitgutter]: https://github.com/airblade/vim-gitgutter
