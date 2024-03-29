#!/bin/env -S nvim -u

if expand("%") == ""
	edit ./
endif

let mapleader = " "

let g:CONFIG_PATH = "$HOME/.config/nvim/"

if $PREFIX == ""
	call setenv('PREFIX', '/usr/')
endif
let g:COLORSCHEME_PATH = "$PREFIX/share/nvim/runtime/colors/blueorange.vim"
set termguicolors
set background=light
exec printf("so %s", g:COLORSCHEME_PATH)
set lazyredraw

set helpheight=10
set splitbelow
set splitkeep=cursor
set nosplitright
set scrolloff=3

set nogdefault
set ignorecase
set smartcase
set incsearch
set magic

set foldclose=all
set foldenable
set foldexpr=0
set foldignore=#
set foldlevel=0
set foldmarker={{{,}}}
set foldmethod=marker
set foldnestmax=15

function! SynGroup()
    let l:s = synID(line('.'), col('.'), 1)
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfunction
function! SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

set nonu
set nornu
function! STCRel()
	if has('nvim')
		let &l:stc = '%#CursorLineNr#%{%v:relnum?"%#LineNr#":((v:virtnum <= 0)?v:lnum:"")%}%=%{v:relnum?((v:virtnum <= 0)?v:relnum:""):""} '
	else
		set nu rnu
	endif
endfunction
function! STCAbs(actual_mode)
	if has('nvim')
		if a:actual_mode ==# ''
			let &l:stc = '%{%v:relnum?"":"%#CursorLineNr#".((v:virtnum <= 0)?v:lnum:"")%}%=%{v:relnum?((v:virtnum <= 0)?v:lnum:""):""} '
			return
		endif
		if a:actual_mode ==# 'r'
			let &l:stc = '%{%v:relnum?"":"%#CursorLineNrRepl#".((v:virtnum <= 0)?v:lnum:"")%}%=%{v:relnum?((v:virtnum <= 0)?v:lnum:""):""} '
			return
		endif
		let &l:stc = '%{%v:relnum?"":"%#CursorLineNrIns#".((v:virtnum <= 0)?v:lnum:"")%}%=%{v:relnum?((v:virtnum <= 0)?v:lnum:""):""} '
	else
		set nu nornu
	endif
endfunction
function! STCNo()
	setlocal stc= nonu nornu
endfunction
let s:stc_shrunk = v:false
function! STCUpd()
	if &columns ># 40
		if has('nvim')
			let &stc = &stc
		endif
		if s:stc_shrunk
			let &stc = s:old_stc
		endif
		let s:stc_shrunk = v:false
	else
		if s:stc_shrunk
			let &stc = ''
		else
			let s:stc_shrunk = v:true
			let s:old_stc = &stc
			let &stc = ''
		endif
	endif
endfunction
call STCUpd()

set showcmd
set showcmdloc=statusline
set laststatus=2

let s:custom_mode = ''
let s:specmode = ''
function! SetStatusLineNc()
	echohl StatusLineNc
endfunction
function! SetGitBranch()
	let s:virtual_gitbranch = split(system('git rev-parse --abbrev-ref HEAD 2> /dev/null'))
	if len(s:virtual_gitbranch) > 0
		let s:gitbranch = s:virtual_gitbranch[0]
	else
		let s:gitbranch = ''
	endif
endfunction
augroup gitbranch
	autocmd!
	autocmd BufEnter,BufLeave * call SetGitBranch()
augroup END
function! GetGitBranch()
	return s:gitbranch
