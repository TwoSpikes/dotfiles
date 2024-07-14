nnoremap gh 0
xnoremap gh 0
nnoremap gl $mz`z
xnoremap gl $mz`z
nnoremap $ $mz`z
xnoremap $ $mz`z
nnoremap ge G
xnoremap ge G
nnoremap gs ^
xnoremap gs ^

function! ExitVisual()
	if v:false
	elseif g:visual_mode ==# "char"
		normal! v
	elseif g:visual_mode ==# "line"
		normal! V
	elseif g:visual_mode ==# "block"
		normal! <c-v>
	else
		echomsg "dotfiles: hcm: ExitVisual: Internal error: Wrong visual mode: ".g:visual_mode
	endif
endfunction

set notildeop
let &whichwrap="b,s,h,l,<,>,~,[,]"
set virtualedit=onemore

nnoremap d x
function! N_DoX()
	let result = ""
	let result .= "v"
	let result .= "0o$"
	let g:pseudo_visual=v:true
	let g:visual_mode="char"
	return result
endfunction
nnoremap <expr> x N_DoX()
nnoremap <expr> X N_DoX()
xnoremap u <esc>u
xnoremap U <esc><c-r>
function ChangeVisModeBasedOnSelectedText()
	let g:lx = line('.')
	let g:ly = col('.')
	normal! o
	let g:rx = line('.')
	let g:ry = col('.')
	normal! o
	call ReorderRightLeft()
	execute "normal! ".MoveLeft()
	normal! o
	if v:false
	\|| g:ly !=# 1
	\|| g:ry <# strlen(getline(g:rx))
	else
		echomsg "YES"
		if mode() !~# 'V'
			call feedkeys("V")
		endif
	endif
endfunction
function! SimulateCorrectPasteMode(cmd)
	if v:false
	elseif v:false
	\|| g:yank_mode ==# 'char'
		if v:false
		elseif a:cmd ==# '$'
			let paste_cmd = 'p'
		elseif a:cmd ==# '0'
			let paste_cmd = 'P'
		else
			echohl ErrorMsg
			echomsg "dotfiles: SimulateCorrectPasteMode: Internal error: wrong a:cmd: ".a:cmd
			echohl Normal
		endif
	elseif g:yank_mode ==# "line"
		execute "normal! ".a:cmd
		if v:false
		elseif a:cmd ==# '$'
			let paste_cmd = 'p'
		elseif a:cmd ==# '0'
			let paste_cmd = 'P'
		else
			echohl ErrorMsg
			echomsg "dotfiles: SimulateCorrectPasteMode: Internal error: wrong a:cmd: ".a:cmd
			echohl Normal
		endif
	elseif g:yank_mode ==# "line_post"
		if v:false
		elseif a:cmd ==# '$'
			execute "normal! j0"
			let paste_cmd = 'P'
		elseif a:cmd ==# '0'
			execute "normal! k$"
			let paste_cmd = 'p'
		else
			echohl ErrorMsg
			echomsg "dotfiles: SimulateCorrectPasteMode: Internal error: wrong a:cmd: ".a:cmd
			echohl Normal
		endif
	else
		echohl ErrorMsg
		echomsg "dotfiles: SimulateCorrectPasteMode: Internal error: wrong yank mode: ".g:yank_mode
		echohl Normal
	endif

	execute "normal! ".paste_cmd
