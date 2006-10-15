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


'' fbdoc_loader_web
''
''
'' chng: jun/2006 written [coderJeff]
''

#include once "common.bi"
#include once "CWikiCon.bi"

dim shared as CWikiCon ptr wikicon
dim shared as string wiki_url

'' --------------------------------------------------------------------------
'' Wiki Connection and Page Loader
'' --------------------------------------------------------------------------

'':::::
sub Connection_SetUrl( byval url as zstring ptr )
	wiki_url = *url
end sub

'':::::
function Connection_Create( ) as CWikiCon Ptr
	if( wikicon <> NULL ) then
		return wikicon
	end if
	
	wikicon = CWikiCon_New( wiki_url )

	return wikicon
	
end function

'':::::
sub Connection_Destroy( )
	if( wikicon = NULL ) then
		exit sub
	end if
	
	CWikiCon_Delete( wikicon )
	wikicon = NULL
	
end sub
