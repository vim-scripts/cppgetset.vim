" vim:ff=unix ts=4 ss=4
" vim60:fdm=marker
" \file		cppgetset.vim
"
" \brief	Convert a data type definition into get/set data members.
" \note		Inspired by javaGetSet.vim by Tom Bast
"			See: http://vim.sourceforge.net/script.php?script_id=436
" \note		Built on my previous work derived from Leif Wickland's VIM-Tip #335
"			See: http://vim.sourceforge.net/tip_view.php?tip_id=335
" \note		Register pasting origial idea from one of them scripts at
"			vim.sf.net :)
"
" \author	Robert KellyIV <Sreny@SverGbc.Pbz> (Rot13ed)
" \note		Emial addresses are Rot13ed. Place cursor in the <> and do a g?i<
" \date		Mon, 07 Oct 2002 20:08 Pacific Daylight Time
" \version	$Id$
" Version:	0.1
" History:	{{{
"
"	0.1
"		Inspired by Tom Bast's javaGetSet.vim Revision: 1.3, Date: 2002/10/02 15:23:58.
"
" }}}

if exists("loaded_cppgetset")
	finish
endif
let loaded_cppgetset = 1


function! <SID>CppGetSet() "{{{
"	echo confirm(expand("%:e"))
	if expand("%:e") ==? "h"
		" In a header file, lets ASSume we are on the line the user wants to
		" make get/set member functions for; I.e. a line that contains a
		" variable defintion

		" save where we are
		let SaveL = line(".")
		let SaveC = virtcol(".")
		" :help restore-position
		execute ":normal! H"
		let SaveT = line('.')
		execute ":normal! ".SaveL."G"

		" get the var type and name from the line.
		let DaLine = getline(".")
"		echo confirm('('.DaLine.')')

		" Set up the match bit
		let mx='^\s\{-}\(\<[a-zA-Z_][a-zA-Z0-9_]*\)\s\{-}\(\<[a-zA-Z_][a-zA-Z0-9_]*\)'
		"get the part matching the whole expression
		let Lummox = matchstr(DaLine, mx)
		"get each item out of the match
		let s:VarType = substitute(Lummox, mx, '\1', '')
		let s:VarName = substitute(Lummox, mx, '\2', '')
"		echo confirm('('.s:VarType.')')
"		echo confirm('('.s:VarName.')')
		if s:VarType ==? 'static'
			echo confirm('Sorry static variables not supported.')
			" [Feral:275/02@15:20] We do not support static variables because
			" the format for their get/set is different enough to special case
			" (at least the set) and as I usually do not use them I'll stick
			" to simplicity for now.
			return
		endif


		" find what class this data member belongs to.
		execute ":normal! [["
		execute ":normal! kw"
		let Was_Reg_c = @c
		execute ':normal! "cye'
		let s:ClassName = @c
		let @c=Was_Reg_c
"		echo confirm(s:ClassName)

		" go back to where we were.
		execute ":normal! ".SaveT."Gzt"
		execute ":normal! ".SaveL."G"
		execute ":normal! ".SaveC."|"