endfunction
nnoremap p <cmd>call SimulateCorrectPasteMode('$')<cr>`[v<cmd>let g:visual_mode="char"<cr>`]<cmd>call ChangeVisModeBasedOnSelectedText()<cr>
nnoremap P <cmd>call SimulateCorrectPasteMode('0')<cr>`[v<cmd>let g:visual_mode="char"<cr>`]<cmd>call ChangeVisModeBasedOnSelectedText()<cr>
xnoremap p <esc><cmd>call SimulateCorrectPasteMode('$')<cr>`[v<cmd>let g:visual_mode="char"<cr>`]<cmd>call ChangeVisModeBasedOnSelectedText()<cr>
xnoremap P <esc><cmd>call SimulateCorrectPasteMode('0')<cr>`[v<cmd>let g:visual_mode="char"<cr>`]<cmd>call ChangeVisModeBasedOnSelectedText()<cr>
nnoremap gp <cmd>call SimulateCorrectPasteMode('$')<cr>`[v<cmd>let g:visual_mode="char"<cr>`]<cmd>call ChangeVisModeBasedOnSelectedText()<cr>o
nnoremap gP <cmd>call SimulateCorrectPasteMode('0')<cr>`[v<cmd>let g:visual_mode="char"<cr>`]<cmd>call ChangeVisModeBasedOnSelectedText()<cr>o
xnoremap gp <esc><cmd>call SimulateCorrectPasteMode('$')<cr>`[v<cmd>let g:visual_mode="char"<cr>`]<cmd>call ChangeVisModeBasedOnSelectedText()<cr>o
xnoremap gP <esc><cmd>call SimulateCorrectPasteMode('0')<cr>`[v<cmd>let g:visual_mode="char"<cr>`]<cmd>call ChangeVisModeBasedOnSelectedText()<cr>o
nnoremap c xi
if !g:use_nvim_cmp
	if has('nvim')
		unmap ySS
		unmap ySs
		unmap yss
		unmap yS
		unmap ys
		unmap y<c-g>
	endif
endif
nnoremap y vy
nnoremap t<cr> v$
nnoremap mm %
xnoremap mm %
nnoremap <c-c> <cmd>call CommentOutDefault<cr>
inoremap <c-x> <c-p>
inoremap <c-p> <c-x>
nnoremap <a-o> viw
nnoremap <a-.> ;
xnoremap R "_dP
nnoremap ~ v~
nnoremap > >>
nnoremap < <<
xnoremap < <gv<cmd>let g:pseudo_visual=v:true<cr>
xnoremap > >gv<cmd>let g:pseudo_visual=v:true<cr>
xnoremap t<cr> $
if !g:use_nvim_cmp
	if has('nvim')
		unmap cS
		unmap cs
	endif
	unmap ci_
endif
unmap dd
if has('nvim')
	unmap ds
endif
let g:pseudo_visual = v:false
let g:lx=1
let g:ly=1
let g:rx=1
let g:ry=1
let g:visual_mode = "no"
function! ReorderRightLeft()
	if g:lx>#g:rx||(g:lx==#g:rx&&g:ly>g:ry)
		let g:lx=xor(g:rx,g:lx)
		let g:rx=xor(g:lx,g:rx)
		let g:lx=xor(g:rx,g:lx)
		let g:ly=xor(g:ry,g:ly)
		let g:ry=xor(g:ly,g:ry)
		let g:ly=xor(g:ry,g:ly)
	endif
endfunction
function! SavePosition()
	let c=col('.')
	let l=line('.')
	if c==#g:ly&&l==#g:lx
		let g:lx=l
		let g:ly=c
	else
		let g:rx=l
		let g:ry=c
	endif
