''  fbdoc - FreeBASIC User's Manual Converter/Generator
''	Copyright (C) 2006 Jeffery R. Marshall (coder[at]execulink.com) and
''  the FreeBASIC development team.
''
''	This program is free software; you can redistribute it and/or modify
''	it under the terms of the GNU General Public License as published by
''	the Free Software Foundation; either version 2 of the License, or
''	(at your option) any later version.
''
''	This program is distributed in the hope that it will be useful,
''	but WITHOUT ANY WARRANTY; without even the implied warranty of
''	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
''	GNU General Public License for more details.
''
''	You should have received a copy of the GNU General Public License
''	along with this program; if not, write to the Free Software
''	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.


'' fbdoc - freebasic user's manual converter/generator main module
''
'' chng: jun/2006 written [coderJeff]
''

#include once "common.bi"

#include once "CWiki2Chm.bi"
#include once "CWiki2fbhelp.bi"
#include once "COptions.bi"

#include once "fbdoc_lang.bi"
#include once "fbdoc_cache.bi"
#include once "fbdoc_loader.bi"
#include once "fbdoc_loader_web.bi"
#include once "fbdoc_loader_sql.bi"
#include once "fbdoc_buildtoc.bi"
#include once "fbdoc_templates.bi"
#include once "fbdoc_keywords.bi"
#include once "fbdoc_misc.bi"

const default_wiki_url = "http://www.freebasic.net/wiki/wikka.php"
const default_CacheDir = "cache/"


