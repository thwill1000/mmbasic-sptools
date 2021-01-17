' Copyright (c) 2020-2021 Thomas Hugo Williams

Option Base 0
Option Default None
Option Explicit On

#Include "../splib/array.inc"
#Include "../splib/file.inc"
#Include "../splib/list.inc"
#Include "../splib/string.inc"

Dim f$ = fil.find$(Cwd$, Mm.CmdLine$, "all")
Do While f$ <> ""
  Print f$
  f$ = fil.find$()
Loop