endfunction
xnoremap <expr> : g:pseudo_visual?":\<c-u>":":"
nnoremap w <cmd>let g:lx=line('.')<bar>let g:ly=col('.')<bar>execute "normal! v".v:count1."e"<bar>let g:rx=line('.')<bar>let g:ry=col('.')<cr><cmd>let g:pseudo_visual = v:true<cr><cmd>let g:visual_mode="char"<cr><cmd>call ReorderRightLeft()<cr>
nnoremap e <cmd>let g:lx=line('.')<bar>let g:ly=col('.')<bar>execute "normal! v".v:count1."e"<bar>let g:rx=line('.')<bar>let g:ry=col('.')<cr><cmd>let g:pseudo_visual = v:true<cr><cmd>let g:visual_mode="char"<cr><cmd>call ReorderRightLeft()<cr>
nnoremap b <cmd>let g:rx=line('.')<bar>let g:ry=col('.')<bar>execute "normal! v".v:count1."b"<bar>let g:lx=line('.')<bar>let g:ly=col('.')<cr><cmd>let g:pseudo_visual = v:true<cr><cmd>let g:visual_mode="char"<cr><cmd>call ReorderRightLeft()<cr>
nnoremap W <cmd>let g:lx=line('.')<bar>let g:ly=col('.')<bar>execute "normal! v".v:count1."W"<bar>let g:rx=line('.')<bar>let g:ry=col('.')<cr><cmd>let g:pseudo_visual = v:true<cr><cmd>let g:visual_mode="char"<cr><cmd>call ReorderRightLeft()<cr>
nnoremap E <cmd>let g:lx=line('.')<bar>let g:ly=col('.')<bar>execute "normal! v".v:count1."E"<bar>let g:rx=line('.')<bar>let g:ry=col('.')<cr><cmd>let g:pseudo_visual = v:true<cr><cmd>let g:visual_mode="char"<cr><cmd>call ReorderRightLeft()<cr>
nnoremap B <cmd>let g:rx=line('.')<bar>let g:ry=col('.')<bar>execute "normal! v".v:count1."B"<bar>let g:lx=line('.')<bar>let g:ly=col('.')<cr><cmd>let g:pseudo_visual = v:true<cr><cmd>let g:visual_mode="char"<cr><cmd>call ReorderRightLeft()<cr>
unmap <esc>
function! N_DoV()
	let g:pseudo_visual=v:false
	let g:rx=line('.')
	let g:ry=col('.')
	let g:lx=g:rx
	let g:ly=g:ry
	let g:visual_mode="char"
endfunction
nnoremap v v<cmd>call N_DoV()<cr>
function! N_DoVLine()
	let result = ""
	let result .= "v"
	let result .= "0o$"
	let g:pseudo_visual=v:false
	let g:visual_mode="char"
	return result
endfunction
nnoremap <expr> V N_DoVLine()
nnoremap <c-v> <c-v><cmd>let g:pseudo_visual=v:false<cr><cmd>let g:rx=line('.')<bar>let g:ry=col('.')<bar>let g:lx=rx<bar>let g:ly=ry<cr><cmd>let g:visual_mode="block"<cr>
function! V_DoV()
	if v:false
	elseif g:visual_mode ==# "no"
		echohl ErrorMsg
		echomsg "dotfiles: hcm: V_DoV: Internal error: It is not visual mode"
		echohl Normal
	elseif v:false
	\|| g:visual_mode ==# "char"
	\|| g:visual_mode ==# "line"
	\|| g:visual_mode ==# "block"
		let g:pseudo_visual = g:pseudo_visual?v:false:v:true
		Showtab
		return ""
	else
		echohl ErrorMsg
		echomsg "dotfiles: hcm: V_DoV: Internal error: Wrong visual mode: ".g:visual_mode
		echohl Normal
	endif
endfunction
xnoremap <expr> v V_DoV()
function! V_DoVLine()
	if v:false
	elseif g:visual_mode ==# "no"
		echohl ErrorMsg
		echomsg "dotfiles: hcm: V_DoVLine: Internal error: It is not visual mode"
		echohl Normal
	elseif v:false
	\|| g:visual_mode ==# "char"
	\|| g:visual_mode ==# "line"
	\|| g:visual_mode ==# "block"
		let g:pseudo_visual = g:pseudo_visual?v:false:v:true
		Showtab
	else
		echohl ErrorMsg
		echomsg "dotfiles: hcm: V_DoVLine: Internal error: Wrong visual mode: ".g:visual_mode
		echohl Normal
	endif
endfunction
xnoremap V <cmd>call V_DoVLine()<cr>
function! V_DoVBlock()
	if v:false
	elseif g:visual_mode ==# "no"
		echohl ErrorMsg
		echomsg "dotfiles: hcm: V_DoVBlock: Internal error: It is not visual mode"
		echohl Normal
	elseif v:false
	\|| g:visual_mode ==# "char"
	\|| g:visual_mode ==# "line"
	\|| g:visual_mode ==# "block"
		let g:pseudo_visual = g:pseudo_visual?v:false?v:true
		Showtab
	else
		echohl ErrorMsg
		echomsg "dotfiles: hcm: V_DoVBlock: Internal error: Wrong visual mode: ".g:visual_mode
		echohl Normal
	endif
