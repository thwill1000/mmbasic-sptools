' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Const INSTALL_DIR$ = "\mbt"
Const RESOURCES_DIR$ = INSTALL_DIR$ + "\resources"

#Include "lexer.inc"
#Include "options.inc"
#Include "pprint.inc"
#Include "trans.inc"
#Include "cmdline.inc"
#Include "../common/file.inc"
#Include "../common/list.inc"
#Include "../common/map.inc"
#Include "../common/set.inc"
#Include "../common/string.inc"

' Stack of open input source files.
Dim in_files$(MAX_NUM_FILES - 1)
Dim in_files_sz
list_init(in_files$(), MAX_NUM_FILES)

Dim cur_line_no(MAX_NUM_FILES)
Dim mbt_in$     ' input filepath
Dim mbt_out$    ' output filepath
Dim err$        ' global error message / flag

Sub open_file(f$)
  Local f2$, p

  cout(Chr$(13)) ' CR

  If in_files_sz > 0 Then
    If Not fi_is_absolute(f$) Then f2$ = fi_get_parent$(in_files$(0)) + "/"
  EndIf
  f2$ = f2$ + f$

  If Not fi_exists(f2$) Then cerror("#Include file '" + f2$ + "' not found")
  cout(Space$(in_files_sz * 2) + f2$) : cendl()
  list_push(in_files$(), in_files_sz, f2$)
  Open f2$ For Input As #in_files_sz
  cout(Space$(1 + in_files_sz * 2))
End Sub

Sub close_file()
  Close #in_files_sz
  Local s$ = list_pop$(in_files$(), in_files_sz)
  cout(Chr$(8) + " " + Chr$(13) + Space$(1 + in_files_sz * 2))
End Sub

Sub cendl()
  If pp_file_num = -1 Then Exit Sub
  Print
End Sub

Sub cout(s$)
  If pp_file_num = -1 Then Exit Sub
  Print s$;
End Sub

Sub cerror(msg$)
  Local i = in_files_sz - 1
  Print
  Print "[" + in_files$(i) + ":" + Str$(cur_line_no(i)) + "] Error: " + msg$
  End
End Sub

Function read_line$()
  Local s$
  Line Input #in_files_sz, s$
  read_line$ = s$
  Local i = in_files_sz - 1
  cur_line_no(i) = cur_line_no(i) + 1
End Function

Sub main()
  Local s$, t

  op_init()

  cl_parse(Mm.CmdLine$)
  If err$ <> "" Then Print "mbt: "; err$ : Print : cl_usage() : End

  If mbt_out$ <> "" Then
    If fi_exists(mbt_out$)) Then
      Print "mbt: file '" + mbt_out$ + "' already exists, please delete it first" : End
    EndIf
  EndIf

  Cls

  lx_load_keywords(RESOURCES_DIR$ + "\keywords.txt")

  pp_open(mbt_out$)
  cout("Transpiling from '" + mbt_in$ + "' to '" + mbt_out$ + "' ...") : cendl()
  open_file(mbt_in$)

  t = Timer
  Do
    cout(Chr$(8) + Mid$("\|/-", ((cur_line_no(in_files_sz - 1) \ 8) Mod 4) + 1, 1))
    s$ = read_line$()
    If op_format_only Then
      lx_parse_basic(s$)
      If err$ <> "" Then cerror(err$)
    Else
      transpile(s$)
    EndIf
    pp_print_line()

    If Eof(#in_files_sz) Then
      If in_files_sz > 1 Then
        s$ = "' END:       #Include " + Chr$(34)
        s$ = s$ + in_files$(in_files_sz - 1) + Chr$(34) + " "
        s$ = s$ + String$(80 - Len(s$), "-")
        transpile(s$)
        pp_print_line()
      EndIf
      close_file()
    EndIf

  Loop Until in_files_sz = 0

  Print
  Print "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")

  pp_close()

End Sub

main()
End
