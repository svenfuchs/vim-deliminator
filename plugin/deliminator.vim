ruby <<
  path = VIM.evaluate('&runtimepath').split(',').detect { |path| path.include?('vim-deliminator') }
  $:.unshift("#{path}/lib")
  require 'deliminator'
.

function! Deliminator()
  ruby Deliminator.setup
endfunction

function! DeliminatorDelimiter(char)
  ruby Deliminator.delimiter(Vim.evaluate('a:char'))
  return SubstituteKeys(l:result)
endfunction

function! DeliminatorBackspace()
  ruby Deliminator.backspace()
  return SubstituteKeys(l:result)
endfunction

function! DeliminatorReload()
  ruby load('delimiter')
endfunction

function! SubstituteKeys(string)
  let string = a:string
  for [key, value] in items({ '<Left>': "\<Left>", '<Right>': "\<Right>", '<BS>': "\<BS>", '<Del>': "\<Del>" })
    echo value
    let string = substitute(string, key, value, '')
  endfor
  return string
endfunction

command! Deliminator :call Deliminator()
command! DeliminatorReload :call DeliminatorReload()