endfunction
xnoremap <c-v> <cmd>call V_DoVBlock()<cr>
xnoremap <nowait> <esc> <cmd>let g:pseudo_visual=v:true<cr>
function! MoveLeft()
	let c=col('.')
	let l=line('.')
	if v:false
	elseif v:false
	\|| g:visual_mode ==# "char"
	\|| g:visual_mode ==# "block"
		if v:false
		\|| c!=#g:ly
		\|| l!=#g:lx
			return "o"
		endif
		return "oo"
	elseif v:false
	\|| g:visual_mode ==# "line"
		if v:false
		\|| c!=#g:ly
		\|| l!=#g:lx
			return "o"
		endif
		return "o0"
	else
		echohl ErrorMsg
		echomsg "dotfiles: hcm: MoveLeft: Internal error: Wrong visual mode: ".g:visual_mode
		echohl Normal
	endif
endfunction
function! V_DoI()
	return MoveLeft()."\<esc>i"
endfunction
xnoremap <expr> i V_DoI()
function! MoveRight()
	let c=col('.')
	let l=line('.')
	if v:false
	elseif v:false
	\|| g:visual_mode ==# "char"
	\|| g:visual_mode ==# "block"
		if v:true
		\&& c==#g:ly
		\&& l==#g:lx
			return "o"
		endif
	elseif v:false
	\|| g:visual_mode ==# "line"
		if l==#g:lx
			return "o$"
		endif
		return "$"
	else
		echohl ErrorMsg
		echomsg "dotfiles: hcm: MoveRight: Internal error: Wrong visual mode: ".g:visual_mode
		echohl Normal
	endif
endfunction
function! V_DoA()
	return MoveRight()."\<esc>a"
