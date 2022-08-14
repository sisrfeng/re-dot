# repeat.vim

Repeat.vim remaps `.` in a way that plugins can tap into  it.

The following plugins support repeat.vim:

* [surround.vim](https://github.com/tpope/vim-surround)
* [speeddating.vim](https://github.com/tpope/vim-speeddating)
* [unimpaired.vim](https://github.com/tpope/vim-unimpaired)
* [vim-easyclip](https://github.com/svermeulen/vim-easyclip)
* [vim-radical](https://github.com/glts/vim-radical)

Adding support to a plugin is generally as simple as the following command at the end of your map functions.


    silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)


