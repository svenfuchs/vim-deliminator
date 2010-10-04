ruby <<
  def deliminator_path
    VIM.evaluate('&runtimepath').split(',').detect { |path| path.include?('vim-deliminator') }
  end

  $:.unshift("#{deliminator_path}/lib")
  require 'deliminator'
.

function! Deliminator()
  ruby Deliminator.setup
endfunction

function! DeliminatorDelimiter(char)
  ruby Deliminator.delimiter(Vim.evaluate('a:char'))
  return SubstituteKeys(l:result)
endfunction

function! DeliminatorSpace()
  ruby Deliminator.space()
  return SubstituteKeys(l:result)
endfunction

function! DeliminatorBackspace()
  ruby Deliminator.backspace()
  return SubstituteKeys(l:result)
endfunction

function! DeliminatorReload()
  ruby <<
    Dir["#{deliminator_path}/**/*.rb"].each { |path| load(path) }
.
endfunction

function! SubstituteKeys(string)
  let string = a:string
  let keys = { '<Left>': "\<Left>", '<Right>': "\<Right>", '<BS>': "\<BS>", '<Del>': "\<Del>" }
  for [key, value] in items(keys)
    echo value
    let string = substitute(string, key, value, '')
  endfor
  return string
endfunction

command! Deliminator :call Deliminator()
command! DeliminatorReload :call DeliminatorReload()
