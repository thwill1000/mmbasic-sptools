' Copyright (c) 2021 Thomas Hugo Williams
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
Print crypt.md5_file$(1)
Close #1