endfunction
unmap a%
xnoremap <expr> a V_DoA()
let g:last_selected = ''
function! V_DoS()
	if isdirectory(g:LOCALSHAREPATH."/site/pack/packer/start/vim-quickui")
		let select = quickui#input#open('Select:', g:last_selected)
	else
		let hcm_select_label = 'select'.(g:last_selected!=#''?' (default: '.g:last_selected.')':'').':'
		let select = input(hcm_select_label)
	endif
	if select ==# ''
		let select = g:last_selected
	else
		let g:last_selected = select
	endif
	call feedkeys(MoveLeft(), 't')
	call ExitVisual()
	let cnt = count(GetVisualSelection(), select)
	echomsg "cnt is: ".cnt
	if cnt !=# 0
		execute "VMSearch" select
		for _ in range(cnt-1)
			call vm#commands#find_next(v:false, v:false)
		endfor
	endif
endfunction
xnoremap s <cmd>call V_DoS()<cr>
function! V_DoX()
	let g:lx = line('.')
	let g:ly = col('.')
	normal! o
	let g:rx = line('.')
	let g:ry = col('.')
	normal! o
	call ReorderRightLeft()
	execute "normal! ".MoveLeft()
	normal! o
	if v:false
	\|| g:ly !=# 1
	\|| g:ry <# strlen(getline(g:rx))
		normal! o0o$
	else
		normal! j$
	endif
endfunction
xnoremap x <cmd>call V_DoX()<cr>
function! V_DoXDoNotExtendSubsequentLines()
	let g:lx = line('.')
	let g:ly = col('.')
	normal! o
	let g:rx = line('.')
	let g:ry = col('.')
	normal! o
	call ReorderRightLeft()
	execute "normal! ".MoveLeft()
	let lx=line('.')
	let ly=col('.')
	normal! o
	let rx=line('.')
	let ry=col('.')
	if v:false
	\|| ly !=# 1
	\|| ry <# strlen(getline(rx))
		normal! o0o$
	endif
endfunction
xnoremap X <cmd>call V_DoXDoNotExtendSubsequentLines()<cr>
function! V_DoH(c)
	if g:pseudo_visual
		execute "normal! \<esc>"
		let i=0
		while i<#a:c
			normal! h
			let i+=1
		endwhile
	else
		let i=0
		while i<#a:c
			normal! h
			let i+=1
		endwhile
		call ReorderRightLeft()
		call SavePosition()
	endif
endfunction
xnoremap h <cmd>call V_DoH(v:count1)<cr>
xnoremap <left> <cmd>call V_DoH(v:count1)<cr>
function! V_DoL(c)
	if g:pseudo_visual
		execute "normal! \<esc>"
		let i=0
		while i<#a:c
			normal! l
			let i+=1
		endwhile
	else
		let i=0
		while i<#a:c
			normal! l
			let i+=1
		endwhile
		call ReorderRightLeft()
		call SavePosition()
	endif
endfunction
xnoremap l <cmd>call V_DoL(v:count1)<cr>
xnoremap <right> <cmd>call V_DoL(v:count1)<cr>
function! V_DoW()
	if g:pseudo_visual
		execute "normal! \<esc>wviw"
	else
		normal! w
	endif
endfunction
xnoremap w <cmd>call V_DoW()<cr>
function! V_DoWWhole()
	if g:pseudo_visual
		execute "normal! \<esc>wviW"
	else
		normal! W
	endif
endfunction
xnoremap W <cmd>call V_DoWWhole()<cr>
function! V_DoE()
	if g:pseudo_visual
		execute "normal! \<esc>eviw"
	else
		normal! e
	endif
endfunction
xnoremap e <cmd>call V_DoE()<cr>
function! V_DoEWhole()
	if g:pseudo_visual
		execute "normal! \<esc>wviW"
	else
		normal! E
	endif
endfunction
xnoremap E <cmd>call V_DoEWhole()<cr>
function! V_DoB()
	if g:pseudo_visual
		execute "normal! \<esc>hviwo"
	else
		execute "normal! b"
	endif
endfunction
xnoremap b <cmd>call V_DoB()<cr>
function! V_DoBWhole()
	if g:pseudo_visual
		execute "normal! \<esc>hviW"
	else
		execute "normal! B"
	endif
endfunction
xnoremap B <cmd>call V_DoBWhole()<cr>
function! V_DoC()
	let g:lx = line('.')
	let g:ly = col('.')
	normal! o
	let g:rx = line('.')
	let g:ry = col('.')
	normal! o
	call ReorderRightLeft()
	execute "normal! ".MoveLeft()
	normal! o
	if v:false
	\|| g:ly !=# 1
	\|| g:ry <# strlen(getline(g:rx))
		normal! d
		startinsert
	else
		normal! dO
		call feedkeys("cc", 'n')
	endif
endfunction
xnoremap c <cmd>call V_DoC()<cr>
let g:yank_mode = "char"
function! V_DoY()
	let g:lx = line('.')
	let g:ly = col('.')
	normal! o
	let g:rx = line('.')
	let g:ry = col('.')
	normal! o
	call ReorderRightLeft()
	execute "normal! ".MoveLeft()
	normal! o
	if v:false
	elseif v:false
	\|| g:ly ==# len(getline(g:lx))+1
	\&& g:ry ==# len(getline(g:rx))+1
		let g:yank_mode = "line"
	elseif v:false
	\|| (v:false
	\|| g:ry ==# len(getline(g:rx))
	\|| g:ry ==# len(getline(g:rx))+1
	\|| v:false)
	\&& g:ly ==# 1
		let g:yank_mode = "line_post"
	else
		normal! y
		let g:yank_mode = "char"
	endif

	if v:false
	elseif v:false
	\|| g:yank_mode ==# "char"
		execute
	elseif v:false
	\|| g:yank_mode ==# "line"
	\|| g:yank_mode ==# "line_post"
		execute "normal! \<esc>mzgv`zy"
	else
		echohl ErrorMsg
		echomsg "dotfiles: V_DoY: Internal error: wrong yank mode: ".g:yank_mode
		echohl Normal
	endif

	execute "normal! gv"
	let g:pseudo_visual = v:true

	if mode() ==# "\<c-v>"
		let g:visual_mode = "block"
		let startcol = getpos("'<")[2]
		let endcol = getpos("'>")[2]
		if col('.') !=# (startcol>#endcol?startcol:endcol)
			execute "normal! O"
		endif
	else
		let g:visual_mode = "char"
	endif
endfunction
xnoremap y <cmd>call V_DoY()<cr>
unmap ;
nnoremap ; <nop>
xnoremap ; <esc>
xnoremap o <esc>o
xnoremap O <esc>O
xnoremap <leader>xo o<cmd>call ReorderRightLeft()<cr>
xnoremap <leader>xO O<cmd>call ReorderRightLeft()<cr>
nnoremap C <c-v>j
xnoremap C j
nnoremap , <nop>
xnoremap , <esc>
nnoremap <c-s> m'
nnoremap U <c-r>
nnoremap g. g;
noremap <a-.> ;

if !g:use_nvim_cmp
	if has('nvim')
		unmap <leader>f
	endif
	unmap <leader>fr
	unmap <leader>fh
	unmap <leader>fb
	unmap <leader>fg
	unmap <leader>ff
endif
nnoremap <leader>f <cmd>call FuzzyFind()<cr>
nnoremap <leader>F <cmd>call FuzzyFind()<cr>
nnoremap <leader>b <cmd>call quickui#tools#list_buffer('e')<cr>
nnoremap <leader>j <cmd>jumps<cr>
nnoremap <leader>s <cmd>TagbarToggle<cr>
nnoremap <leader>S <cmd>TagbarToggle<cr>
nnoremap <leader>d <cmd>Trouble diagnostics toggle filter.buf=0<cr>
nnoremap <leader>D <cmd>Trouble diagnostics toggle<cr>
nnoremap <leader>ww <c-w>w
nnoremap <leader>w<c-w> <c-w>w
nnoremap <leader>ws <cmd>split<cr>
nnoremap <leader>w<c-s> <cmd>split<cr>
nnoremap <leader>wv <cmd>vsplit<cr>
nnoremap <leader>w<c-v> <cmd>vsplit<cr>
nnoremap <leader>wt <c-w>J
nnoremap <leader>w<c-t> <c-w>J
nnoremap <leader>wf <cmd>split <cfile><cr>
nnoremap <leader>wF <cmd>vsplit <cfile><cr>
nnoremap <leader>wq <cmd>quit<cr>
nnoremap <leader>w<c-q> <cmd>quit<cr>
nnoremap <leader>wo <cmd>only<cr>
nnoremap <leader>w<c-o> <cmd>only<cr>
nnoremap <leader>wh <c-w>h
nnoremap <leader>w<c-h> <c-w>h
nnoremap <leader>wj <c-w>j
nnoremap <leader>w<c-j> <c-w>j
nnoremap <leader>wk <c-w>k
nnoremap <leader>w<c-k> <c-w>k
nnoremap <leader>wl <c-w>l
nnoremap <leader>w<c-l> <c-w>l
nnoremap <leader>w<left> <c-w>h
nnoremap <leader>w<down> <c-w>j
nnoremap <leader>w<up> <c-w>k
nnoremap <leader>w<right> <c-w>l
nnoremap <leader>wH <c-w>H
nnoremap <leader>wJ <c-w>J
nnoremap <leader>wK <c-w>K
nnoremap <leader>wL <c-w>L
nnoremap <leader>y <cmd>echohl ErrorMsg<cr><cmd>echom "No selection"<cr><cmd>echohl Normal<cr>
nnoremap <leader>Y <cmd>echohl ErrorMsg<cr><cmd>echom "No selection"<cr><cmd>echohl Normal<cr>
xnoremap <leader>y y
xnoremap <leader>Y y
nnoremap <leader>R <cmd>for i in range(line("'>")-line("'<"))<bar>let l=line("'<")+i<bar>call setline(l,substitute(getline(l),getreg('x')))<bar>endfor<cr>
nnoremap <leader>k K
nnoremap <leader>r <Plug>(coc-rename)
nnoremap <leader><c-c> <cmd>Telescope commands<cr>