endfunction
function! Showtab()
	let stl_name = '%<%t'
	let stl_name .= '%( %#StatusLinemod#%M%R%H%W%)%*'
	if &columns ># 40
		let stl_name .= '%( %#StatusLinemod#'
		let stl_name .= &syntax
		let stl_name .= '%)%*'
	endif
	if &columns ># 45
		let stl_name .= '%( %#Statuslinemod#'
		let stl_name .= '%{GetGitBranch()}'
		let stl_name .= '%)%*'
	endif
	let mode = mode('lololol')
	let strmode = ''
	if mode == 'n'
		let strmode = '%#ModeNorm#NORM '
	elseif mode == 'no'
		let strmode = 'OP_PEND '
	elseif mode == 'nov'
		let strmode = 'visu OP_PEND '
	elseif mode == 'noV'
		let strmode = 'vis_line OP_PEND '
	elseif mode == 'noCTRL-v'
		let strmode = 'vis_block OP_PEND '
	elseif mode == 'niI'
		let strmode = '^o INS '
	elseif mode == 'niR'
		let strmode = '^o REPL '
	elseif mode == 'niV'
		let strmode = '^o visu REPL '
	elseif mode == 'nt'
		let strmode = '%#ModeNorm#norm%#ModeTerm#TERM'
	elseif mode == 'ntT'
		let strmode = '^\^o norm TERM '
	elseif mode == 'v'
		let strmode = '%#ModeVisu#VISU '
	elseif mode == 'V'
		let strmode = 'VIS_LINE '
	elseif mode == 'vs'
		let strmode = '^o visu SEL '
	elseif mode == 'CTRL-V'
		let strmode = 'VIS_BLOCK '
	elseif mode == 'CTRL-Vs'
		let strmode = '^o vis_block SEL '
	elseif mode == 's'
		let strmode = 'SEL  '
	elseif mode == 'S'
		let strmode = 'SEL LINE '
	elseif mode == 'CTRL-S'
		let strmode = 'SEL BLOCK '
	elseif mode == 'i'
		let strmode = '%#ModeIns#INSE '
	elseif mode == 'ic'
		let strmode = 'compl INS '
	elseif mode == 'ix'
		let strmode = '%#ModeCom#^x compl%#ModeIns#INS'
	elseif mode == 'R'
		let strmode = '%#ModeRepl#REPL '
	elseif mode == 'Rc'
		let strmode = 'compl REPL '
	elseif mode == 'Rx'
		let strmode = '^x compl REPL '
	elseif mode == 'Rv'
		let strmode = '%#ModeIns#visu%*%#ModeRepl#REPL'
	elseif mode == 'Rvc'
		let strmode = 'compl visu REPL '
	elseif mode == 'Rvx'
		let strmode = '^x compl visu REPL '
	elseif mode == 'c'
		if s:specmode == 'b'
			let strmode = 'COM_BLOCK '
		else
			let strmode = '%#ModeCom#COMM '
		endif
	elseif mode == 'cv'
		let strmode = 'EX   '
	elseif mode == 'r'
		let strmode = 'HIT_ENTER '
	elseif mode == 'rm'
		let strmode = 'MORE '
	elseif mode == 'r?'
		let strmode = 'CONFIRM '
	elseif mode == '!'
		let strmode = 'SHELL '
	elseif mode == 't'
		let strmode = '%#ModeTerm#TERM '
	else
		let strmode = '%#ModeVisu#visu%#ModeBlock#BLOCK'
	endif
	"let stl_time = '%{strftime("%b,%d %H:%M:%S")}'
	let stl_pos = '%l:%c %LL'
" 
	let stl_showcmd = '%(%#Statuslinemod#%S%*%)'
	let stl_buf = '#%n %p%%'
	let stl_mode_to_put = ''
	if &columns ># 20
		let stl_mode_to_put .= strmode
		let stl_mode_to_put .= s:custom_mode?' '.s:custom_mode:''
		let stl_mode_to_put .= '%* '
	endif

	let s:result = stl_mode_to_put
	let s:result .= stl_name
	if &columns ># 30
		let &showcmdloc = 'statusline'
		let s:result .= ' '
		let s:result .= stl_showcmd
	else
		let &showcmdloc = 'last'
	endif
	let s:result .= '%='
	if &columns ># 45
		let s:result .= '%#Statuslinestat01#'
		let s:result .= ''
		let s:result .= '%#Statuslinestat1#'
		let s:result .= ' '
	endif
	if &columns ># 30
		let s:result .= stl_pos
		let s:result .= ' '
	endif
	if &columns ># 45
		let s:result .= '%#Statuslinestat12#'
		let s:result .= ''
	endif
	if &columns ># 35
		let s:result .= '%#Statuslinestat2# '
		let s:result .= stl_buf
		let s:result .= ' '
	endif
	return s:result
endfunction
command! Showtab set stl=%{%Showtab()%}
Showtab

command! -nargs=* Git !git <args>
command! -nargs=* Pkg !pkg <args>

" let s:tabtimerid = 0
" function TabTimerHandler(id)
" 	let s:tabtimerid = a:id
" 	Showtab
" endfunction
" function TabTimerStart()
" 	if s:tabtimerid == 0
" 		Showtab
" 		call timer_start(500, 'TabTimerHandler', {'repeat': -1})
" 	endif
" endfunction
" function TabTimerStop()
" 	call timer_stop(s:tabtimerid)
" 	let s:tabtimerid = 0
" endfunction
" call TabTimerStart()
" function Printtabtimerid()
" 	echom "Timer id is: " . s:tabtimerid
" endfunction
" augroup tabtimer
" 	autocmd!
" 	autocmd CmdlineEnter * Showtab
" 	autocmd CmdlineLeave * call TabTimerStart()
" 	autocmd CmdwinEnter * let s:specmode = 'b' | Showtab
" 	autocmd CmdwinLeave * let s:specmode = '' | Showtab
" 	autocmd CursorHold * call TabTimerStop()
" 	autocmd CursorMoved * call TabTimerStart()
" 	autocmd CursorHoldI * call TabTimerStop()
" 	autocmd CursorMovedI * call TabTimerStart()
" 	autocmd InsertEnter * call TabTimerStart()
" 	autocmd InsertLeave * call TabTimerStart()
" augroup END
" 
" "noremap <silent> <esc> <cmd>Showtab<cr>

augroup numbertoggle
	autocmd!
	function Numbertoggle_stcabs()
		if &modifiable
			call STCAbs(v:insertmode)
		else
			call STCNo()
		endif
	endfunction
	function Numbertoggle_stcrel()
		if !s:fullscreen
			if &modifiable
				call STCRel()
			else
				call STCNo()
			endif
		endif
	endfunction
	function Numbertoggle_no()
		set stc= nonu nornu
	endfunction
	autocmd FocusGained,InsertLeave * call Numbertoggle_stcrel()
	autocmd FocusLost,InsertEnter * call Numbertoggle_stcabs()
	" autocmd BufLeave * call Numbertoggle_no()