'' --------------------------------------------------------------------------
'' main
'' --------------------------------------------------------------------------

	dim as integer CacheRefreshMode = CACHE_REFRESH_IFMISSING
	dim as string sCacheDir = default_CacheDir
	dim as string sOutputDir = ""
	dim as string sConnFile, sLangFile, sTocTitle, sDocToc, sTemplateDir
	dim as integer i = 1, h
	dim as integer bMakeKeywords = FALSE
	dim as COptions ptr connopts = NULL

	dim as integer bShowHelp = FALSE, bShowVersion = FALSE
	dim as integer bUseWeb = FALSE, bUseSql = FALSE, bMakeIni = FALSE
	dim as integer bEmitChm = FALSE
	dim as integer bEmitfbhelp = FALSE
	dim as string SinglePage = ""
	dim as integer bSinglePage = FALSE
	redim as string webPageList(1 to 10)
	dim as integer webPageCount = 0, bWebPages = FALSE

	if( len(command(1)) = 0 ) then
		bShowHelp = TRUE
	else
		while( len( command(i) ) > 0 )
			select case lcase(command(i))
			case "-version"
				bShowVersion = TRUE
			case "-h", "-help", "/?", "/h", "/help"
				bShowHelp = TRUE
			end select
			i += 1
		wend

	end if

	if( bShowHelp ) then
		? "fbdoc options
		? ""
		? "options:"
		? "   -makeini       create the default ini file if it does not exist and exit"
		? "   -useweb        load pages from wiki web"
		? "   -usesql        load pages from sql database"
		? "   -usecache      use cache as only source"
		? "   -refresh       refresh all pages"
		? "   -chm           generate html and chm output"
		? "   -fbhelp        generate output for fbhelp viewer"
		? "   -version       show version"
		? "   -getpage page1 [page2 [ ... pageN ]]]"
		? "                  get specified pages from web and store in the cache"
		? "   -getpage @listfile"
		? "                  get specified pages using a list file from web and 
		? "                  store in the cache"
		? "   -makepage  pagename"
		? "                  process a single page (and links on page) only"
		? ""
		end 1
	end if

	if( bShowVersion ) then
		? "FreeBASIC User's Manual Converter/Generator - Version 0.1"
		? "Copyright (C) 2006 Jeffery R. Marshall (coder[at]execulink.com)"
		end 1
	end if

	i = 1
	while( len( command(i) ) > 0 )

		if( bWebPages ) then
			if left( command(i), 1) = "-" then
				bWebPages = FALSE
			else
				if left( command(i), 1) = "@" then
					scope
						dim h as integer, x as string
						h = freefile
						if open( mid(command(i),2) for input access read as #h ) <> 0 then
							print "Error reading '" + command(i) + "'"
						else
							while eof(h) = 0
								line input #h, x
								x = trim(x, any " " + chr(9))
								if( x > "" ) then 
									webPageCount += 1
									if( webPageCount > ubound(webPageList) ) then
										redim preserve webPageList(1 to Ubound(webPageList) * 2)
									end if
									webPageList(webPageCount) = x
								end if
							wend
							close #h
						end if
					end scope
				else
					webPageCount += 1
					if( webPageCount > ubound(webPageList) ) then
						redim preserve webPageList(1 to Ubound(webPageList) * 2)
					end if
					webPageList(webPageCount) = command(i)
				end if
			end if
		end if

		if( bSinglePage ) then
			if left( command(i), 1) = "-" then
				bSinglePage = FALSE
			else
				SinglePage = command(i)
			end if
		end if

		if(( bWebPages = FALSE ) and ( bSinglePage = FALSE )) then

			select case lcase(command(i))
			case "-makeini"
				bMakeIni = TRUE
			case "-r", "-refresh"
				CacheRefreshMode = CACHE_REFRESH_ALL
			case "-n", "-usecache"
				CacheRefreshMode = CACHE_REFRESH_NONE
			case "-useweb"
				bUseWeb = TRUE
			case "-usesql"
				bUseSql = TRUE
			case "-makekeypageslist"
				bMakeKeywords = TRUE
			case "-chm"
				bEmitChm = TRUE
			case "-fbhelp"
				bEmitfbhelp = TRUE
			case "-getpage"
				bWebPages = TRUE
			case "-makepage"
				bSinglePage = TRUE
			case else
				? "Unrecognized option '" + command(i) + "'"
				end 1
			end select
		
		end if

		i += 1
	wend

	'' If no connection is set, use cache only
	if( (bUseSQL = FALSE) and (bUseWeb = FALSE)) then
		CacheRefreshMode = CACHE_REFRESH_NONE
	end if
	
	'' Check output format is set
	if( (bEmitChm = FALSE) and (bEmitfbhelp = FALSE) ) then
		'' bEmitChm = TRUE
		'' TODO: warn no format is set when mutliple formats available
	end if

	
	if sConnFile = "" then
		sConnFile = ExePath & "/fbdoc.ini"
	end if

	if( bMakeIni ) then
		print "Makeing default connection ini file '" + sConnFile + "'"
		h = FreeFile
		if( open( sConnFile for input as #h ) = 0 ) then
			close #h
			print "ini file already exists."
		else
			if( open( sConnFile for output as #h ) = 0 ) then
				print #h, "[Wiki Connection]"
				print #h, "wiki_url = http://www.freebasic.net/wiki/wikka.php"
				print #h,

				print #h, "[MySql Connection]"
				print #h, "db_host = localhost"
				print #h, "db_user = user"
				print #h, "db_pass = password"
				print #h, "db_name = test"
				print #h, "db_port = 3306"
				print #h,

				close #h

			else
				print "Unable to create '" + sConnFile + "'"
			end if
		end if
		end 0
	end if

	'' Load connection options from the ini file
	connopts = COptions_New( sConnFile )
	if( connopts = NULL ) then
		? "Unable to load connection options file '" + sConnFile + "'"
		end 1
	end if

	'' Load language options
	sLangFile = "templates/default/lang/en/common.ini"
	if( Lang_LoadOptions( sLangFile ) = FALSE ) then
		? "Unable to load language file '" + sLangFile + "'"
		end 1
	end if

	'' Initialize the cache
	sCacheDir = COptions_Get( connopts, "cache_dir", default_CacheDir)
	if LocalCache_Create( sCacheDir, CacheRefreshMode ) = FALSE then
		? "Unable to use local cache dir " + sCacheDir
		end 1
	end if

	'' Initialize the wiki connection - in case its needed
	Connection_SetUrl( COptions_Get( connopts, "wiki_url", default_wiki_url) )

	'' If using SQL, get all the pages in to the cache now.
	if( bUseSql ) then
		
		dim as string  db_host = COptions_Get( connopts, "db_host")
		dim as string  db_user = COptions_Get( connopts, "db_user")
		dim as string  db_pass = COptions_Get( connopts, "db_pass")
		dim as string  db_name = COptions_Get( connopts, "db_name")
		dim as integer db_port = CInt(Val(COptions_Get( connopts, "db_port")))
		
		bUseWeb = FALSE
		CacheRefreshMode = CACHE_REFRESH_NONE

		if( Fetch_Pages_From_Database( db_host, db_user, db_pass, db_name, db_port ) = FALSE ) then
			print "Aborting."
			end 1
		end if
	end if

	
	'' Build up an index to all pages
	dim as CPageList ptr paglist, toclist

	'' TODO: make this an option
	'' SinglePage = "KeyPgScreenGraphics"
	'' SinglePage = "CptAscii"

	if( webPageCount > 0 ) then
		dim as integer i
		dim as string ret
		for i = 1 to webPageCount
			ret = LoadPage( webPageList(i), FALSE, TRUE )
		next i
		end 0
	end if

	if( len(SinglePage) > 0 ) then
		FBDoc_BuildSinglePage( SinglePage, SinglePage, @paglist, @toclist )

	else

		sDocToc = "DocToc"
		sTocTitle = Lang_GetOption( "fb_toc_title", "Table of Contents" )

		FBDoc_BuildTOC( sDocToc, sTocTitle, @paglist, @toclist )

	end if

	'' Load Keywords
	fbdoc_loadkeywords( "templates/default/keywords.lst" )

	if( bMakeKeywords = TRUE ) then
		misc_dumpkeypageslist( paglist, "keypages.txt" )

	else

		'' Emit formats
				
		if( bEmitChm )then

			'' Generate CHM
			sOutputDir = "html/"
			sTemplateDir = "templates/default/code/"

			Templates_LoadFile( "chm_idx", sTemplateDir + "chm_idx.tpl.html" )
			Templates_LoadFile( "chm_prj", sTemplateDir + "chm_prj.tpl.html" )
			Templates_LoadFile( "chm_toc", sTemplateDir + "chm_toc.tpl.html" )
			Templates_LoadFile( "chm_def", sTemplateDir + "chm_def.tpl.html" )
			Templates_LoadFile( "htm_toc", sTemplateDir + "htm_toc.tpl.html" )

			dim as CWiki2Chm ptr chm
			chm = CWiki2Chm_New( @"", 1, sOutputDir, paglist, toclist )
			CWiki2Chm_Emit( chm )
			CWiki2Chm_Delete( chm )

		end if

		if( bEmitfbhelp )then

			'' Generate fbhelp output for fbhelp console viewer
			sOutputDir = "fbhelp/"
			sTemplateDir = "templates/default/code/"

			dim as CWiki2fbhelp ptr fbhelp
			fbhelp = CWiki2fbhelp_New( @"", 1, sOutputDir, paglist, toclist )
			CWiki2fbhelp_Emit( fbhelp )
			CWiki2fbhelp_Delete( fbhelp )

		end if

	end if

	CPageList_Delete( toclist )
	CPageList_Delete( paglist )

	Connection_Destroy()
	LocalCache_Destroy()
	COptions_Delete( connopts )

	end
