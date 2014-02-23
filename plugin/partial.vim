" ============================================================================
" File:        partial.vim
" Description: VIM global plugin that provides a way to insert code generated
" from commands
" Maintainer:  Naquad <naquad at gmail dot com>
" Last Change: 23 February 2014
" License:     This program is free software. It comes without any warranty,
"              to the extent permitted by applicable law. You can redistribute
"              it and/or modify it under the terms of the Do What The Fuck You
"              Want To Public License, Version 2, as published by Sam Hocevar.
"              See http://sam.zoy.org/wtfpl/COPYING for more details.
"
" ============================================================================

if exists("g:loaded_partial")
    finish
endif

if v:version < 700
    echoerr "Partial: this plugin requires VIM >= 7.0"
    finish
endif

let g:loaded_partial = 1

if !exists('g:partial_command_signature')
  let g:partial_command_signature = '#!'
endif

function! s:Error(msg)
  echohl Error
  echo 'Partial: ' . a:msg
  echohl None
endfunction

let s:line_cont = '\\\s*$'

function! s:ExtractCommandAndStdin(lines, eof)
  let state = 0
  let indent = -1
  let cmd = {'command': '', 'stdin': ''}

  let lidx = 0
  let llen = len(a:lines)

  while lidx < llen
    if state == 0
      let indent = stridx(a:lines[lidx], g:partial_command_signature)

      if indent != -1
        let csl = len(g:partial_command_signature)

        while lidx < llen
          let cmd.command .= a:lines[lidx][csl + indent :]

          if match(cmd.command, s:line_cont) == -1
            let state = 1
            break
          endif

          let cmd.command = substitute(cmd.command, s:line_cont, '', '')
          let lidx += 1
        endwhile

        if state != 1
          call s:Error('unexpected end of command')
          return {}
        endif
      endif
    else
      let cmd.stdin .= a:lines[lidx][indent :] . a:eof
    endif

    let lidx += 1
  endwhile

  if state == 0
    call s:Error("can't find command in given range")
    return {}
  endif

  return cmd
endfunction

function! s:Cat(path)
  if getfsize(a:path)
    echo join(readfile(a:path), "\n")
  endif
endfunction

function! s:Indent(since, count, first)
  let indent = matchstr(getline(a:first), '^\s\+')
  if indent == '' || a:count == 0
    return
  endif

  for lidx in range(a:since, a:since + a:count - 1)
    let line = getline(lidx)
    call setline(lidx, indent . line)
  endfor
endfunction

let s:eols = {'dos': "\r\n", 'mac': "\r", 'unix': "\n"}

function! s:Partial(ignore_failure) range
  let cmd = s:ExtractCommandAndStdin(
        \   getline(a:firstline, a:lastline),
        \   get(s:eols, &ff, s:eols.unix)
        \ )

  if empty(cmd)
    return
  endif

  let sout = tempname()
  let serr = tempname()
  let cmdline = printf(
        \ '(%s) >%s 2>%s',
        \ cmd.command,
        \ shellescape(sout),
        \ shellescape(serr)
        \ )

  if empty(cmd.stdin)
    call system(cmdline)
  else
    call system(cmdline, cmd.stdin)
  endif

  if v:shell_error && a:ignore_failure != '!'
    call s:Error('command failed')
    call s:Cat(serr)
  else
    let olines = line('$')
    exec ':' . a:lastline . 'r ' . fnameescape(sout)
    call s:Indent(a:lastline + 1, line('$') - olines, a:firstline)
    call s:Cat(serr)
  endif

  call delete(sout)
  call delete(serr)
endfunction

command! -range -bang Partial <line1>,<line2>call <SID>Partial('<bang>') 