augroup END

function! BufModifiableHandler()
	if &modifiable
		call STCRel()
	else
		call STCNo()
	endif
endfunction
autocmd BufReadPost,WinLeave,WinEnter * call BufModifiableHandler()
" call timer_start(500, 'BufModifiableHandler', {'repeat': -1})

function! MyTabLabel(n)
	let buflist = tabpagebuflist(a:n)
	let winnr = tabpagewinnr(a:n)
	let original_buf_name = bufname(buflist[winnr - 1])
	if original_buf_name == ''
		let buf_name = '[null]'
	else
		let buf_name = original_buf_name
	endif
	return fnamemodify(buf_name, ':~:.:gs?\([^/]\)[^/]*/?\1/?')
	" call execute("normal :!echo '" . buf_name . "' > ~/.config/nvim/config_garbagefile.txt")
	" redir! > ~/.config/nvim/config_garbagefile.txt
	" 	silent echo buf_name
	" redir END
endfunction
function! MyTabLine()
  let s = ''
  for i in range(tabpagenr('$'))
    if i + 1 == tabpagenr()
      let s ..= '%#TabLineSel#'
    elseif (i - tabpagenr()) % 2 == 0
		let s ..= '%#TabLine#'
	else
		let s ..= '%#TabLineSec#'
    endif

    " set the tab page number (for mouse clicks)
    let s ..= '%' .. (i + 1) .. 'T'

    " the label is made by MyTabLabel()
    let s ..= '%{MyTabLabel(' .. (i + 1) .. ')}'
  endfor

  " after the last tab fill with TabLineFill and reset tab page nr
  let s ..= '%#TabLineFill#%T'

	" let s ..= '%=%#TabLine#%999Xclose'

  return s
endfunction
set tabline=%!MyTabLine()

set hidden
set nowrap
set nolinebreak
let &breakat = "    !¡@*-+;:,./?¿{}[]^%&"
set list
set display=lastline
set fcs=lastline:>
set listchars=tab:>\ ,trail:_,nbsp:+
set shortmess=filmnrxwsWItCF
set showtabline=2
set noshowmode
set noconfirm
set virtualedit=onemore

setlocal nowrap

set matchpairs=(:),{:},[:],<:>
set noshowmatch
set matchtime=2
set maxfuncdepth=50
" set maxmapdepth=2
set maxmempattern=500
set history=10000
set modelineexpr
set updatetime=5000
set timeout
set timeoutlen=500
set nottimeout
set ttimeoutlen=500

set cursorline
set cursorlineopt=screenline,number
set cursorcolumn
set mouse=a
set nomousefocus
set nomousehide
set mousemodel=popup_setpos
set nomousemoveevent
if has('nvim')
	set mousescroll=ver:3,hor:6
endif
set mouseshape=i:beam,r:beam,s:updown,sd:cross,m:no,ml:up-arrow,v:rightup-arrow
set mousetime=400
set startofline

set concealcursor=nc
set conceallevel=0

set tabstop=4
set shiftwidth=4
set smartindent
set smarttab
set noexpandtab

let g:loaded_perl_provider = 0

command! SWrap setl wrap linebreak nolist

if v:version >= 700
  au BufLeave * let b:winview = winsaveview()
  au BufEnter * if(exists('b:winview')) | call winrestview(b:winview) | endif
endif

