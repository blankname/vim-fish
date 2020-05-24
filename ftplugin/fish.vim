if exists('b:did_ftplugin')
    finish
end
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim

setlocal comments=:#
setlocal commentstring=#%s
setlocal define=\\v^\\s*function>
setlocal foldexpr=fish#Fold()
setlocal formatoptions+=ron1
setlocal formatoptions-=t
setlocal include=\\v^\\s*\\.>
setlocal iskeyword=@,48-57,-,_,.
setlocal suffixesadd^=.fish

" Use the 'j' format option when available.
if v:version ># 703 || v:version ==# 703 && has('patch541')
    setlocal formatoptions+=j
endif

if executable('fish_indent')
    setlocal formatexpr=fish#Format()
endif

function! s:append_paths(data)
  execute 'setlocal path+=' . join(a:data, ',')
endfunction

if executable('fish')
    setlocal omnifunc=fish#Complete

    " The command used to get the value of $fish_function_path
    let s:path_cmd = ['fish', '-c', 'echo $fish_function_path']

    " FIXME(test job_start on windows, in case we can't use a list for the
    " s:path_cmd there)
    " vim
    if exists('*job_start')
      function! s:close_cb(channel)
        let l:data = []
        while ch_status(a:channel, {'part': 'out'}) == 'buffered'
          call extend(l:data, split(ch_read(a:channel)))
        endwhile

        call s:append_paths(l:data)
      endfunction

      call job_start(s:path_cmd, { 'close_cb': function('s:close_cb')})
    " neovim
    elseif exists('*jobstart')
      call jobstart(s:path_cmd,
            \ {
            \  'stdout_buffered': v:true,
            \  'on_stdout':{ j,d,e -> s:append_paths(split(d[0])) }
            \ })
    " fallback
    else
      call s:append_paths(split(system(s:path_cmd)))
    endif
else
    setlocal omnifunc=syntaxcomplete#Complete
endif

" Use the 'man' wrapper function in fish to include fish's man pages.
" Have to use a script for this; 'fish -c man' would make the the man page an
" argument to fish instead of man.
execute 'setlocal keywordprg=fish\ '.fnameescape(expand('<sfile>:p:h:h').'/bin/man.fish')

let b:match_ignorecase = 0
if has('patch-7.3.1037')
    let s:if = '%(else\s\+)\@15<!if'
else
    let s:if = '%(else\s\+)\@<!if'
endif

let b:match_words = escape(
            \'<%(begin|function|'.s:if.'|switch|while|for)>:<else\s\+if|case>:<else>:<end>'
            \, '<>%|)')

let b:endwise_addition = 'end'
let b:endwise_words = 'begin,function,if,switch,while,for'
let b:endwise_syngroups = 'fishKeyword,fishConditional,fishRepeat'

let b:undo_ftplugin = "
            \ setlocal comments< commentstring< define< foldexpr< formatoptions<
            \|setlocal include< iskeyword< suffixesadd<
            \|setlocal formatexpr< omnifunc< path< keywordprg<
            \|unlet! b:match_words b:endwise_addition b:endwise_words b:endwise_syngroups
            \"

let &cpo = s:save_cpo
unlet s:save_cpo
