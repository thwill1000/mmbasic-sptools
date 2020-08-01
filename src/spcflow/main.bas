' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Const INSTALL_DIR$ = "\sptools"
Const RESOURCES_DIR$ = INSTALL_DIR$ + "\resources"
Const BS$ = Chr$(8)
Const CR$ = Chr$(13)
Const QU$ = Chr$(34)

#Include "cmdline.inc"
#Include "options.inc"
#Include "../common/error.inc"
#Include "../common/file.inc"
#Include "../common/list.inc"
#Include "../common/map.inc"
#Include "../common/set.inc"
#Include "../common/string.inc"
#Include "../sptrans/input.inc"
#Include "../sptrans/lexer.inc"
#Include "../sptrans/output.inc"

Sub cendl()
  If op_outfile$ <> "" Then Print
End Sub

Sub cout(s$)
  If op_outfile$ <> "" Then Print s$;
End Sub

Sub cerror(msg$)
  Local i = in_files_sz - 1
  Print
  Print "[" + in_files$(i) + ":" + Str$(cur_line_no(i)) + "] Error: " + msg$
  End
End Sub

Sub main()
  Local s$, t

  op_init()

  cl_parse(Mm.CmdLine$)
  If err$ <> "" Then Print "spcflow: "; err$ : Print : cl_usage() : End

  If op_outfile$ <> "" Then
    If fi_exists(op_outfile$)) Then
      Print "spcflow: file '" op_outfile$ "' already exists, please delete it first" : End
    EndIf
  EndIf

  Cls

  ' TODO: sort out dynamic determination of RESOURCES_DIR$
  '       and also look for file in current program directory.
  lx_load_keywords(RESOURCES_DIR$ + "\keywords.txt")

  out_open(op_outfile$)

  cout("Generating language flowgraph from '" + op_infile$ + "' to '" + op_outfile$ + "' ...")
  cendl()
  in_open(op_infile$)
  If err$ <> "" Then cerror(err$)
  cout(in_files$(0)) : cendl()
  cout("   ")

  t = Timer
  Do
    cout(BS$ + Mid$("\|/-", ((cur_line_no(in_files_sz - 1) \ 8) Mod 4) + 1, 1))

    s$ = in_readln$()
    lx_parse_basic(s$)
    If lx_token_lc$(0) = "#include" Then handle_include()
    If err$ <> "" Then cerror(err$)

    If Eof(#in_files_sz) Then handle_eof()
    If err$ <> "" Then cerror(err$)

  Loop Until in_files_sz = 0

  Print
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