""nmap <F5> "lYml[[kw"cye'l
""		execute ":normal! ml"
"		let SaveL = line(".")
"		let SaveC = virtcol(".")
"
"		" into l yank the entire line
"		" ([Feral:274/02@19:06] MY Y is mapped to y$, so I account for that below)
"		:let Was_Reg_l = @l
""		execute ':normal! "lY'
"		execute ':normal! 0"ly$'
""		echo confirm(@l)
"		:let s:LineWithDecloration = @l
"		:let @l=Was_Reg_l
"
"		" [Feral:274/02@14:41] this works peachy for a member function, not so
"		" well for a normal function, how can we fix this? Or do we bother?
"		execute ":normal! [["
"		execute ":normal! kw"
"		:let Was_Reg_c = @c
"		execute ':normal! "cye'
"		:let s:ClassName = @c
"		:let @c=Was_Reg_c
"
""		execute ":normal! 'l"
"		:execute ":normal! ".SaveL."G"
"		:execute ":normal! ".SaveC."|"
"
"		echo confirm(s:ClassName)
	else
"		echo confirm('('.s:VarType.')('.s:VarName.')('.s:ClassName.')')

" {{{ Sample output from Tom Bast's javaGetSet.vim
"/**
"* Get iLenBuffer.
"*
"* @return iLenBuffer as a int
"*/
"public int getILenBuffer()
"{
"	return(iLenBuffer);
"}
"
"/**
" * Set iLenBuffer.
" *
" * @param The iLenBuffer as a int
" */
"public void setILenBuffer(int iLenBuffer)
"{
"	this.iLenBuffer = iLenBuffer;
"	return;
"}
" }}}

		" [Feral:276/02@13:32] I am picky about how my params should look (I
		" like _<paramname>, i.e. _lFlags. So, if the s:VarName starts with 'm_'
		" (a class data member) then strip the starting 'm' so we are left with
		" a starting '_', i.e. m_lFlags becomes _lFlags, which is exactly what I
		" want, else prepend '_' so lFlags would become _lFlags and _lFlags
		" would become __lFlags.
		if match(s:VarName, "m_") == 0
			let ParamName = strpart(s:VarName, 1)
		else
			let ParamName = '_'.s:VarName
		endif
		" [Feral:276/02@13:48] Now I find getm_lFlags to look well, odd. So if
		" s:VarName starts with m_ get rid of it. i.e. getm_lFlags becomes
		" getlFlags.
		if match(s:VarName, "m_") == 0
			let VarName = strpart(s:VarName, 2)
		else
			let VarName = s:VarName
		endif
		let Was_Reg_z = @z
		let @z=   "// {{"."{\n"
		let @z=@z."/*!\n"
		let @z=@z." * \\brief\tGet ".s:VarName.".\n"
		let @z=@z." *\n"
		let @z=@z." * \\return\t".s:VarName." as a ".s:VarType.".\n"
		let @z=@z." */ // }}"."}\n"
"		let @z=@z.s:VarType." ".s:ClassName."::get".VarName."()\n"
		let @z=@z.s:VarType." ".s:ClassName."::Get_".VarName."()\n"
		let @z=@z."{\n"
		let @z=@z."\treturn(".s:VarName.");\n"
		let @z=@z."}\n"
		let @z=@z."\n"
		let @z=@z."// {{"."{\n"
		let @z=@z."/*!\n"
		let @z=@z." * \\brief\tSet ".s:VarName.".\n"
		let @z=@z." *\n"
		let @z=@z." * \\param\t".ParamName."\tThe new value for ".s:VarName." (as a ".s:VarType.").\n"
		let @z=@z." */ // }}"."}\n"
"		let @z=@z."void ".s:ClassName."::set".VarName."(".s:VarType." ".ParamName.")\n"
		let @z=@z."void ".s:ClassName."::Set_".VarName."(".s:VarType." ".ParamName.")\n"
		let @z=@z."{\n"
		let @z=@z."\t".s:VarName." = ".ParamName.";\n"
		let @z=@z."\treturn;\n"
		let @z=@z."}\n"
		let @z=@z."\n"
		put z
		let @z=Was_Reg_z

"		let SaveL = line(".")
"		let SaveC = virtcol(".")
""		:execute ':normal! ma'
"		:let Was_Reg_n = @n
"		:let @n=@/
"		:execute ':normal! O'.s:LineWithDecloration
"		:execute ':normal! =='
"
"		" XXX if you want virtual commented in the implimentation:
"		if a:howtoshowVirtual == 1
"			:s/\<virtual\>/\/\*&\*\//e
"		else
"			" XXX else, remove virtual and any spaces/tabs after it.
"			:s/\<virtual\>\s*//e
"		endif
"
"		" XXX if you want static commented in the implimentation:
"		if a:howtoshowStatic == 1
"			:s/\<static\>/\/\*&\*\//e
"		else
"			" XXX else, remove static and any spaces/tabs after it.
"			:s/\<static\>\s*//e
"		endif
"
"
"		" wipe out a pure virtual thingie-ma-bob. (technical term? (= )
"		:s/\s*=\s*0\s*//e
"
"		" Handle default params, if any.
"		if a:howtoshowDefaultParams == 1
"			" Remove the default param assignments.
"			:s/\s\{-}=\s\{-}[^,)]\{1,}//ge
"		else
"			" Comment the default param assignments.
"			:s/\s\{-}\(=\s\{-}[^,)]\{1,}\)/\/\*\1\*\//ge
"
"			if a:howtoshowDefaultParams == 3
"				" Remove the = and any spaces to the left or right.
"				:s/\s*=\s*//ge
"			endif
"		endif
"
"		:let @/=@n
"		:let @n=Was_Reg_n
"		:execute ":normal! ".SaveL."G"
"		:execute ":normal! ".SaveC."|"
"		:execute ':normal! f(b'
"		:execute ':normal! i'.s:ClassName.'::'
"
"		" find the ending ; and replace it with a brace structure on the next line.
"		:execute ":normal! f;s\<cr>{\<cr>}\<cr>\<esc>kk"
	endif
endfunc
"}}}

"*****************************************************************
"* Commands
"*****************************************************************
:command! -nargs=0 GETSET call <SID>CppGetSet()

" eof
