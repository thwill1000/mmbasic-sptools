#!/usr/local/bin/mmbasic -i

' Copyright (c) 2022-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Explicit On
Option Default Integer

Const BS$ = Chr$(8)
Const CR$ = Chr$(13)

#Include "../splib/system.inc"
#Include "../splib/array.inc"
#Include "../splib/list.inc"
#Include "../splib/string.inc"
#Include "../splib/file.inc"
#Include "../splib/map.inc"
#Include "../splib/set.inc"
#Include "../splib/vt100.inc"
#Include "../common/sptools.inc"
#Include "../sptrans/input.inc"
#Include "../sptrans/keywords.inc"
#Include "../sptrans/lexer.inc"
#Include "../sptrans/options.inc"
#Include "../sptrans/defines.inc"
#Include "../sptrans/output.inc"
#Include "../sptrans/pprint.inc"
#Include "bas2js_trans.inc"
#Include "../sptrans/cmdline.inc"

Sub cendl()
  If opt.outfile$ <> "" Then Print
End Sub

Sub cout(s$)
  If opt.outfile$ <> "" Then Print s$;
End Sub

Sub cerror(msg$)
  Local i = in.num_open_files% - 1
  Print
  Print "[" + in.files$(i) + ":" + Str$(in.line_num%(i)) + "] Error: " + msg$
  End
End Sub

Sub main()
  Local s$, t

  in.init()
  opt.init()

  cli.parse(Mm.CmdLine$)
  If sys.err$ <> "" Then Print "bas2js: "; sys.err$ : Print : cli.usage() : End

  If Not file.exists%(opt.infile$) Then
    Print "bas2js: input file '" opt.infile$ "' not found."
    End
  EndIf

  If opt.outfile$ <> "" Then
    If file.exists%(opt.outfile$)) Then
      Line Input "Overwrite existing '" + opt.outfile$ + "' [y|N] ? ", s$
      If LCase$(s$) <> "y" Then Print "CANCELLED" : End
      Print
    EndIf
    opt.colour = 0
  EndIf

  keywords.init()

  ' No line numbers when output to file.
  If opt.outfile$ <> "" Then out.line_num_width% = 0

  out.open(opt.outfile$)

  If Not opt.format_only Then
    If opt.colour Then out.print(TK_COLOUR$(TK_COMMENT))
    out.print("' Transpiled on " + DateTime$(Now))
    If opt.colour Then out.print(vt100.colour$("reset"))
    out.endl()
    out.endl()
  EndIf

  cout("Transpiling from '" + opt.infile$ + "' to '" + opt.outfile$ + "' ...") : cendl()
  If in.open%(opt.infile$) <> sys.SUCCESS Then cerror(sys.err$)
  cout(in.files$(0)) : cendl()
  cout("   ")

  t = Timer
  Do
    cout(BS$ + Mid$("\|/-", ((in.line_num%(in.num_open_files% - 1) \ 8) Mod 4) + 1, 1))

    s$ = in.readln$()
    If lx.parse_basic%(s$) = sys.SUCCESS Then
      If Not opt.format_only Then tr.transpile()
      If tr.include$ <> "" Then open_include()
    EndIf
    If sys.err$ <> "" Then cerror(sys.err$)

    pp.print_line()

    If Eof(#in.num_open_files%) Then
      If in.num_open_files% > 1 Then close_include() Else in.close()
      If sys.err$ <> "" Then cerror(sys.err$)
      cout(BS$ + " " + CR$ + Space$(1 + in.num_open_files% * 2))
    EndIf

  Loop Until in.num_open_files% = 0

  Print
  Print "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")

  out.close()

End Sub

Sub open_include()
  Local s$ = lx.line$
  s$ = "' BEGIN:     " + s$ + " " + String$(66 - Len(s$), "-")
  If lx.parse_basic%(s$) = sys.SUCCESS Then
    If in.open%(tr.include$) = sys.SUCCESS Then
      Local i = in.num_open_files%
      cout(CR$ + Space$((i - 1) * 2) + in.files$(i - 1)) : cendl()
      cout(" " + Space$(i * 2))
    EndIf
  EndIf
End Sub

Sub close_include()
  Local s$ = "#Include " + str.quote$(in.files$(in.num_open_files% - 1))
  s$ = "' END:       " + s$ + " " + String$(66 - Len(s$), "-")
  If lx.parse_basic%(s$) = sys.SUCCESS Then pp.print_line()
  If sys.err$ = "" Then in.close()
End Sub

main()
End
