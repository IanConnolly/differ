sign define DifferAdd text=+ texthl=DifferAdd
sign define DifferMod text=~ texthl=DifferChange
sign define DifferMod1 text=!1 texthl=DifferChange
sign define DifferMod2 text=!2 texthl=DifferChange
sign define DifferMod3 text=!3 texthl=DifferChange
sign define DifferMod4 text=!4 texthl=DifferChange
sign define DifferMod5 text=!5 texthl=DifferChange
sign define DifferMod6 text=!6 texthl=DifferChange
sign define DifferMod7 text=!7 texthl=DifferChange
sign define DifferMod8 text=!8 texthl=DifferChange
sign define DifferMod9 text=!9 texthl=DifferChange
sign define DifferDel text=__ texthl=DifferDelete
sign define DifferDel1 text=_1 texthl=DifferDelete
sign define DifferDel2 text=_2 texthl=DifferDelete
sign define DifferDel3 text=_3 texthl=DifferDelete
sign define DifferDel4 text=_4 texthl=DifferDelete
sign define DifferDel5 text=_5 texthl=DifferDelete
sign define DifferDel6 text=_6 texthl=DifferDelete
sign define DifferDel7 text=_7 texthl=DifferDelete
sign define DifferDel8 text=_8 texthl=DifferDelete
sign define DifferDel9 text=_9 texthl=DifferDelete
sign define DifferDummy

highlight default link DifferAdd    GitGutterAdd
highlight default link DifferChange GitGutterChange
highlight default link DifferDelete GitGutterDelete

let s:previous_lines = {}

function! Differ()
  if &ft == 'qf' || &ft == 'terminal'
    return
  endif

  let buffer = expand('%')
  let previous_lines = get(s:previous_lines, buffer, [])

  if get(g:, "differ_always_show_sign_column", 0)
    if len(previous_lines) == 0
      execute 'sign place' 1 'line='. eval(1) 'name='. 'DifferDummy' 'file='. buffer
    endif
  endif

  for i in previous_lines
    execute 'sign unplace' i
    if get(g:, "differ_always_show_sign_column", 0)
      if i == 1
        execute 'sign place' 1 'line='. eval(1) 'name='. 'DifferDummy' 'file='. buffer
      endif
    endif
  endfor
  let s:previous_lines[buffer] = []

  if has('nvim')
    call jobstart(['annotate-differ', buffer], extend({'buffer': buffer}, s:callbacks))
  else
    let diff = system('annotate-differ ' . buffer)
    call s:DiffUpdate(split(diff, '\n'), buffer)
  endif
endfunction

function! s:DiffUpdate(lines, buffer)
  for line in a:lines
    if strlen(line) > 0
      let i_sym = split(line, '=')
      let i = i_sym[0]
      let sym = i_sym[1]
      call add(s:previous_lines[a:buffer], eval(i))

      if get(g:, "differ_always_show_sign_column", 0)
        if i == 1
          execute 'sign unplace' i
        endif
      endif

      execute 'sign place' i 'line='. eval(i) 'name='. sym 'file='. a:buffer
    endif
  endfor
endfunction

function! s:JobHandler(job_id, data, event)
  if a:event == 'stdout'
    call s:DiffUpdate(a:data, self.buffer)
  elseif a:event == 'stderr'
    echoerr join(a:data, '\n')
  endif
endfunction

let s:callbacks = {
\ 'on_stdout': function('s:JobHandler'),
\ 'on_stderr': function('s:JobHandler'),
\ 'on_exit': function('s:JobHandler')
\ }
