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

Dim num_files = 0
' We ignore the 0'th element in these.
Dim file_stack$(MAX_NUM_FILES) Length 40
Dim cur_line_no(MAX_NUM_FILES)
Dim mbt_in$     ' input filepath
Dim mbt_out$    ' output filepath
Dim err$        ' global error message / flag

Sub open_file(f$)
  Local f2$, p

  cout(Chr$(13)) ' CR

  If num_files > 0 Then
    f2$ = fi_get_parent$(file_stack$(1)) + f$
  Else
    f2$ = f$
  EndIf

  If Not fi_exists(f2$) Then cerror("#Include file '" + f2$ + "' not found")
  cout(Space$(num_files * 2) + f2$) : cendl()
  num_files = num_files + 1
  Open f2$ For Input As #num_files
  file_stack$(num_files) = f2$
  cout(Space$(1 + num_files * 2))
End Sub

Sub close_file()
  Close #num_files
  num_files = num_files - 1
  cout(Chr$(8) + " " + Chr$(13) + Space$(1 + num_files * 2))
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
  Print
  Print "[" + file_stack$(num_files) + ":" + Str$(cur_line_no(num_files)) + "] Error: " + msg$
  End
End Sub

Function read_line$()
  Local s$
  Line Input #num_files, s$
  read_line$ = s$
  cur_line_no(num_files) = cur_line_no(num_files) + 1
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
    cout(Chr$(8) + Mid$("\|/-", ((cur_line_no(num_files) \ 8) Mod 4) + 1, 1))
    s$ = read_line$()
    If op_format_only Then
      lx_parse_basic(s$)
      If err$ <> "" Then cerror(err$)
    Else
      transpile(s$)
    EndIf
    pp_print_line()

    If Eof(#num_files) Then
      If num_files > 1 Then
        s$ = "' END:       #Include " + Chr$(34)
        s$ = s$ + file_stack$(num_files) + Chr$(34) + " "
        s$ = s$ + String$(80 - Len(s$), "-")
        transpile(s$)
        pp_print_line()
      EndIf
      close_file()
    EndIf

  Loop Until num_files = 0

  Print
  Print "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")

  pp_close()

End Sub

main()
End