noremap <silent> dd ddk
noremap <silent> - dd
noremap <silent> + mzyyp`zj

noremap <silent> J mzJ`z
noremap <silent> gJ mzgJ`z

let s:fullscreen = v:false
function! ToggleFullscreen()
	if !s:fullscreen
		let s:fullscreen = v:true
		let s:old_cursorline = &cursorline
		let s:old_cursorcolumn = &cursorcolumn
		let s:old_showtabline = &showtabline
		let s:old_laststatus = &laststatus
		let s:old_showcmdloc = &showcmdloc
		let s:old_showmode = &showmode
		let s:old_ruler = &ruler
		set nocursorline
		set nocursorcolumn
		set showtabline=0
		set laststatus=0
		set showcmdloc=last
		set showmode
		set ruler
		call STCAbs('')
	else
		let s:fullscreen = v:false
		let &cursorline = s:old_cursorline
		let &cursorcolumn = s:old_cursorcolumn
		let &showtabline = s:old_showtabline
		let &laststatus = s:old_laststatus
		let &showcmdloc = s:old_showcmdloc
		let &showmode = s:old_showmode
		let &ruler = s:old_ruler
		call STCRel()
	endif
endfunction
function! ToggleLocalFullscreen()
	echom "ToggleLocalFullscreen: not implemented yet"
endfunction
command! ToggleFullscreen call ToggleFullscreen()
command! ToggleLocalFullscreen call ToggleLocalFullscreen()
noremap <leader><c-f> <cmd>ToggleFullscreen<cr>
noremap <leader>l<c-f> <cmd>ToggleLocalFullscreen<cr>
noremap <c-t> <cmd>TagbarToggle<cr>

nnoremap <leader>g :grep -R <cword> .<cr>

"function! ProcessBut(button)
"	let mode_was = mode()
"	let temp = ''
"
"	let temp .= "\<cmd>set showcmdloc=last\<cr>"
"
"	let temp .= a:button
"
"	let temp .= "\<Esc>\<cmd>set showcmdloc=statusline\<cr>"
"
"	if mode_was == 'v' || mode_was == 'V' || mode_was == 'CTRL-V'
"		let temp .= "gv"
"	endif
"
"	return temp
"endfunction
function! ProcessGBut(button)
	let temp = ''
	if v:count == 0
		let temp .= 'g' . a:button
	else
		let temp .= "\<Esc>" . v:count . a:button
	endif
	call STCUpd()
	return temp
endfunction

noremap <silent> <expr> j ProcessGBut('j')
noremap <silent> <expr> k ProcessGBut('k')
noremap <silent> <expr> <down> ProcessGBut('j')
noremap <silent> <expr> <up> ProcessGBut('k')
inoremap <silent> <down> <cmd>call STCUpd()<cr><down>
inoremap <silent> <up> <cmd>call STCUpd()<cr><up>
noremap <silent> <leader>j j:let &stc=&stc<cr>
noremap <silent> <leader>k k:let &stc=&stc<cr>
noremap <silent> <leader><up> k:let &stc=&stc<cr>
noremap <silent> <leader><down> j:let &stc=&stc<cr>
" noremap <silent> 0 g0
" noremap <silent> $ g$
" noremap <silent> I g0i
" noremap <silent> A g$a

noremap <silent> <c-s> <c-a>
noremap <silent> <c-a> <cmd>normal g0<cr>
noremap <silent> <c-e> <cmd>normal $<cr>
inoremap <silent> <c-a> <c-o>_
inoremap <silent> <c-e> <c-o>$

cnoremap <silent> <c-a> <c-b>
cnoremap <c-g> <c-e><c-u><cr>
cnoremap <silent> jk <c-e><c-u><cr>
cnoremap <c-u> <c-e><c-u>
cnoremap <c-a> <c-b>
cnoremap <c-b> <S-left>
"noremap jk <cmd>echo 'Not in Insert Mode'<cr>

nnoremap <c-j> viwUe<space><esc>
vnoremap <c-j> iwUe<space>
inoremap <c-j> <esc>viwUe<esc>a

nnoremap <bs> X
noremap <leader><bs> <bs>

function! Findfile()
	echohl Question
	let filename = input('find file: ')
	echohl Normal
	if filename !=# ''
		exec printf("tabedit %s", filename)
	endif
endfunction
command! Findfile call Findfile()
noremap <c-c>c <cmd>Findfile<cr>
function! Findfilebuffer()
	echohl Question
	let filename = input('find file (in buffer): ')
	echohl Normal
	if filename !=# ''
		exec printf("edit %s", filename)
	endif
endfunction
command! Findfilebuffer call Findfilebuffer()
noremap <c-c>C <cmd>Findfilebuffer<cr>
"nnoremap <leader>lC :tabnew<Bar>ter<Bar><cr>a./build.sh
"nnoremap <leader>lc :tabnext<Bar><c-\><c-n>:bd!<Bar>tabnew<Bar>ter<cr>a!!<cr>

nnoremap <silent> * *:noh<cr>
nnoremap <silent> <c-*> *
nnoremap <silent> # #:noh<cr>
nnoremap <silent> <c-#> #

noremap <c-l> 20zl
noremap <c-h> 20zh
inoremap <c-l> <esc>20zla
inoremap <c-h> <esc>20zha
let s:SCROLL_UP_FACTOR = 2
let s:SCROLL_DOWN_FACTOR = 2
let s:SCROLL_C_E_FACTOR = s:SCROLL_UP_FACTOR
let s:SCROLL_C_Y_FACTOR = s:SCROLL_DOWN_FACTOR
let s:SCROLL_MOUSE_UP_FACTOR = s:SCROLL_UP_FACTOR
let s:SCROLL_MOUSE_DOWN_FACTOR = s:SCROLL_DOWN_FACTOR
exec printf("noremap <silent> <expr> <c-Y> \"%s<c-e>\"", s:SCROLL_C_E_FACTOR)
exec printf("noremap <silent> <expr> <c-y> \"%s<c-y>\"", s:SCROLL_C_Y_FACTOR)
exec printf("noremap <silent> <expr> <ScrollWheelDown> \"%s<c-e>\"", s:SCROLL_MOUSE_DOWN_FACTOR)
exec printf("noremap <silent> <expr> <ScrollWheelUp> \"%s<c-y>\"", s:SCROLL_MOUSE_UP_FACTOR)

" NVIMRC FILE
let s:INIT_FILE_PATH = '~/.config/nvim/init.vim'
let s:PLUGINS_INSTALL_FILE_PATH = '~/.config/nvim/lua/packages/plugins.lua'
let s:PLUGINS_SETUP_FILE_PATH = '~/.config/nvim/lua/packages/plugins_setup.lua'
let s:LSP_PLUGINS_SETUP_FILE_PATH = '~/.config/nvim/lua/packages/lsp/plugins.lua'

exec printf("noremap <silent> <leader>vet <esc>:tabe %s<cr>", s:INIT_FILE_PATH)
exec printf("noremap <silent> <leader>veb <esc>:e %s<cr>", s:INIT_FILE_PATH)
exec printf("noremap <silent> <leader>veh <esc>:sp %s<cr>", s:INIT_FILE_PATH)
exec printf("noremap <silent> <leader>vev <esc>:vsp %s<cr>", s:INIT_FILE_PATH)
exec printf("noremap <silent> <leader>ves <esc>:so %s<cr>", s:INIT_FILE_PATH)

exec printf("noremap <silent> <leader>vit <esc>:tabe %s<cr>", s:PLUGINS_INSTALL_FILE_PATH)
exec printf("noremap <silent> <leader>vib <esc>:e %s<cr>", s:PLUGINS_INSTALL_FILE_PATH)
exec printf("noremap <silent> <leader>vih <esc>:sp %s<cr>", s:PLUGINS_INSTALL_FILE_PATH)
exec printf("noremap <silent> <leader>viv <esc>:vsp %s<cr>", s:PLUGINS_INSTALL_FILE_PATH)
exec printf("noremap <silent> <leader>vis <esc>:so %s<cr>", s:PLUGINS_INSTALL_FILE_PATH)

exec printf("noremap <silent> <leader>vst <esc>:tabe %s<cr>", s:PLUGINS_SETUP_FILE_PATH)
exec printf("noremap <silent> <leader>vsb <esc>:e %s<cr>", s:PLUGINS_SETUP_FILE_PATH)
exec printf("noremap <silent> <leader>vsh <esc>:sp %s<cr>", s:PLUGINS_SETUP_FILE_PATH)
exec printf("noremap <silent> <leader>vsv <esc>:vsp %s<cr>", s:PLUGINS_SETUP_FILE_PATH)
exec printf("noremap <silent> <leader>vss <esc>:so %s<cr>", s:PLUGINS_SETUP_FILE_PATH)

exec printf("noremap <silent> <leader>vlt <esc>:tabe %s<cr>", s:LSP_PLUGINS_SETUP_FILE_PATH)
exec printf("noremap <silent> <leader>vlb <esc>:e %s<cr>", s:LSP_PLUGINS_SETUP_FILE_PATH)
exec printf("noremap <silent> <leader>vlh <esc>:sp %s<cr>", s:LSP_PLUGINS_SETUP_FILE_PATH)
exec printf("noremap <silent> <leader>vlv <esc>:vsp %s<cr>", s:LSP_PLUGINS_SETUP_FILE_PATH)
exec printf("noremap <silent> <leader>vls <esc>:so %s<cr>", s:LSP_PLUGINS_SETUP_FILE_PATH)

" BASHRC FILE
noremap <silent> <leader>bt <esc>:tabe ~/.bashrc<cr>
noremap <silent> <leader>bb <esc>:e ~/.bashrc<cr>
noremap <silent> <leader>bh <esc>:sp ~/.bashrc<cr>
noremap <silent> <leader>bv <esc>:vsp ~/.bashrc<cr>

autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" MY .nvimrc HELP
noremap <silent> <leader>? <esc>:echo "
  \MY .nvimrc HELP:
\\n  GLOBAL HELP:
\\n    \<leader\>? - Show this help message
\\n  NVIMRC FILE:
\\n    \<leader\>vet - Open in a new tab
\\n    \<leader\>veb - Open in a new buffer
\\n    \<leader\>veh - Open in a new horizontal window (-)
\\n    \<leader\>vev - Open in a new vertical window (\|)
\\n    \<leader\>vs  - Source it
\\n  BASHRC FILE:
\\n    \<leader\>bt - Open in a new tab
\\n    \<leader\>bb - Open in a new buffer
\\n    \<leader\>bh - Open in a new horizontal window (-)
\\n    \<leader\>bv - Open in a new vertical window (\|)
\\n  EDITING:
\\n    MOVING:
\\n      You can press `l`, `h`, `right` and `left` at the end of the line and it will go to the beginning of the next line (in Normal mode).
\\n      To disable this feature, run this command in bash:
\\n      ╭──────────────────────────╮
\\n      │ $ disable_autowrapping=1 │
\\n      ╰──────────────────────────╯
\\n    SPECIAL:
\\n      ; - Switch to command mode (:)
\\n      SPC SPC - Open quickui menu
\\n      INSERT: jk - Exit from Insert Mode
\\n      INSERT: ju - Make current word uppercase
\\n      CTRL-a - Move to start of line
\\n      CTRL-e - Move to end of line
\\n      CTRL-h - 20zh
\\n      CTRL-l - 20zl
\\n      CTRL-a - Increase number
\\n      CTRL-x - Deecrease number
\\n      ci_ - Edit word from start to first _
\\n      \<leader\>d  - Remove search highlightings
\\n      s - Delete (d) without copying
\\n      q - Quit window
\\n      Q - Quit without saving
\\n      CTRL-c - Find file
\\n      CTRL-C - Find file in buffer
\\n      \<leader\>S - Toggle scrolloff (see :h 'scrolloff')
\\n    Like in Emacs:
\\n      ALT-x - Switch to command mode (:)
\\n      F10 - Open quickui menu
\\n      CTRL-x CTRL-c - Close All windows
\\n      CTRL-x s - Save current buffer
\\n      CTRL-x CTRL-s - See CTRL-x s
\\n      CTRL-x k - Kill current buffer
\\n      CTRL-x 0 - Close current window
\\n      CTRL-x 1 - Close all but current window
\\n      CTRL-x 2 - Split window
\\n      CTRL-x 3 - Vertically split window
\\n      CTRL-x o - Next tab
\\n      CTRL-x O - Previous tab
\\n      CTRL-x CTRL-f - See CTRL-c c
\\n      CTRL-x t 0 - Close current tab
\\n      CTRL-x t 1 - Close all but current tab
\\n      CTRL-x t 2 - New tab
\\n      CTRL-x t o - Next tab
\\n      CTRL-x t O - Previous tab
\\n      CTRL-x h - Select all text
\\n      CTRL-x CTRL-h - See help (:h)
\\n    QUOTES AROUND:
\\n      \<leader\>\" - Put \'\"\' around word
\\n      \<leader\>\' - Put \"\'\" around word
\\n  TERMINAL:
\\n    \<leader\>tt - Open in a new tab
\\n    \<leader\>tb - Open in a new buffer
\\n    \<leader\>th - Open in a new horizontal window (-)
\\n    \<leader\>tv - Open in a new vertical window (\|)
\\n  COLORSCHEME:
\\n    \<leader\>cet - Open colorschemes in a new tab
\\n    \<leader\>ceb - Open colorschemes in a new buffer
\\n    \<leader\>ceh - Open colorschemes in a new horizontal window (-)
\\n    \<leader\>cev - Open colorschemes in a new vertical window (\|)
\\n    \<leader\>cs  - Set colorscheme (:colo)
\\n    \<leader\>cy  - Copy colorscheme name from current buffer and set it
\\n  TELESCOPE (Plugin):
\\n    \<leader\>ff - Find files
\\n    \<leader\>fg - Live grep
\\n    \<leader\>fb - Buffers
\\n    \<leader\>fh - Help tags
\\n  LSP:
\\n    \<leader\>slv - Start vim-language-server
\\n    \<leader\>slb - Start bash-language-server
\\n    \<leader\>sld - Dump active clients
\\n  SPECIAL:
\\n     By default, \<leader\> is space symbol. You can change it typing this command in Vim/Neovim:
\\n     ╭───────────────────────────╮
\\n     │ :let mapleader = \"symbol\" │
\\n     ╰───────────────────────────╯
\\n     Where symbol is your symbol (type quotes literally)
\\n  AUTHOR:
\\n    Name: TwoSpikes (2023 - 2023)
\\n    Github: https://github.com/TwoSpikes/dotfiles.git
\"<cr>

" FAST COMMANDS
noremap ; :
noremap <silent> <leader>; ;
noremap <silent> <leader>: :<c-f>a
"noremap <leader>= :tabe 
"noremap <leader>- :e 
noremap <leader>= <cmd>echo "use \<c-c\>c"<cr>
noremap <leader>- <cmd>echo "use \<c-c\>C"<cr>
noremap <leader>1 :!

" QUOTES AROUND
nnoremap <leader>" viw<esc>a"<esc>bi"<esc>
nnoremap <leader>' viw<esc>a'<esc>bi'<esc>
vnoremap <leader>" iw<esc>a"<esc>bi"<esc>v
vnoremap <leader>' iw<esc>a'<esc>bi'<esc>v

" SPECIAL
nnoremap ci_ yiwct_
noremap <silent> <leader>d <esc>:noh<cr>
tnoremap <c-]> <c-\><esc>

" TERMINAL
function OpenTerm()
	terminal
	setlocal statuscolumn=
	setlocal nonu nornu
	startinsert
endfunction
noremap <silent> <leader>tt <cmd>tabnew<cr><cmd>call OpenTerm()<cr>
noremap <silent> <leader>tb <cmd>call OpenTerm()<cr>
noremap <silent> <leader>th <cmd>split<cr><cmd>call OpenTerm()<cr>
noremap <silent> <leader>tv <cmd>vsplit<cr><cmd>call OpenTerm()<cr>
" noremap <silent> <leader>tct <c-\><c-n>:q\|tabnew\|ter<cr>a

" COLORSCHEME
noremap <silent> <leader>cet :tabe $VIMRUNTIME/colors/<cr>
noremap <silent> <leader>ceb :e $VIMRUNTIME/colors/<cr>
noremap <silent> <leader>ceh :split $VIMRUNTIME/colors/<cr>
noremap <silent> <leader>cev :vsplit $VIMRUNTIME/colors/<cr>
noremap <silent> <leader>cs :colo 
noremap <silent> <leader>cy yiw:colo <c-r>"<cr>j

augroup cpp
	au!
	au filetype cpp noremap <silent> <buffer> <leader>ln viwo<esc>i::<esc>hi
	au filetype cpp noremap <silent> <buffer> <leader>l/d mz0i//<esc>`zll
	au filetype cpp noremap <silent> <buffer> <leader>l/u mz:s:^//<cr>`zhh:noh<cr>
	au filetype cpp noremap <silent> <buffer> <leader>l! :e ~/.config/tsvimconf/cpp/example.cpp<cr>ggvGy:bd<cr>pgg
