' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

Option Base 0
Option Default None
Option Explicit On

#Include "../splib/system.inc"
#Include "../splib/array.inc"
#Include "../splib/list.inc"
#Include "../splib/string.inc"
#Include "../splib/file.inc"

Dim f$ = fil.find$(Cwd$, Mm.CmdLine$, "all")
Do While f$ <> ""
  Print f$
  f$ = fil.find$()
Loop
