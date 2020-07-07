' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "lexer.inc"
#Include "replace.inc"
#Include "pprint.inc"

Const MAX_NUM_FILES = 5
Const MAX_NUM_FLAGS = 10
Const MAX_NUM_IFS = 10

Dim num_files = 0

' We just ignore the 0'th element in all of these.
Dim file_stack$(MAX_NUM_FILES) Length 40
Dim cur_line_no(MAX_NUM_FILES)
Dim num_comments(MAX_NUM_FILES)
Dim num_ifs(MAX_NUM_FILES)
Dim if_stack(MAX_NUM_FILES, MAX_NUM_IFS)
Dim flags$(MAX_NUM_FLAGS)

Sub open_file(f$)
  Local f2$, p

  If num_files > 0 Then
    f2$ = get_parent$(file_stack$(1)) + f$
  Else
    f2$ = f$
  EndIf
  Print : Print f2$;
  If Not fi_exists(f2$) Then report_error("#Include file '" + f2$ + "' not found")
  num_files = num_files + 1
  Open f2$ For Input As #num_files
  file_stack$(num_files) = f2$
End Sub

Function get_parent$(f$)
  Local ch$, p

  p = Len(f$)
  Do
    ch$ = Chr$(Peek(Var f$, p))
    If (ch$ = "/") Or (ch$ = "\") Then Exit Do
    p = p - 1
  Loop Until p = 0

  If p > 0 Then get_parent$ = Left$(f$, p)
End Function

Function fi_exists(f$)
  Local s$
  s$ = Dir$(f$, File)
  If s$ = "" Then s$ = Dir$(f$, Dir)
  fi_exists = s$ <> ""
End Function

Sub report_error(msg$)
  Print "["; file_stack$(num_files); ","; cur_line_no(num_files); "] Error: " + msg$
  End
End Sub

Sub close_file()
  Close #num_files
  num_files = num_files - 1
End Sub

Function read_line$()
  Local s$
  Line Input #num_files, s$
  read_line$ = s$
  cur_line_no(num_files) = cur_line_no(num_files) + 1
End Function

Sub add_comments()
  Local nc = num_comments(num_files)
  If nc > 0 Then
    parse_line(String$(nc, "'") + lx_line$)
  ElseIf nc < 0 Then
    Do While nc < 0 And lx_num > 0 And lx_type(0) = LX_COMMENT
      parse_line(Space$(lx_start(0)) + Right$(lx_line$, Len(lx_line$) - lx_start(0)))
      nc = nc + 1
    Loop
  EndIf
End Sub

Sub push_if(x)
  If num_ifs(num_files) = MAX_NUM_IFS Then Error "Too many if directives"
  num_ifs(num_files) = num_ifs(num_files) + 1
  if_stack(num_files, num_ifs(num_files)) = x
End Sub

Function pop_if()
  If num_ifs(num_files) = 0 Then Error "If directive stack is empty"
  pop_if = if_stack(num_files, num_ifs(num_files))
  num_ifs(num_files) = num_ifs(num_files) - 1
End Function

Sub process_directives()
  Local f$, s$, t0$, t1$, x

  t0$ = LCase$(lx_get_token$(0))

  If t0$ = "'!endif" Then
    update_num_comments(- pop_if())
    parse_line("' PROCESSED: " + lx_line$)
  EndIf

  add_comments()

  t0$ = LCase$(lx_get_token$(0))
  t1$ = LCase$(lx_get_token$(1))

  If t0$ = "#include" Then
    f$ = lx_get_token$(1)
    f$ = Mid$(f$, 2, Len(f$) - 2)
    open_file(f$)
    parse_line("' -------- BEGIN " + lx_line$ + " --------")
  EndIf

  If lx_type(0) <> LX_DIRECTIVE Then Exit Sub

  If t0$ = "'!comment_if" Then
    x = get_flag(t1$)
    push_if(x)
    If x Then update_num_comments(+1)
  ElseIf t0$ = "'!uncomment_if" Then
    x = get_flag(t1$)
    push_if(x * -1)
    If x Then update_num_comments(-1)
  ElseIf t0$ = "'!comment_if_not" Then
    x = get_flag(t1$)
    push_if(1 - x)
    If Not x Then update_num_comments(+1)
  ElseIf t0$ = "'!uncomment_if_not" Then
    x = get_flag(t1$)
    push_if((1 - x) * -1)
    If Not x Then update_num_comments(-1)
  ElseIf t0$ = "'!set" Then
    set_flag(t1$)
  ElseIf t0$ = "'!clear" Then
    clear_flag(t1$)
  ElseIf t0$ = "'!replace" Then
    If lx_num <> 3 Then Error "Syntax error: !replace requires 2 parameters"
    rp_add(lx_get_token$(1), lx_get_token$(2))
  Else
    Error "Unknown directive: " + t0$
  EndIf

  parse_line("' PROCESSED: " + lx_line$)
End Sub

Sub update_num_comments(x)
  num_comments(num_files) = num_comments(num_files) + x
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

Sub parse_line(s$)
  lx_parse_line(s$)
  rp_apply()
End Sub

Sub main()
  Local s$, t

  Cls

  lx_load_keywords()

  lx_parse_line(Mm.CmdLine$)
  s$ = lx_get_string$(0)

  If s$ = "" Then Error "No file specified at command-line"
  open_file(s$)

  If lx_num > 1 Then s$ = lx_get_string$(1) Else s$ = ""
  pp_open(s$, 0)

  t = Timer
  Do
    If pp_file_num > -1 Then Print ".";

    s$ = read_line$()
    parse_line(s$)
    If lx_error$ <> "" Then report_error(lx_error$)
    process_directives()
    pp_print_line()

    If Eof(#num_files) Then
      If num_files > 1 Then
        s$ = "' -------- END #Include " + Chr$(34)
        s$ = s$ + file_stack$(num_files) + Chr$(34) + " --------"
        parse_line(s$)
        pp_print_line()
      EndIf
      close_file()
    EndIf

  Loop Until num_files = 0

  Print "Time taken ="; Timer - t; " ms"

  pp_close()

End Sub

main()
End