augroup END
augroup vim
	au!
	au filetype vim noremap <silent> <buffer> <leader>l/d mz0i"<esc>`zl
	au filetype vim noremap <silent> <buffer> <leader>l/u mz:s/^"<cr>`zh:noh<cr>
augroup END
augroup googol
	au!
	au syntax googol noremap <silent> <buffer> <leader>l/d mz0i//<esc>`zll
	au syntax googol noremap <silent> <buffer> <leader>l/u mz:s:^//<cr>`zhh:noh<cr>
augroup END
augroup php
	au!
	au filetype php nnoremap <silent> <buffer> <leader>lg viwoviGLOBALS['<esc>ea']<esc>
augroup END
augroup bash
	au!
	au filetype bash,sh setlocal nowrap linebreak
augroup END
augroup python
	au!
	au filetype python nnoremap <silent> <buffer> <leader>l/d mz0i#<esc>`zl
	au filetype python nnoremap <silent> <buffer> <leader>l/u mz:s/^#<cr>`zh:noh<cr>
augroup END
augroup netrw
	au!
	au filetype netrw setlocal nocursorcolumn
augroup END
augroup terminal
	au!
	au termopen * setlocal nocursorline nocursorcolumn
augroup END
augroup visual
	function! HandleBuftype()
		let &cursorcolumn = mode() !~# "[vVirco]" && !s:fullscreen && &filetype !=# 'netrw' && &buftype !=# 'terminal'
		let &cursorline = mode() !~# "[irco]" && !s:fullscreen && &buftype !=# 'terminal'
	endfunction
	au ModeChanged,BufWinEnter * call HandleBuftype()
