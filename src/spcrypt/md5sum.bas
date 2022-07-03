' Copyright (c) 2021-2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default None
Option Base 0

#Include "../splib/system.inc"
#Include "../splib/array.inc"
#Include "../splib/crypt.inc"
#Include "../splib/string.inc"

Dim filename$ = str.unquote$(str.trim$(Mm.CmdLine$))
If filename$ = "" Then Error "No file specified"
Open filename$ For Input As #1
Dim md5%(array.new%(2))
Dim result% = crypt.md5_file%(1, md5%())
Close #1
Print Choice(result%, crypt.md5_fmt$(md5%()), sys.err$)
