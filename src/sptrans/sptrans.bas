#!/usr/local/bin/mmbasic

' Copyright (c) 2020-2023 Thomas Hugo Williams
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
#Include "input.inc"
#Include "keywords.inc"
#Include "lexer.inc"
#Include "options.inc"
#Include "defines.inc"
#Include "output.inc"
#Include "pprint.inc"
#Include "expression.inc"
#Include "trans.inc"
#Include "cmdline.inc"

Sub cendl(always%)
  If Not Len(opt.outfile$) Then Exit Sub
  If Not always% And opt.quiet Then Exit Sub
  Print
End Sub

Sub cout(s$, always%)
  If Not Len(opt.outfile$) Then Exit Sub
  If Not always% And opt.quiet Then Exit Sub
  Print s$;
End Sub

Sub cerror(msg$)
  Local i = in.num_open_files% - 1
  Print
  Print "[" + in.files$(i) + ":" + Str$(in.line_num(i)) + "] Error: " + msg$
  If Mm.Device$ = "MMB4L" Then
    End 1
  Else
    End
  EndIf
End Sub

Sub main()
  Local s$, t

  opt.init()
  def.init()
  keywords.init()

  cli.parse(Mm.CmdLine$)
  If sys.err$ <> "" Then Print "sptrans: "; sys.err$ : End

  If Not file.exists%(opt.infile$) Then
    Print "sptrans: input file '" opt.infile$ "' not found."
    End
  EndIf

  If opt.outfile$ <> "" Then
    If file.exists%(opt.outfile$)) Then
      Line Input "Overwrite existing '" + opt.outfile$ + "' [y|N] ? ", s$
      If LCase$(s$) <> "y" Then Print "CANCELLED" : End
    EndIf
    opt.colour = 0
  EndIf

  ' No line numbers when output to file.
  If opt.outfile$ <> "" Then out.line_num_fmt$ = ""

  out.open(opt.outfile$)

  If Not opt.format_only Then
    If opt.colour Then out.print(TK_COLOUR$(TK_COMMENT))
    out.print("' Transpiled on " + DateTime$(Now))
    If opt.colour Then out.print(vt100.colour$("reset"))
    out.endl()
    out.endl()
  EndIf

  cout("Transpiling from '" + opt.infile$ + "' to '" + opt.outfile$ + "' ...", 1) : cendl(1)
  If in.open%(opt.infile$) <> sys.SUCCESS Then cerror(sys.err$)
  cout(in.files$(0)) : cendl()
  cout("   ")

  Local pretty_print% = opt.pretty_print%() Or opt.process_directives%()
  Local trok%
  t = Timer
  Do
    cout(BS$ + Mid$("\|/-", ((in.line_num(in.num_open_files% - 1) \ 8) Mod 4) + 1, 1))

    s$ = in.readln$()
    trok% = 0
    If lx.parse_basic%(s$) = sys.SUCCESS Then
      If opt.format_only Then
        trok% = Choice(opt.comments = 0, tr.remove_comments%(), 1)
      ElseIf opt.include_only Then
        trok% = tr.transpile_includes%()
      Else
        trok% = tr.transpile%()
      EndIf
    EndIf

    Select Case trok%
      Case sys.FAILURE:     cerror(sys.err$)
      Case sys.SUCCESS:     pp.print_line(pretty_print%)
      Case tr.INCLUDE_FILE: open_include() : pp.print_line(pretty_print%)
      Case tr.OMIT_LINE:    ' Do nothing
      Case Else:            Error "Unknown status: " + Str(trok%)
    End Select

    If Eof(#in.num_open_files%) Then
      If in.num_open_files% > 1 Then close_include() Else in.close()
      If sys.err$ <> "" Then cerror(sys.err$)
      cout(BS$ + " " + CR$ + Space$(1 + in.num_open_files% * 2))
    EndIf

  Loop Until in.num_open_files% = 0

  Print BS$ "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")

  out.close()

End Sub

Sub open_include()
  Local s$ = "' BEGIN: #Include "
  Cat s$, lx.line$
  If Len(s$) < 79 Then Cat s$, " "
  Do While Len(s$) < 80 : Cat s$, "-" : Loop
  If lx.parse_basic%(s$) = sys.SUCCESS Then
    If in.open%(tr.include$) = sys.SUCCESS Then
      Local i = in.num_open_files%
      cout(CR$ + Space$((i - 1) * 2) + in.files$(i - 1)) : cendl()
      cout(" " + Space$(i * 2))
    Else
      cerror(sys.err$)
    EndIf
  EndIf
End Sub

Sub close_include()
  Local s$ = "' END:   #Include "
  Cat s$, str.quote$(in.files$(in.num_open_files% - 1))
  If Len(s$) < 79 Then Cat s$, " "
  Do While Len(s$) < 80 : Cat s$, "-" : Loop
  If lx.parse_basic%(s$) = sys.SUCCESS Then pp.print_line(1)
  If sys.err$ = "" Then in.close()
End Sub

main()
End