augroup END

" TELESCOPE
nnoremap <silent> <leader>ff :lua require'telescope.builtin'.find_files(require('telescope.themes').get_dropdown({winblend = 0 }))<cr>
nnoremap <silent> <leader>fg :lua require'telescope.builtin'.live_grep(require('telescope.themes').get_dropdown({winblend = 0 }))<cr>
nnoremap <silent> <leader>fb :lua require'telescope.builtin'.buffers(require('telescope.themes').get_dropdown({winblend = 0 }))<cr>
nnoremap <silent> <leader>fh :lua require'telescope.builtin'.help_tags(require('telescope.themes').get_dropdown({winblend = 0 }))<cr>

" vnoremap <c-/> <esc>v:q:s/.*/# \0
" vnoremap <c-?> <esc>:s/.*/\/\/ \0

function! IsYes(string)
	return a:string ==# 'y' || a:string ==# 'Y' || a:string ==# 'yes' || a:string ==# 'Yes' || a:string ==# 'YES'
endfunction
function! IsNo(string)
	return a:string ==# 'n' || a:string ==# 'N' || a:string ==# 'no' || a:string ==# 'No' || a:string ==# 'NO'
endfunction

" Tab closers
noremap <silent> q <cmd>q<cr>
noremap <silent> Q <cmd>q!<cr>
noremap <c-w><c-g> <cmd>echo "Quit"<cr>

