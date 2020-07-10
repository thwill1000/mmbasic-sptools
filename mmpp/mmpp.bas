' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5

#Include "lexer.inc"
#Include "map.inc"
#Include "pprint.inc"
#Include "set.inc"
#Include "trans.inc"

Dim num_files = 0
' We ignore the 0'th element in these.
Dim file_stack$(MAX_NUM_FILES) Length 40
Dim cur_line_no(MAX_NUM_FILES)

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

Function fi_get_parent$(f$)
  Local ch$, p

  p = Len(f$)
  Do
    ch$ = Chr$(Peek(Var f$, p))
    If (ch$ = "/") Or (ch$ = "\") Then Exit Do
    p = p - 1
  Loop Until p = 0

  If p > 0 Then fi_get_parent$ = Left$(f$, p)
End Function

Function fi_exists(f$)
  Local s$
  s$ = Dir$(f$, File)
  If s$ = "" Then s$ = Dir$(f$, Dir)
  fi_exists = s$ <> ""
End Function

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
  Local in$, out$, s$, t

  Cls

  lx_load_keywords()

  lx_parse_line(Mm.CmdLine$)
  If lx_num = 0 Then Error "No input filename specified"
  If lx_num > 0 Then
    If lx_type(0) <> TK_STRING Then Error "Input filename must be quoted"
    in$ = lx_string$(0)
  EndIf
  If lx_num > 1 Then
    If lx_type(1) <> TK_STRING Then Error "Output filename must be quoted"
    out$ = lx_string$(1)
  EndIf

  pp_open(out$, 0)
  cout("Transpiling from '" + in$ + "' to '" + out$ + "' ...") : cendl()
  open_file(in$)

  t = Timer
  Do
    cout(Chr$(8) + Mid$("\|/-", ((cur_line_no(num_files) \ 8) Mod 4) + 1, 1))
    s$ = read_line$()
    transpile(s$)
    pp_print_line()

    If Eof(#num_files) Then
      If num_files > 1 Then
        s$ = "' -------- END #Include " + Chr$(34)
        s$ = s$ + file_stack$(num_files) + Chr$(34) + " --------"
        transpile(s$)
        pp_print_line()
      EndIf
      close_file()
    EndIf

  Loop Until num_files = 0

  cout(Chr$(13) + "Time taken = " + Format$((Timer - t) / 1000, "%.1f s"))

  pp_close()

End Sub

main()
End
