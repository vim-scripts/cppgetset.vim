" vim:ff=unix ts=4 ss=4
" vim60:fdm=marker
" \file		cppgetset.vim
"
" \brief	Make get/set member functions for data members.
"
" \note		Luc Hermitte's cpp_InsertAccessors.vim is basicaly superior (but
"			a bit larger)
"			See: http://hermitte.free.fr/vim
"
" \note		This is VIM-Script #438
"			See: http://vim.sourceforge.net/script.php?script_id=438
"
" \note		Inspired by javaGetSet.vim by Tom Bast
"			See: http://vim.sourceforge.net/script.php?script_id=436
"
" \author	Robert KellyIV <Sreny@SverGbc.Pbz> (Rot13ed)
" \note		Emial addresses are Rot13ed. Place cursor in the <> and do a g?i<
" \date		Thu, 17 Oct 2002 22:26 Pacific Daylight Time
" \version	$Id: cppgetset.vim,v 1.1 2002/10/15 02:27:50 root Exp $
" Version:	0.2
" History:	{{{
"	[Feral:290/02@21:59] 0.2
"		Some rather fancy changes / Misc improvments.
"	Improvments:
"		* More robust class/struct handling (from copycppdectoimp.vim 0.43)
"		* Global vars for options to determin how the get set methods look.
"		* Proper ftplugin, MUST be placed in ftplugin/cpp or the like.
"	0.1
"		Inspired by Tom Bast's javaGetSet.vim Revision: 1.3, Date: 2002/10/02 15:23:58.
" }}}

"Place something like the below in your .vimrc or where ever you like to keep
"	your global option vars and change as desired.
""
""*****************************************************************
"" GETSET Options: {{{
""*****************************************************************
"" You are welcomed to email me if there is another format you would like for
""	this, please include example code!
"" See cppgetset.vim for more documtation.
"" Member Function Name Prefix:
""		0 for (default)
""			"Get_"
""			"Set_"
""		else
""			"get"
""			"set"
"let g:getset_StyleOfGetSetMethod				= 1
"" Brace Style:
""		0 for (default)
""			func()
""			{
""			}
""		else
""			func() {
""			}
"let g:getset_StyleOfBraces						= 1
"" HowTo Trim Var Prefix:
""		1 for (default)
""			if Var prefix is m_ remove the m so the prefix is _
""			else prepend _
""		2 for
""			Prepend _
""		else
""			do not modify Var
""	I.e.
""		0 = m_lFlags	->	m_lFlags
""			mlFlags		->	mlFlags
""		1 = m_lFlags	->	_lFlags
""			mlFlags		->	_mlFlags
""		2 = m_lFlags	->	__lFlags
""			mlFlags		->	_mlFlags
"let g:getset_Trim_VarPrefix					= 2
"" Howto Trim Member Function Name Var Prefix:
""		1 for (default)
""			Remove m_
""		2 for
""			Remove m
""		else
""			do not modify Var
"let g:getset_Trim_MemberFunctionNameVarPrefix	= 2
"" }}}
""

" TextLinks for where the options are used, update these spots when adding new
"	options or changing/expanding existing options.
"||@|"Handle Options:|
"||@|"Do Something With The Options:|


if exists("b:loaded_cppgetset")
	finish
endif
let b:loaded_cppgetset = 1


"*****************************************************************
" Functions: {{{
if !exists("*s:CppGetSet(...)")
" Info: {{{
" Valid Params:
" 0, h, g
"	Get the var info
" 1, c, p, 2, i
"	Put the get/set member functions.
" 2, i
"	Put the get/set member functions, inline style
" }}}
function! s:CppGetSet(...) "{{{
	let l:WhatToDo = 0 " 0 = get var, else put get/set membervars.
	" [Feral:283/02@15:40] sort of guessing on extesions here.. I tend to only
	"	use .h ...
	if match(expand("%:e"), '\c\<h\>\|\<hpp\>\|\<hh\>\|\<hxx\>') > -1
		let l:WhatToDo = 0
	else
		let l:WhatToDo = 1
	endif

	" Override: {{{
	" Just for clarity override the above as a separate if
	if a:0 == 1
		if a:1 == '0' || a:1 ==? "h" || a:1 ==? "g"
			let l:WhatToDo = 0