" Emacs support
noremap <silent> <c-x><c-c> <cmd>qa<cr>
noremap <silent> <c-x>s <cmd>w<cr>
noremap <silent> <c-x><c-s> <cmd>w<cr>
function! Killbuffer()
	echohl Question
	let user_input = input("do you wanna kill the buffer (Y/n): ")
	echohl Normal
	if user_input ==# '' || IsYes(user_input)
		bdelete
	elseif !IsNo(user_input)
		echohl ErrorMsg
		echo " "
		echo "please answer "
		echohl Title
		echon "yes"
		echohl ErrorMsg
		echon " or "
		echohl Title
		echon "no"
		echohl ErrorMsg
		echon " or leave blank empty"
		echohl Normal
	endif
endfunction
command! Killbuffer call Killbuffer()
noremap <silent> <c-x>k <cmd>Killbuffer<cr>
noremap <silent> <c-x>0 <cmd>q<cr>
noremap <silent> <c-x>1 <cmd>only<cr>
noremap <silent> <c-x>2 <cmd>split<cr>
noremap <silent> <c-x>3 <cmd>vsplit<cr>
noremap <silent> <c-x>o <c-w>w
noremap <silent> <c-x>O <c-w>W
noremap <silent> <c-x><c-f> <cmd>Findfilebuffer<cr>
noremap <silent> <c-x>t0 <cmd>tabclose<cr>
noremap <silent> <c-x>t1 <cmd>tabonly<cr>
noremap <silent> <c-x>t2 <cmd>tabnew<cr>
noremap <silent> <c-x>to <cmd>tabnext<cr>
noremap <silent> <c-x>tO <cmd>tabprevious<cr>
noremap <silent> <c-x>5 <cmd>echo "Frames are only in Emacs/GNU Emacs"<cr>
noremap <m-x> :
noremap <silent> <c-x>h ggVG
noremap <silent> <c-x><c-h> <cmd>h<cr>
noremap <silent> <c-x><c-g> <cmd>echo "Quit"<cr>

noremap mz <cmd>echohl ErrorMsg<cr><cmd>echom "mz is used for commands"<cr><cmd>echohl Normal<cr>

noremap <leader>q q
noremap <leader>Q Q

inoremap <silent> jk <esc>:w<cr>
inoremap <silent> jK <esc>
inoremap <silent> JK <esc>:w<cr>
inoremap <silent> Jk <esc>
tnoremap <silent> jk <c-\><c-n>
tnoremap <silent> jK <c-\><c-n>:bd!<Bar>tabnew<Bar>call OpenTerm()<cr>
command! W w

