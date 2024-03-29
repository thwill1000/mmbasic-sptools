#!/usr/local/bin/mmbasic -i

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
#Include "../common/sptools.inc"
#Include "../sptrans/input.inc"
#Include "../sptrans/keywords.inc"
#Include "../sptrans/lexer.inc"
#Include "../sptrans/output.inc"
#Include "options.inc"
#Include "cmdline.inc"
#Include "process.inc"
#Include "treegen.inc"

Sub cendl()
  Print
End Sub

Sub cout(s$)
  Print s$;
End Sub

Sub cerror(msg$)
  Local i = in.num_open_files% - 1
  Print
  Print "[" + in.files$(i) + ":" + Str$(in.line_num%(i)) + "] Error: " + msg$
  End
End Sub

Sub main()
  Local s$

  in.init()
  opt.init()
  pro.init()

  cli.parse(Mm.CmdLine$)
  If sys.err$ <> "" Then Print "spflow: " sys.err$ : Print : cli.usage() : End

  If Not file.exists%(opt.infile$)) Then
    Print "spflow: input file '" opt.infile$ "' not found."
    End
  EndIf

  If opt.outfile$ <> "" Then
    If file.exists%(opt.outfile$)) Then
      Line Input "Overwrite existing '" + opt.outfile$ + "' [y|N] ? ", s$
      If LCase$(s$) <> "y" Then Print "CANCELLED" : End
      Print
    EndIf
  EndIf

  keywords.init()

  out.open(opt.outfile$)

  cout("Generating MMBasic flowgraph from '" + opt.infile$ + "'")
  If opt.outfile$ <> "" Then cout(" to '" + opt.outfile$ + "'")
  cout(" ...")
  cendl()
  cendl()

  Local t = Timer
  Local pass
  For pass = 1 To 2
    Print "PASS" pass

    If in.open%(opt.infile$) <> sys.SUCCESS Then cerror(sys.err$)
    cout(in.files$(0)) : cendl()
    cout("   ")

    Do
      cout(BS$ + Mid$("\|/-", ((in.line_num%(in.num_open_files% - 1) \ 8) Mod 4) + 1, 1))

      s$ = in.readln$()
      If pass = 1 Then
        ' In pass 1 we are only interested in #include and the start and end of
        ' subroutine and function declarations.
        ' Note: the duplicated LCase$() calls incur no significant performance
        '       penalty.
        If InStr(LCase$(s$), "function") Then Goto process
        If InStr(LCase$(s$), "sub") Then Goto process
        If InStr(LCase$(s$), "#include") Then Goto process
        Goto skip
      EndIf
process:
      If lx.parse_basic%(s$) = sys.SUCCESS Then
        If lx.token_lc$(0) = "#include" Then handle_include()
      EndIf
      If sys.err$ <> "" Then cerror(sys.err$)

      process(pass)
      If sys.err$ <> "" Then cerror(sys.err$)
skip:
      If Eof(#in.num_open_files%) Then handle_eof()
      If sys.err$ <> "" Then cerror(sys.err$)

    Loop Until in.num_open_files% = 0

    Print

    pass_completed(pass)
  Next pass

  treegen()

  If opt.outfile$ = "" Then Print
  Print "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")

  out.close()

End Sub

Sub handle_include()
  If sys.err$ <> "" Then Exit Sub
  If lx.num < 2 Or lx.type(1) <> TK_STRING Then sys.err$ = "#Include expects a <file> argument"
  If lx.num > 2 Then sys.err$ = "#Include has too many arguments"
  If sys.err$ <> "" Then Exit Sub
  If in.open%(lx.string$(1)) = sys.SUCCESS Then
    Local i = in.num_open_files%
    cout(CR$ + Space$((i - 1) * 2) + in.files$(i - 1)) : cendl()
    cout(" " + Space$(i * 2))
  EndIf
End Sub

Sub handle_eof()
  in.close()
  If sys.err$ = "" Then cout(BS$ + " " + CR$ + Space$(1 + in.num_open_files% * 2))
End Sub

main()
End
