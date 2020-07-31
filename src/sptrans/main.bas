' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Const INSTALL_DIR$ = "\mbt"
Const RESOURCES_DIR$ = INSTALL_DIR$ + "\resources"

#Include "input.inc"
#Include "lexer.inc"
#Include "options.inc"
#Include "output.inc"
#Include "pprint.inc"
#Include "trans.inc"
#Include "cmdline.inc"
#Include "../common/file.inc"
#Include "../common/list.inc"
#Include "../common/map.inc"
#Include "../common/set.inc"
#Include "../common/string.inc"

Dim mbt_in$  ' input filepath
Dim mbt_out$ ' output filepath
Dim err$     ' global error message / flag

Sub cendl()
  If mbt_out$ = "" Then Exit Sub
  Print
End Sub

Sub cout(s$)
  If mbt_out$ = "" Then Exit Sub
  Print s$;
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
  If err$ <> "" Then Print "mbt: "; err$ : Print : cl_usage() : End

  If mbt_out$ <> "" Then
    If fi_exists(mbt_out$)) Then
      Print "mbt: file '" + mbt_out$ + "' already exists, please delete it first" : End
    EndIf
    op_colour = 0
  EndIf

  Cls

  lx_load_keywords(RESOURCES_DIR$ + "\keywords.txt")

  out_open(mbt_out$)

  If Not op_format_only Then
    If op_colour Then out_print(TK_COLOUR$(TK_COMMENT))
    out_print("' Transpiled on " + DateTime$(Now))
    If op_colour Then out_print(VT100_RESET)
    out_endl()
    out_endl()
  EndIf

  cout("Transpiling from '" + mbt_in$ + "' to '" + mbt_out$ + "' ...") : cendl()
  in_open(mbt_in$)
  If err$ <> "" Then cerror(err$)

  t = Timer
  Do
    cout(Chr$(8) + Mid$("\|/-", ((cur_line_no(in_files_sz - 1) \ 8) Mod 4) + 1, 1))
    s$ = in_readln$()
    If op_format_only Then
      lx_parse_basic(s$)
    Else
      transpile(s$)
    EndIf
    If err$ <> "" Then cerror(err$)
    pp_print_line()

    If Eof(#in_files_sz) Then
      If in_files_sz > 1 Then
        s$ = "' END:       #Include " + Chr$(34)
        s$ = s$ + in_files$(in_files_sz - 1) + Chr$(34) + " "
        s$ = s$ + String$(80 - Len(s$), "-")
        transpile(s$)
        If err$ <> "" Then cerror(err$)
        pp_print_line()
        If err$ <> "" Then cerror(err$)
      EndIf
      in_close()
      cout(Chr$(8) + " " + Chr$(13) + Space$(1 + in_files_sz * 2))
    EndIf

  Loop Until in_files_sz = 0

  Print
  Print "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")

  out_close()

End Sub

main()
End