"			let l:IsInline = 0 -- not used when getting. I want it to error
"			(so I can fix it) if we some how get into that mode or I use it
"			there.
		elseif a:1 == '1' || a:1 ==? "c" || a:1 ==? "p"
			let l:WhatToDo = 1
			let l:IsInline = 0
		elseif a:1 == '2' || a:1 ==? "i"
			let l:WhatToDo = 1
			let l:IsInline = 1
		else
			echo "GETSET: ERROR: Unknown option"
			return
		endif
	endif
"	echo confirm("l:WhatToDo:".l:WhatToDo)
	" }}}

	"Handle Options: {{{
	if exists('g:getset_StyleOfGetSetMethod')
		let StyleOfGetSetMethod		= g:getset_StyleOfGetSetMethod
	else
		let StyleOfGetSetMethod		= 0
	endif

	if exists('g:getset_StyleOfBraces')
		let StyleOfBraces						= g:getset_StyleOfBraces
	else
		let StyleOfBraces						= 0
	endif

	if exists('g:getset_Trim_VarPrefix')
		let Trim_VarPrefix						= g:getset_Trim_VarPrefix
	else
		let Trim_VarPrefix						= 1
	endif

	if exists('g:getset_Trim_MemberFunctionNameVarPrefix')
		let Trim_MemberFunctionNameVarPrefix	= g:getset_Trim_MemberFunctionNameVarPrefix
	else
		let Trim_MemberFunctionNameVarPrefix	= 1
	endif
	" }}}

	" Now do something!
	if l:WhatToDo == 0
		" {{{ Get the var...
		" In a header file, lets ASSume we are on the line the user wants to
		" make get/set member functions for; I.e. a line that contains a
		" variable defintion

		" save our position
		let SaveL = line(".")
		let SaveC = virtcol(".")
		" :help restore-position
		execute ":normal! H"
		let SaveT = line('.')
		execute ":normal! ".SaveL."G"


		" get the var type and name from the line. {{{
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
			" [Feral:290/02@06:22] If YOU really need this email me with how
			" it should look and I'll see what I can do with it.
			return
		endif
		" }}}


		" find what class this data member belongs to.
" {{{ Mark III (from copycppdectoimp.vim 0.43)
		let s:ClassName = ""
		let mx='\(\<class\>\|\<struct\>\|\<namespace\>\)\s\{-}\(\<\I\i*\)\s\{-}.*'
		while 1
			if searchpair('{','','}', 'bW') > 0
				if search('\%(\<class\>\|\<struct\>\|\<namespace\>\).\{-}\n\=\s\{-}{', 'bW') > 0
					let DaLine = getline('.')
					let Lummox = matchstr(DaLine, mx)
"					let s:ClassName = substitute(Lummox, mx, '\1', '') . '::' . s:ClassName
					let FoundType = substitute(Lummox, mx, '\1', '')
					let FoundClassName = substitute(Lummox, mx, '\2', '')
"					echo confirm(FoundClassName.' is a '.FoundType)
					if FoundType !=? 'namespace' && FoundType != ''
						let s:ClassName = FoundClassName.'::'.s:ClassName
					endif
				else
					echo confirm("cppgetset.vim:DEV:Found {} but no class/struct\nIf this was a proper function and you think it should have worked, email me the (member) function/class setup and I'll see if I can get it to work.(email is in this file)")
				endif
			else
				break
			endif
		endwhile
"		echo confirm('s:ClassName('.s:ClassName.')')
" }}}

		" {{{ make sure s:ClassName is not nothing (a distinct posibility)
		if s:ClassName == ""
			echo "GETSET does not work on non class data members at this time, suggestions and encouragement welcome :)"
			return
		endif
		" }}}

		" go back to where we were.
		execute ":normal! ".SaveT."Gzt"
		execute ":normal! ".SaveL."G"
		execute ":normal! ".SaveC."|"

"		echo confirm(s:ClassName)
		" }}}
	else
		" {{{ Paste the get/set functions.
"		echo confirm('('.s:VarType.')('.s:VarName.')('.s:ClassName.')')

