' Copyright (c) 2020 Thomas Hugo Williams

Option Base 0
Option Default None
Option Explicit On

#Include "../common/array.inc"
#Include "../common/file.inc"
#Include "../common/list.inc"
#Include "../common/strings.inc"

Dim f$ = fil.find$(Cwd$, Mm.CmdLine$, "all")
Do While f$ <> ""
  Print f$
  f$ = fil.find$()
Loop
