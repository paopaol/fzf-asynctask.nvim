if exists('g:loaded_fzf_asynctask') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
command! FzfAsyncTask lua require'fzf-asynctask'.async_task()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_fzf_asynctask = 1