inoremap <silent> ju <esc>viwUea
inoremap <silent> ji <esc>viwUea

inoremap ( ()<c-o>h
inoremap [ []<c-o>h
inoremap { {}<c-o>h
function! HandleKeystroke(keystroke)
	if a:keystroke ==# "\\\<bs>"
		if getline('.')[col('.')-2] ==# '('
		\&& getline('.')[col('.')-1] ==# ')'
		\|| getline('.')[col('.')-2] ==# '{'
		\&& getline('.')[col('.')-1] ==# '}'
		\|| getline('.')[col('.')-2] ==# '['
		\&& getline('.')[col('.')-1] ==# ']'
		\|| getline('.')[col('.')-2] ==# "'"
		\&& getline('.')[col('.')-1] ==# "'"
		\|| getline('.')[col('.')-2] ==# '"'
		\&& getline('.')[col('.')-1] ==# '"'
		\|| getline('.')[col('.')-2] ==# '<'
		\&& getline('.')[col('.')-1] ==# '>'
			return "\<del>\<bs>"
		else
			return "\<bs>"
		endif
	endif
	if a:keystroke ==# ')'
	\&& getline('.')[col('.')-1] ==# ')'
	\|| a:keystroke ==# ']'
	\&& getline('.')[col('.')-1] ==# ']'
	\|| a:keystroke ==# '}'
	\&& getline('.')[col('.')-1] ==# '}'
	\|| a:keystroke ==# "'"
	\&& getline('.')[col('.')-1] ==# "'"
	\|| a:keystroke ==# '"'
	\&& getline('.')[col('.')-1] ==# '"'
		return "\<right>"
	else
		if a:keystroke ==# '"'
		\|| a:keystroke ==# "'"
			return a:keystroke.a:keystroke."\<left>"
		endif
		return a:keystroke
	endif
endfunction
inoremap <expr> ) HandleKeystroke(')')
inoremap <expr> ] HandleKeystroke(']')
inoremap <expr> } HandleKeystroke('}')
inoremap <expr> ' HandleKeystroke("'")
inoremap <expr> " HandleKeystroke('"')
inoremap <expr> <bs> HandleKeystroke('\<bs>')

if has('nvim')
	exec printf("luafile %s", s:PLUGINS_INSTALL_FILE_PATH)
	PackerInstall
	exec printf("luafile %s", s:PLUGINS_SETUP_FILE_PATH)
endif

so ~/xterm-color-table.vim

if has('nvim')
	lua M = {}
	lua servers = { gopls = {}, html = {}, jsonls = {}, pyright = {}, rust_analyzer = {}, sumneko_lua = {}, tsserver = {}, vimls = {}, }
	lua on_attach = function(client, bufnr) vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc") vim.api.nvim_buf_set_option(0, "formatexpr", "v:lua.vim.lsp.formatexpr()") require("config.lsp.keymaps").setup(client, bufnr) end
	lua opts = { on_attach = on_attach, flags = { debounce_text_changes = 150, }, }
	lua setup = function() require("config.lsp.installer").setup(servers, opts) end
endif

if has('nvim')
	lua table_dump = function(table)
	\   if type(table) == 'table' then
	\      local s = '{ '
	\      for k,v in pairs(table) do
	\         if type(k) ~= 'number' then k = '"'..k..'"' end
	\         s = s .. '['..k..'] = ' .. table_dump(v) .. ','
	\      end
	\      return s .. '} '
	\   else
	\      return tostring(table)
	\   end
	\ end
endif

noremap <silent> <leader>S :let &scrolloff = 999 - &scrolloff<cr>

nnoremap s "_d

noremap <silent> <f10> <cmd>call quickui#menu#open()<cr>

" Interface
function! ChangeVisual()
	echo "Visual changed to "
	echohl Visual
	echon "blue"
	echohl Normal
	hi Visual ctermfg=NONE ctermbg=18 cterm=NONE guifg=NONE guibg=#000087 gui=NONE
endfunction
command! ChangeVisual call ChangeVisual()
function! DeChangeVisual()
	echo "Visual changed to reversed "
	hi Visual ctermfg=NONE ctermbg=NONE cterm=reverse guifg=NONE guibg=NONE gui=reverse
endfunction
command! DeChangeVisual call DeChangeVisual()
noremap <leader>iv ChangeVisual
noremap <leader>iV DeChangeVisual

function! SwapHiGroup(group)
    let id = synIDtrans(hlID(a:group))
    for mode in ['cterm', 'gui']
        for g in ['fg', 'bg']
            exe 'let '. mode.g. "=  synIDattr(id, '".
                        \ g."#', '". mode. "')"
            exe "let ". mode.g. " = empty(". mode.g. ") ? 'NONE' : ". mode.g
        endfor
    endfor
    exec printf('hi %s ctermfg=%s ctermbg=%s guifg=%s guibg=%s', a:group, ctermbg, ctermfg, guibg, guifg)
endfunction

au VimResized * call OnResized()
function! OnResized()
	echom "Window: ".&lines."rows, ".&columns."cols"
	call STCUpd()
endfunction

au! VimEnter * echo 'type ' | echohl SpecialKey | echon ':intro<cr>' | echohl Normal | echon ' to see help'
