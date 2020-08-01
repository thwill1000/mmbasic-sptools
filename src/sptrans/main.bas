' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Const INSTALL_DIR$ = "\mbt"
Const RESOURCES_DIR$ = INSTALL_DIR$ + "\resources"
Const BS$ = Chr$(8)
Const CR$ = Chr$(13)
Const QU$ = Chr$(34)

#Include "input.inc"
#Include "lexer.inc"
#Include "options.inc"
#Include "output.inc"
#Include "pprint.inc"
#Include "trans.inc"
#Include "cmdline.inc"
#Include "../common/error.inc"
#Include "../common/file.inc"
#Include "../common/list.inc"
#Include "../common/map.inc"
#Include "../common/set.inc"
#Include "../common/string.inc"

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
  If err$ <> "" Then Print "mbt: "; err$ : Print : cl_usage() : End

  If op_outfile$ <> "" Then
    If fi_exists(op_outfile$)) Then
      Print "mbt: file '" op_outfile$ "' already exists, please delete it first" : End
    EndIf
    op_colour = 0
  EndIf

  Cls

  lx_load_keywords(RESOURCES_DIR$ + "\keywords.txt")

  out_open(op_outfile$)

  If Not op_format_only Then
    If op_colour Then out_print(TK_COLOUR$(TK_COMMENT))
    out_print("' Transpiled on " + DateTime$(Now))
    If op_colour Then out_print(VT100_RESET)
    out_endl()
    out_endl()
  EndIf

  cout("Transpiling from '" + op_infile$ + "' to '" + op_outfile$ + "' ...") : cendl()
  in_open(op_infile$)
  If err$ <> "" Then cerror(err$)
  cout(in_files$(0)) : cendl()
  cout("   ")

  t = Timer
  Do
    cout(BS$ + Mid$("\|/-", ((cur_line_no(in_files_sz - 1) \ 8) Mod 4) + 1, 1))

    s$ = in_readln$()
    lx_parse_basic(s$)
    If err$ = "" Then
      If Not op_format_only Then transpile()
      If tr_include$ <> "" Then open_include()
    EndIf
    If err$ <> "" Then cerror(err$)

    pp_print_line()

    If Eof(#in_files_sz) Then
      If in_files_sz > 1 Then close_include() Else in_close()
      If err$ <> "" Then cerror(err$)
      cout(BS$ + " " + CR$ + Space$(1 + in_files_sz * 2))
    EndIf

  Loop Until in_files_sz = 0

  Print
  Print "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")

  out_close()

End Sub

Sub open_include()
  Local s$ = lx_line$
  s$ = "' BEGIN:     " + s$ + " " + String$(66 - Len(s$), "-")
  lx_parse_basic(s$)
  If err$ = "" Then in_open(tr_include$)
  If err$ = "" Then
    Local i = in_files_sz
    cout(CR$ + Space$((i - 1) * 2) + in_files$(i - 1)) : cendl()
    cout(" " + Space$(i * 2))
  EndIf
End Sub

Sub close_include()
  Local s$ = "#Include " + QU$ + in_files$(in_files_sz - 1) + QU$
  s$ = "' END:       " + s$ + " " + String$(66 - Len(s$), "-")
  lx_parse_basic(s$)
  If err$ = "" Then pp_print_line()
  If err$ = "" Then in_close()
End Sub

main()
End