" {{{ NOTE: Sample output from Tom Bast's javaGetSet.vim
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

		" -[Feral:290/02@06:29]--------------------------------------------
		" Gate
		if !exists("s:VarType")
			echo "GETSET: ERROR: I do not have any variable data to work with!"
			return
		endif

		" Fixup the param name {{{
		" 1 = m_lFlags	->	_lFlags
		"     mlFlags	->	_mlFlags
		" 2 = m_lFlags	->	__lFlags
		"     mlFlags	->	_mlFlags
		" 3 = m_lFlags	->	m_lFlags
		"     mlFlags	->	mlFlags
		if Trim_VarPrefix == 1
			if match(s:VarName, "m_") == 0
				let ParamName = strpart(s:VarName, 1)
			else
				let ParamName = '_'.s:VarName
			endif
		elseif Trim_VarPrefix == 2
				let ParamName = '_'.s:VarName
		else
				let ParamName = s:VarName
		endif
		" }}}

		" Fixup the get/set name {{{
		" [Feral:276/02@13:48] Now I find getm_lFlags to look well, odd. So if
		" s:VarName starts with m_ get rid of it. i.e. getm_lFlags becomes
		" getlFlags.
		if Trim_MemberFunctionNameVarPrefix == 1
			if match(s:VarName, '\<m_') == 0
				let VarName = strpart(s:VarName, 2)
			else
				let VarName = s:VarName
			endif
		elseif Trim_MemberFunctionNameVarPrefix == 2
			if match(s:VarName, '\<m') == 0
				let VarName = strpart(s:VarName, 1)
			else
				let VarName = s:VarName
			endif
		else
			let VarName = s:VarName
		endif
		" }}}

		"Do Something With The Options: {{{
		if StyleOfGetSetMethod == 0
			let GetStr = "Get_"
			let SetStr = "Set_"
		else
			let GetStr = "get"
			let SetStr = "set"
		endif

		if StyleOfBraces == 0
			" func()
			" {
			" }
			let BraceStr = "\n{\n"
		else
			" func() {
			" }
			let BraceStr = " {\n"
		endif
		" }}}


		" {{{ Handle inline part 1 -- remove the class name.
		if l:IsInline == 1
			let ClassName = ""
		else
			let ClassName = s:ClassName
		endif
		" }}}

		" {{{ save/fill in register with our functions and then put it.
		let Was_Reg_z = @z
"[Feral:290/02@06:36] Get/set and whatever else should be an option.
"	Actually, feeding s:VarName and s:VarType into a template could be best,
"	but I'm not sure I want to goto that work :)
		" Get Member Function:
		let @z=   "// {{"."{\n"
		let @z=@z."/*!\n"
		let @z=@z." * \\brief\tGet ".s:VarName.".\n"
		let @z=@z." *\n"
		let @z=@z." * \\return\t".s:VarName." as a ".s:VarType.".\n"
		let @z=@z." */ // }}"."}\n"
		let @z=@z.s:VarType." ".ClassName.GetStr.VarName."()".BraceStr
		let @z=@z."\treturn(".s:VarName.");\n"
		let @z=@z."}\n"

		" If we are inline, skip the two spaces seperating the memberfunctions
		"	so that they are grouped nicly in the class.
		if l:IsInline != 1
			let @z=@z."\n"
"			put z
"			let @z=   "\n"
			let @z=@z."\n"
		endif

		" Set Member Function:
		let @z=@z."// {{"."{\n"
		let @z=@z."/*!\n"
		let @z=@z." * \\brief\tSet ".s:VarName.".\n"
		let @z=@z." *\n"
		let @z=@z." * \\param\t".ParamName."\tThe new value for ".s:VarName." (as a ".s:VarType.").\n"
		let @z=@z." */ // }}"."}\n"
		let @z=@z."void ".ClassName.SetStr.VarName."(".s:VarType." ".ParamName.")".BraceStr
		let @z=@z."\t".s:VarName." = ".ParamName.";\n"
		let @z=@z."\treturn;\n"
		let @z=@z."}\n"
		let @z=@z."\n"
		put! z

		let @z=Was_Reg_z
		" }}}

		" {{{ Handle inline part 2 -- = the inserted text.
		if l:IsInline == 1
			execute "normal! =']"
		endif
		" }}}

		" }}}
	endif

endfunction
"}}}
endif
" }}}

"*****************************************************************
" Commands: {{{
"*****************************************************************

" GETSET Usage: {{{
"	Simply :GETSET with your cursor on the variable you wish to process, and
"	:GETSET will attempt to be smart and either get the data or put the
"	member functions depending on the file extension it was called from. If
"	you wish to overide this behavior simply place g (to get) or p (to put) on
"	the command line (or as a param to <SID>CppGetSet())
"	In Header:
"		:GETSET
"	In Source:
"		:GETSET
"	Inline Member Functions:
"		:GETSET i
"	Putting The Member Functions While In A Header:
"		:GETSET p
"	Getting The Variables While In A Source File:
"		:GETSET g
" }}}
if !exists(":GETSET")
:command -buffer -nargs=? GETSET call <SID>CppGetSet(<f-args>)
endif

"*****************************************************************
" }}}
"
" EOF
