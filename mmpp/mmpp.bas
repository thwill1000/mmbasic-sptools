' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "lexer.inc"
#Include "pprint.inc"

Const MAX_NUM_FLAGS = 10
Const MAX_NUM_IFS = 10

Dim cur_file_num = 0
Dim open_files$(9) Length 40
Dim num_comments = 0
Dim flags$(MAX_NUM_FLAGS - 1)
Dim if_stack(MAX_NUM_IFS)
Dim num_ifs = 0

Sub open_file(f$)
  cur_file_num = cur_file_num + 1
'  Print "Opening '"; f$ ; "' ..."
  Open f$ For Input As #cur_file_num
  open_files$(cur_file_num - 1) = f$
End Sub

Sub close_file()
'  Print "Closing '"; open_files$(cur_file_num - 1); "'"
  Close #cur_file_num
  cur_file_num = cur_file_num - 1
End Sub

Function read_line$()
  Local s$
  Line Input #cur_file_num, s$
  read_line$ = s$
End Function

Sub add_comments()
  If num_comments > 0 Then
    lx_parse_line(String$(num_comments, "'") + lx_line$)
  ElseIf num_comments < 0 Then
    Local x = num_comments
    Do While x < 0 And lx_type(0) = LX_COMMENT
      lx_parse_line(Space$(lx_start(0)) + Right$(lx_line$, Len(lx_line$) - lx_start(0)))
      x = x + 1
    Loop
  EndIf
End Sub

Sub push_if(x)
  If num_ifs = MAX_NUM_IFS Then Error "Too many if directives"
  if_stack(num_ifs) = x
  num_ifs = num_ifs + 1
End Sub

Function pop_if()
  If num_ifs = 0 Then Error "If directive stack is empty"
  num_ifs = num_ifs - 1
  pop_if = if_stack(num_ifs)
End Function

Sub process_directives()
  Local f$, s$, t0$, t1$, x

  t0$ = LCase$(lx_get_token$(0))

  If t0$ = "'!endif" Then
    num_comments = num_comments - pop_if()
    lx_parse_line("' PROCESSED: " + lx_line$)
  EndIf

  add_comments()

  t0$ = LCase$(lx_get_token$(0))
  t1$ = LCase$(lx_get_token$(1))

  If t0$ = "#include" Then
    f$ = lx_get_token$(1)
    f$ = Mid$(f$, 2, Len(f$) - 2)
    open_file(f$)
    lx_parse_line("' -------- BEGIN " + lx_line$ + " --------")
  EndIf

  If lx_type(0) <> LX_DIRECTIVE Then Exit Sub

  If t0$ = "'!comment_if" Then
    x = get_flag(t1$)
    push_if(x)
    If x Then num_comments = num_comments + 1
  ElseIf t0$ = "'!uncomment_if" Then
    x = get_flag(t1$)
    push_if(x * -1)
    If x Then num_comments = num_comments - 1
  ElseIf t0$ = "'!comment_if_not" Then
    x = get_flag(t1$)
    push_if(1 - x)
    If Not x Then num_comments = num_comments + 1
  ElseIf t0$ = "'!uncomment_if_not" Then
    x = get_flag(t1$)
    push_if((1 - x) * -1)
    If Not x Then num_comments = num_comments - 1
  ElseIf t0$ = "'!set" Then
    set_flag(t1$)
  ElseIf t0$ = "'!clear" Then
    clear_flag(t1$)
  Else
    Error "Unknown directive: " + t0$
  EndIf

  lx_parse_line("' PROCESSED: " + lx_line$)
End Sub

Function get_flag(s$)
  Local i
  If s$ = "" Then Error "No flag specified"
  For i = 0 To MAX_NUM_FLAGS - 1
    If flags$(i) = s$ Then get_flag = 1 : Exit Function
  Next i
End Function

Sub set_flag(s$)
  Local i, j = -1
  If s$ = "" Then Error "No flag specified"
  For i = 0 To MAX_NUM_FLAGS - 1
    If j = -1 And flags$(i) = "" Then j = i
    If flags$(i) = s$ Then Exit Sub ' already set
  Next i
  If j = -1 Then Error "Too many flags"
  flags$(j) = s$
End Sub

Sub clear_flag(s$)
  Local i
  If s$ = "" Then Error "No flag specified"
  For i = 0 To MAX_NUM_FLAGS - 1
    If flags$(i) = s$ Then flags$(i) = "" : Exit Sub
  Next i
End Sub

Sub main()
  Local s$

  Cls

  lx_init()

'  Print "** "; Mm.CmdLine$; " **"
  lx_parse_line(Mm.CmdLine$)
  s$ = lx_get_token$(0)
  If s$ = "" Then Error "No file specified at command-line"
  open_file(s$)

  s$ = lx_get_token$(1)
  pp_open(s$, 1)

  Do
    If pp_file_num > -1 Then Print ".";

    s$ = read_line$()
    lx_parse_line(s$)
    process_directives()
    pp_print_line()

    If Eof(#cur_file_num) Then
      If cur_file_num > 1 Then
        s$ = "' -------- END #Include " + Chr$(34)
        s$ = s$ + open_files$(cur_file_num - 1) + Chr$(34) + " --------"
        lx_parse_line(s$)
        pp_print_line()
      EndIf
      close_file()
    EndIf

  Loop Until cur_file_num = 0

  pp_close()

End Sub

main()
End
