"
" This script is to test various aspects of the GetChar event.  Look at the
" test switches, source it, and try it out.
"
"
" To Do:
"
" - <TAB> expansion was broken in the command line.
"   (fixed accidentally?  Now resetting KeyTyped and KeyStuffed to values
"   before GetChar event is processed, or values set by it.)
"

let s:mode_names = {
			\ 'n' : 	'Normal',
			\ 'v' : 	'Visual by character',
			\ 'V' : 	'Visual by line',
			\ "\<C-V>" : 	'Visual blockwise',
			\ 's' : 	'Select by character',
			\ 'S' : 	'Select by line',
			\ "\<C-S>" : 	'Select blockwise',
			\ 'i' : 	'Insert',
			\ 'R' : 	'Replace',
			\ 'c' : 	'Command-line',
			\ 'r' : 	'Hit-enter prompt',
			\ }


let s:verbose = 1
let g:counter = 0
let s:last_char = ''
let s:Drain = ''
let s:Drain_ok = 1

function! Tst()
	let g:counter += 1

	if s:verbose
		echomsg     'key=(' . strtrans( v:getchar ) . '), '
				\ . 'x[0]=(' . printf('<%02X>', char2nr( v:getchar[0] ) ) . '), '
				\ . 'count=' . g:counter . ', '
				\ . 'type=' . v:getchartype . ', '
				\ . 'mode=' . s:mode_names[ mode() ]
	endif


	" Test draining mappings and stuff from the typeahead buffer:
	"
	" This has a side effect of eating commands like 'x' and 's'
	" since they are actually implemented as 'd ' and 'c '.  KeyTyped check
	" avoids it.
	if s:Drain_ok && v:getchartype != 'KeyTyped'
		" Note: getchar(1) will return ESC if it detects a busy state, even if
		" no chars are available.  'normal' can cause this , feedkeys()
		" doesn't.  Therefore, checking for \e\e\e is a workaround.
		if getchar(1) > 0 && s:Drain !~ '\e\e$'
			let s:Drain .= v:getchar
			echomsg "appending Drain=(" . s:Drain . ")"
			let v:getchar = ""
			return
		elseif s:Drain != ''
			let s:Drain_ok = 0

			let s:Drain .= v:getchar
			let v:getchar = ""
			let s:Drain = substitute( s:Drain, '\e\e\e$', '', '' )
			echomsg "feeding Drain=(" . s:Drain . ")"
			" This is safe because 't' flag is checked by KeyTyped, above.
			call feedkeys( s:Drain,  't' )
			let s:Drain = ''
			let s:Drain_ok = 1
			return
		endif
	endif


	" Test discard:
	if v:getchar == '~' && s:last_char == '~'
		let v:getchar = ""
	endif
	" Test replace:
	if v:getchar == '!' && s:last_char == '!'
		let v:getchar = "#"
	endif

	" Test re-entrant, once:
	" Note: case matters when comparing special keys.
	if v:getchar ==# "\<S-TAB>"
		let c = getchar()
		echomsg 'recursive getchar = (' . nr2char( c ) . '), nr=(' . c . ')'
	endif


	" Note: some keys only seem to be delivered in the command line:
	" \<C-CR> \<S-CR> \<S-SPACE>

	" Running into some internal interference with ^Q^Q
	"if ( v:getchar == "\<c-q>" ) && ( s:last_char == "\<c-q>" )
	if ( v:getchar == "\<esc>" ) && ( s:last_char == "\<esc>" )
		if s:verbose
			let s:verbose = 0
			echomsg 'Verbose off'
		else
			let s:verbose = 1
		endif
	endif

	" Possibly useful in yet unknown cases:
	"let v:getchartype = "KeyTyped"
	
	let s:last_char = v:getchar

endfunction



aug Tst
	au!
	au GetChar <buffer> call Tst()
	"au GetChar * call Tst()
aug END


" Note: mixing 't' and 'm', etc. keys causes KeyStuffed and KeyTyped to get
" confused.
"call feedkeys(':echo "macroing"' . "\<CR>", 'm' )
"call feedkeys(':echo "feeding"' . "\<CR>", 't' )
"call feedkeys('ggVG', 't' )

" This gets cleared after 'gg' by some internal process, if re-routed through
" feedkeys() in the s:Drain stuff above.
"normal ggVG


