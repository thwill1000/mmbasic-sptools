' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const BS$ = Chr$(8)
Const CR$ = Chr$(13)
Const QU$ = Chr$(34)

#Include "cmdline.inc"
#Include "process.inc"
#Include "options.inc"
#Include "treegen.inc"
#Include "../common/error.inc"
#Include "../common/file.inc"
#Include "../common/list.inc"
#Include "../common/map.inc"
#Include "../common/set.inc"
#Include "../common/sptools.inc"
#Include "../common/strings.inc"
#Include "../sptrans/input.inc"
#Include "../sptrans/lexer.inc"
#Include "../sptrans/output.inc"

Sub cendl()
  Print
End Sub

Sub cout(s$)
  Print s$;
End Sub

Sub cerror(msg$)
  Local i = in_files_sz - 1
  Print
  Print "[" + in_files$(i) + ":" + Str$(in_line_num(i)) + "] Error: " + msg$
  End
End Sub

Sub main()
  Local s$

  op_init()
  pr_init()

  cl_parse(Mm.CmdLine$)
  If err$ <> "" Then Print "spflow: "; err$ : Print : cl_usage() : End

  If op_outfile$ <> "" Then
    If fil.exists%(op_outfile$)) Then
      Line Input "Overwrite existing '" + op_outfile$ + "' [y|N] ? ", s$
      If LCase$(s$) <> "y" Then Print "CANCELLED" : End
      Print
    EndIf
  EndIf

  lx_load_keywords(SPT_RESOURCES_DIR$ + "/keywords.txt")

  out_open(op_outfile$)

  cout("Generating MMBasic flowgraph from '" + op_infile$ + "'")
  If op_outfile$ <> "" Then cout(" to '" + op_outfile$ + "'")
  cout(" ...")
  cendl()
  cendl()

  Local t = Timer
  Local pass
  For pass = 1 To 2
    Print "PASS" pass

    in_open(op_infile$)
    If err$ <> "" Then cerror(err$)
    cout(in_files$(0)) : cendl()
    cout("   ")

    Do
      cout(BS$ + Mid$("\|/-", ((in_line_num(in_files_sz - 1) \ 8) Mod 4) + 1, 1))

      s$ = in_readln$()
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
      lx_parse_basic(s$)
      If lx_token_lc$(0) = "#include" Then handle_include()
      If err$ <> "" Then cerror(err$)

      process(pass)
      If err$ <> "" Then cerror(err$)
skip:
      If Eof(#in_files_sz) Then handle_eof()
      If err$ <> "" Then cerror(err$)

    Loop Until in_files_sz = 0

    Print

    pass_completed(pass)
  Next pass

  treegen()

  If op_outfile$ = "" Then Print
  Print "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")

  out_close()

End Sub

Sub handle_include()
  If err$ <> "" Then Exit Sub
  If lx_num < 2 Or lx_type(1) <> TK_STRING Then err$ = "#Include expects a <file> argument"
  If lx_num > 2 Then err$ = "#Include has too many arguments"
  If err$ = "" Then in_open(lx_string$(1))
  If err$ = "" Then
    Local i = in_files_sz
    cout(CR$ + Space$((i - 1) * 2) + in_files$(i - 1)) : cendl()
    cout(" " + Space$(i * 2))
  EndIf
End Sub

Sub handle_eof()
  in_close()
  If err$ = "" Then cout(BS$ + " " + CR$ + Space$(1 + in_files_sz * 2))
End Sub

main()
End
