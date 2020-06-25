' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "lexer.inc"

Const VT100_RED = Chr$(27) + "[31m"
Const VT100_GREEN = Chr$(27) + "[32m"
Const VT100_YELLOW = Chr$(27) + "[33m"
Const VT100_BLUE = Chr$(27) + "[34m"
Const VT100_MAGENTA = Chr$(27) + "[35m"
Const VT100_CYAN = Chr$(27) + "[36m"
Const VT100_WHITE = Chr$(27) + "[37m"
Const VT100_RESET = Chr$(27) + "[0m"

Dim TK_COLOUR$(6)
TK_COLOUR$(LX_IDENTIFIER) = VT100_WHITE
TK_COLOUR$(LX_NUMBER) = VT100_GREEN
TK_COLOUR$(LX_COMMENT) = VT100_YELLOW
TK_COLOUR$(LX_STRING) = VT100_MAGENTA
TK_COLOUR$(LX_KEYWORD) = VT100_CYAN
TK_COLOUR$(LX_SYMBOL) = VT100_WHITE
TK_COLOUR$(LX_DIRECTIVE) = VT100_RED

Const MAX_NUM_FLAGS = 10
Const MAX_NUM_IFS = 10

Dim cur_file_num = 0
Dim open_files$(9) Length 40
Dim line_buffer_len = 0
Dim line_buffer$(9) Length 80
Dim out_file_num = 0
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

Sub add_line(line$)
  line_buffer$(line_buffer_len) = line$
  line_buffer_len = line_buffer_len + 1
End Sub

Function read_line$()
  Local s$
  If line_buffer_len = 0 Then
    Line Input #cur_file_num, s$
    read_line$ = s$
  Else
    line_buffer_len = line_buffer_len - 1
    read_line$ = line_buffer$(line_buffer_len)
  EndIf
End Function

Sub pretty_print()
  Local i, no_space, t$

  For i = 0 To lx_num - 1
    If i = 0 Then cout(Space$(lx_start(i) - 1))
    t$ = lx_get_token$(i)
    If t$ <> "" Then
'      cout(VT100_WHITE + "{")
      cattrib(TK_COLOUR$(lx_type(i)))
      cout(t$)
      If i < lx_num - 1 Then
        no_space = t$ = "("
        no_space = no_space Or lx_get_token$(i + 1) = "("
        no_space = no_space Or lx_get_token$(i + 1) = ")"
        no_space = no_space Or lx_get_token$(i + 1) = ","
        no_space = no_space Or lx_get_token$(i + 1) = ";"
        no_space = no_space And t$ <> "=" And t$ <> ","
        If Not no_space Then cout(" ")
      EndIf
      cattrib(VT100_RESET)
    EndIf
  Next i
  cendl()
End Sub

Sub cattrib(c$)
  If out_file_num = 0 Then cout(c$)
End Sub

Sub cout(s$)
  If out_file_num = 0 Then
    Print s$;
  Else
    Print #out_file_num, s$;
  EndIf
End Sub

Sub cendl()
  If out_file_num = 0 Then Print Else Print #out_file_num
End Sub

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
  t1$ = LCase$(lx_get_token$(1))

  If t0$ = "'!endif" Then
    num_comments = num_comments - pop_if()
    lx_parse_line("' PROCESSED: " + lx_line$)
  EndIf

  add_comments()

  If lx_type(0) <> LX_DIRECTIVE Then Exit Sub

  If t0$ = "#include" Then
    f$ = lx_get_token$(1)
    f$ = Mid$(f$, 2, Len(f$) - 2)
    open_file(f$)
    s$ = "' -------- BEGIN #Include " + Chr$(34) + f$ + Chr$(34) + " --------"
    add_line(s$)
    s$ = read_line$()
    lx_parse_line(s$)
  EndIf

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
  Local count, f$, s$

  Cls

  lx_init()

'  Print "** "; Mm.CmdLine$; " **"
  lx_parse_line(Mm.CmdLine$)
  f$ = lx_get_token$(0)
  If f$ = "" Then Error "No file specified at command-line"
  open_file(f$)

  f$ = lx_get_token$(1)
  If f$ <> "" Then
    out_file_num = 10
    Open f$ For Output As #out_file_num
  EndIf

  Do
    count = count + 1
    Print VT100_WHITE$ + Format$(count, "%-4g") + ": ";

    s$ = read_line$()
    lx_parse_line(s$)
    process_directives()
    pretty_print()

    If Eof(#cur_file_num) Then
      If cur_file_num > 1 Then
        s$ = "' -------- END #Include " + Chr$(34)
        s$ = s$ + open_files$(cur_file_num - 1) + Chr$(34) + " --------"
        add_line(s$)
      EndIf
      close_file()
    EndIf

  Loop Until cur_file_num = 0

  If out_file_num > 0 Then Close #out_file_num

End Sub

main()
End
