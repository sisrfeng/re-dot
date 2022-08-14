" repeat.vim - Let the repeat command repeat plugin maps
" Maintainer:   Tim Pope
" Version:      1.2
" GetLatestVimScripts: 2136 1 :AutoInstall: repeat.vim

" Developers:
" Basic usage is as follows:
"
"   silent! call repeat#set("\<Plug>MappingToRepeatCommand",3)
"
    "\ " The first argument is the mapping that will be invoked when the |.| key
    "\ is pressed.
    "\ Typically,
    "\ it will be the same as the mapping the user invoked.
    "\ This sequence will be stuffed into the input queue literally.
    "\ Thus you must encode special keys by
    "\ prefixing them with a ¿backslash¿ inside double ¿quotes¿.
    "\ The second argument is the default count.
    "\ This is the number that will be prefixed to the mapping
    "\ if no explicit numeric argument was given.
    "\ The value of the ¿v:count¿ variable is usually correct and
    "\     it will be used if the second parameter is omitted.
    "\ If your mapping doesn't accept a numeric argument and
    "\ you never want to receive one,
    "\     pass a value of -1.

    "\ Make sure to call the repeat#set function _after_ making changes to the file.
    "\ For mappings that use a register and
    "\ want the same register used on repetition,
    "\ use:
    "\ "   silent! call repeat#setreg("\<Plug>MappingToRepeatCommand", v:register)
    "\ This function can (and probably needs to be)
    "\ called before making changes to the file
    "\     (as those typically clear v:register).
    "\ Therefore,
    "\ the call sequence in your mapping will look like this:
    "\ "
    "\ "
    "\ "   nnoremap <silent> <Plug>MyMap
        "\ "   \   :<C-U>execute 'silent! call repeat#setreg("\<lt>Plug>MyMap", v:register)'<Bar>
        "\ "   \   call <SID>MyFunction(v:register, ...)<Bar>
        "\ "   \   silent! call repeat#set("\<lt>Plug>MyMap")<CR>

if exists("g:loaded_repeat")   | finish  | endif
let g:loaded_repeat = 1

let g:repeat_tick = -1
let g:repeat_reg = ['', '']

" Special function to avoid spurious repeats in a related, naturally repeating
" mapping when your repeatable mapping doesn't increase b:changedtick.
fun! repeat#invalidate()
    au! repeat_custom_motion
    let g:repeat_tick = -1
endf

fun! repeat#set(sequence,...)
    let g:repeat_sequence = a:sequence
    let g:repeat_count = a:0 ? a:1 : v:count
    let g:repeat_tick = b:changedtick
    aug  repeat_custom_motion
        au!
        au CursorMoved <buffer> let g:repeat_tick = b:changedtick | autocmd! repeat_custom_motion
    aug  END
endf

fun! repeat#setreg(sequence,register)
    let g:repeat_reg = [a:sequence, a:register]
endf


fun! s:default_register()
    let values = split(&clipboard, ',')
    if index(values, 'unnamedplus') != -1
        return '+'
    elseif index(values, 'unnamed') != -1
        return '*'
    el
        return '"'
    en
endf

fun! repeat#run(count)
    let s:errmsg = ''
    try
        if g:repeat_tick == b:changedtick
            let r = ''
            if g:repeat_reg[0] ==# g:repeat_sequence && !empty(g:repeat_reg[1])
                " Take the original register, unless another (non-default, we
                " unfortunately cannot detect no vs. a given default register)
                " register has been supplied to the repeat command (as an
                " explicit override).
                let regname = v:register ==# s:default_register() ? g:repeat_reg[1] : v:register
                if regname ==# '='
                    " This causes a re-evaluation of the expression on repeat, which
                    " is what we want.
                    let r = '"=' . getreg('=', 1) . "\<CR>"
                el
                    let r = '"' . regname
                en
            en

            let c = g:repeat_count
            let s = g:repeat_sequence
            let cnt = c == -1 ? "" : (a:count ? a:count : (c ? c : ''))
            if ((v:version == 703 && has('patch100')) || (v:version == 704 && !has('patch601')))
                exe 'norm ' . r . cnt . s
            elseif v:version <= 703
                call feedkeys(r . cnt, 'n')
                call feedkeys(s, '')
            el
                call feedkeys(s, 'i')
                call feedkeys(r . cnt, 'ni')
            en
        el
            if ((v:version == 703 && has('patch100')) || (v:version == 704 && !has('patch601')))
                exe 'norm! '.(a:count ? a:count : '') . '.'
            el
                call feedkeys((a:count ? a:count : '') . '.', 'ni')
            en
        en
    catch /^Vim(normal):/
        let s:errmsg = v:errmsg
        return 0
    endtry
    return 1
endf
fun! repeat#errmsg()
    return s:errmsg
endf

fun! repeat#wrap(command,count)
    let preserve = (g:repeat_tick == b:changedtick)
    call feedkeys((a:count ? a:count : '').a:command, 'n')
    exe (&foldopen =~# 'undo\|all' ? 'norm! zv' : '')
    if preserve
        let g:repeat_tick = b:changedtick
    en
endf

nno  <silent> <Plug>(RepeatDot)      :<C-U>if !repeat#run(v:count)<Bar>echoerr repeat#errmsg()<Bar>endif<CR>
nno  <silent> <Plug>(RepeatUndo)     :<C-U>call repeat#wrap('u',v:count)<CR>
nno  <silent> <Plug>(RepeatUndoLine) :<C-U>call repeat#wrap('U',v:count)<CR>
nno  <silent> <Plug>(RepeatRedo)     :<C-U>call repeat#wrap("\<Lt>C-R>",v:count)<CR>

if !hasmapto('<Plug>(RepeatDot)', 'n')
    nmap . <Plug>(RepeatDot)
en
if !hasmapto('<Plug>(RepeatUndo)', 'n')
    nmap u <Plug>(RepeatUndo)
en
if maparg('U','n') ==# '' && !hasmapto('<Plug>(RepeatUndoLine)', 'n')
    nmap U <Plug>(RepeatUndoLine)
en
if !hasmapto('<Plug>(RepeatRedo)', 'n')
    nmap <C-R> <Plug>(RepeatRedo)
en

aug  repeatPlugin
    au!
    au BufLeave,BufWritePre,BufReadPre * let g:repeat_tick = (g:repeat_tick == b:changedtick || g:repeat_tick == 0) ? 0 : -1
    au BufEnter,BufWritePost * if g:repeat_tick == 0|let g:repeat_tick = b:changedtick|endif
aug  END

