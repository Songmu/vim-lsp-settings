function! s:install_or_update() abort
  let l:line = getline('.')
  let l:token = matchlist(getline('.'), '\[.\] \(\S\+\)\s\+(\([^)]\+\))')
  let l:command = l:token[1]
  let l:languages = split(l:token[2], ',\s*')
  if empty(l:command)
    return
  endif
  if confirm('Install ' . l:command . ' ?', "&OK\n&Cancel") ==# 2
    return
  endif
  bw!
  call lsp_settings#install_server(l:languages[0], l:command)
endfunction

function! s:uninstall() abort
  let l:command = substitute(getline('.'), '\[.\] \(\S\+\).*', '\1', '')
  if empty(l:command)
    return
  endif
  if confirm('Uninstall ' . l:command . ' ?', "&OK\n&Cancel") ==# 2
    return
  endif
  bw!
  exe 'LspUninstallServer' l:command
endfunction

function! s:update() abort
  setlocal buftype=nofile bufhidden=wipe noswapfile
  setlocal cursorline
  setlocal nomodified
  
  silent! %d _
  let l:names = []
  let l:types = {}
  let l:installer_dir = lsp_settings#installer_dir()
  let l:settings = lsp_settings#settings()
  for l:ft in sort(keys(l:settings))
    for l:conf in l:settings[l:ft]
      let l:missing = 0
      for l:require in l:conf.requires
        if !executable(l:require)
          let l:missing = 1
          break
        endif
      endfor    
      if l:missing ># 0
        continue
      endif
      call add(l:names, l:conf.command)
      if !has_key(l:types, l:conf.command)
        let l:types[l:conf.command] = [l:ft]
      else
        call add(l:types[l:conf.command], l:ft)
      endif
    endfor    
  endfor
  let l:names = uniq(sort(l:names))
  call map(l:names, {_, v -> printf('%s %s (%s)', lsp_settings#executable(v) ? '[*]' : '[ ]', v, join(l:types[v], ', '))})
  set modifiable
  cal setline(1, l:names)
  set nomodifiable
endfunction

function! lsp_settings#ui#open() abort
  silent new __LSP_SETTINGS__
  only!
  call s:update()
  nnoremap <buffer> i :call <SID>install_or_update()<cr>
  nnoremap <buffer> x :call <SID>uninstall()<cr>
  nnoremap q :bw<cr>
  redraw
  echomsg 'Type i to install, or x to uninstall'
endfunction
