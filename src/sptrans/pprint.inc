' Copyright (c) 2020 Thomas Hugo Williams

Const VT100_RED = Chr$(27) + "[31m"
Const VT100_GREEN = Chr$(27) + "[32m"
Const VT100_YELLOW = Chr$(27) + "[33m"
Const VT100_BLUE = Chr$(27) + "[34m"
Const VT100_MAGENTA = Chr$(27) + "[35m"
Const VT100_CYAN = Chr$(27) + "[36m"
Const VT100_WHITE = Chr$(27) + "[37m"
Const VT100_RESET = Chr$(27) + "[0m"

Dim TK_COLOUR$(7)
TK_COLOUR$(TK_IDENTIFIER) = VT100_WHITE
TK_COLOUR$(TK_NUMBER) = VT100_GREEN
TK_COLOUR$(TK_COMMENT) = VT100_YELLOW
TK_COLOUR$(TK_STRING) = VT100_MAGENTA
TK_COLOUR$(TK_KEYWORD) = VT100_CYAN
TK_COLOUR$(TK_SYMBOL) = VT100_WHITE
TK_COLOUR$(TK_DIRECTIVE) = VT100_RED

Dim pp_count
Dim pp_previous = 0 ' 0 : previous line was empty
                    ' 1 : previous line was comment
                    ' 2 : previous line had content
Dim pp_file_num = -1
Dim pp_indent_lvl

Sub pp_open(f$)
  If f$ <> "" Then
    pp_file_num = 10
    Open f$ For Output As #pp_file_num
  EndIf

  If op_format_only = 0 Then
    pp_inc_line()
    pp_attrib(TK_COLOUR$(TK_COMMENT))
    pp_out("' Transpiled on " + DateTime$(Now)) : pp_endl()
    pp_attrib(VT100_RESET)
    pp_inc_line()
    pp_endl()
  EndIf
End Sub

Sub pp_close()
  If pp_file_num > -1 Then Close #pp_file_num
End Sub

Sub pp_inc_line()
  pp_count = pp_count + 1
  If pp_file_num = -1 Then
    pp_attrib(VT100_WHITE)
    pp_out(Format$(pp_count, "%-4g") + ": ")
  EndIf
End Sub

Sub pp_print_line()
  Local i, t$, u$

  ' Ignore empty lines if the 'empty-lines' option is set or the previous line
  ' was empty.
  If (op_empty_lines > -1 Or pp_previous = 0) And lx_num = 0 Then Exit Sub

  ' Ignore lines consisting solely of a comment if the 'comments' option is 0.
  If op_comments = 0 Then
    If lx_num = 1 Then
      If lx_type(0) = TK_COMMENT Then Exit Sub
    EndIf
  EndIf

  pp_inc_line()

  ' Nothing more to do for empty lines.
  If lx_num = 0 Then pp_previous = 0 : pp_endl() : Exit Sub

  For i = 0 To lx_num - 1

    ' If we are not including comments and we reach a comment then don't process
    ' any further tokens ... there shouldn't be any.
    If op_comments = 0 Then
      If i = lx_num - 1 Then
        If lx_type(i) = TK_COMMENT Then Exit For
      EndIf
    EndIf

    t$ = " " + lx_token_lc$(i) + " "

    ' If the 'empty-lines' option is 'single|1' and previous printed line
    ' had content and the line starts with {Function|Sub} then print empty line.
    If op_empty_lines = 1 And pp_previous = 2 Then
      If i = 0 And Instr(" sub function ", t$) > 0 Then pp_endl() : pp_inc_line()
    EndIf

    ' Tokens requiring us to decrease the indent level before printing them.
    If Instr(" end ", t$) Then
      If Instr(" select sub function ", " " + lx_token_lc$(i + 1) + " ") Then
        pp_indent_lvl = pp_indent_lvl - 1
        If lx_token_lc$(i + 1) = "select" Then pp_indent_lvl = pp_indent_lvl - 1
      EndIf
    ElseIf Instr(" case else elseif endif loop next exit ", t$) > 0 Then
      pp_indent_lvl = pp_indent_lvl - 1
    EndIf

    ' Indent the first token.
    If i = 0 Then
      If op_indent_sz = -1 Then
        ' Use existing indentation.
        pp_out(Space$(lx_start(0) - 1))
      ElseIf pp_indent_lvl > 0 Then
        ' Use automatic indentation.
        pp_out(Space$(pp_indent_lvl * op_indent_sz))
      EndIf
    EndIf

    ' Output the token with a trailing space where required.
    pp_attrib(TK_COLOUR$(lx_type(i)))
    pp_out(lx_token$(i) + Space$(pp_num_spaces(i)))

    ' Tokens requiring us to increase the indent level after printing them.
    If t$ = " do " Then
      pp_indent_lvl = pp_indent_lvl + 1

    ElseIf t$ = " for " Then
      u$ = " " + lx_token_lc$(i + 1) + " "
      If Instr(" input output random ", u$) <= 0 Then pp_indent_lvl = pp_indent_lvl + 1

    ElseIf t$ = " else " Then
      u$ = lx_token_lc$(i + 1)
      If u$ <> "if" Then pp_indent_lvl = pp_indent_lvl + 1

    ElseIf Instr(" case function select sub ", t$) Then
      If i = 0 Then
        pp_indent_lvl = pp_indent_lvl + 1
      Else If lx_token_lc$(i - 1) <> "end" Then
        pp_indent_lvl = pp_indent_lvl + 1
        If Instr(" case ", t$) Then pp_indent_lvl = pp_indent_lvl + 1
      EndIf

    ElseIf t$ = " then " Then
      u$ = lx_token_lc$(i + 1)
      If u$ = "" Or Left$(u$, 1) = "'" Then pp_indent_lvl = pp_indent_lvl + 1

    EndIf

  Next i

  pp_attrib(VT100_RESET)
  pp_endl()
  If lx_type(0) = TK_COMMENT Then pp_previous = 1 Else pp_previous = 2

  ' If the 'empty-lines' option is 'single|1' and the line ends with
  ' End {Function|Sub} then print one.
  If op_empty_lines = 1 Then
    If Instr(" function sub ", t$) > 0 Then
      u$ = lx_token_lc$(lx_num - 2)
      If u$ = "end" Then pp_inc_line() : pp_endl() : pp_previous = 0
    EndIf
  EndIf

  ' "Fix" the indent level if it goes badly wrong.
  If pp_indent_lvl < 0 Then pp_indent_lvl = 0

End Sub

' How many spaces should follow token 'i' ?
Function pp_num_spaces(i)

  ' Never need a space after the last token.
  If i >= lx_num - 1 Then Exit Function

  If op_spacing = -1 Then
    ' Maintain existing spaces.
    pp_num_spaces = lx_start(i + 1) - lx_start(i) - lx_len(i)
    Exit Function
  EndIf

  Local t$ = lx_token$(i)
  Local u$ = lx_token$(i + 1)

  ' Never need a space before a comma, semi-colon or closing bracket.
  If InStr(",;)", u$) Then Exit Function

  ' Never need a space after an opening bracket.
  If t$ = "(" Then Exit Function

  ' Rules applying to 'generous' spacing.
  If op_spacing >= 2 Then
    ' Don't need a space before an opening bracket
    ' unless it is preceeded by a symbol.
    If u$ = "(" Then
      If lx_type(i) <> TK_SYMBOL Then Exit Function
    EndIf

    ' Don't need a space after +/- if preceeded by equals.
    If InStr("+-", t$) Then
      If lx_num > 1 Then
        If lx_token$(i - 1) = "=" Then Exit Function
      EndIf
    EndIf

    ' Need a space before/after any symbol.
    If lx_type(i) = TK_SYMBOL Then pp_num_spaces = 1 : Exit Function
    If lx_type(i + 1) = TK_SYMBOL Then pp_num_spaces = 1 : Exit Function
  EndIf

  ' Rules applying to 'compact' spacing.
  If op_spacing >= 1 Then
    ' Need a space between a keyword/identifier and string.
    If lx_type(i) = TK_KEYWORD Or lx_type(i) = TK_IDENTIFIER Then
      If lx_type(i + 1) = TK_STRING Then pp_num_spaces = 1 : Exit Function
    EndIf

    ' Need a space before a comment.
    If lx_type(i + 1) = TK_COMMENT Then pp_num_spaces = 1 : Exit Function

    ' Need a space after a string unless followed by a symbol.
    If lx_type(i) = TK_STRING Then
      If lx_type(i + 1) <> TK_SYMBOL Then pp_num_spaces = 1 : Exit Function
    EndIf

    ' Space after a closing bracket unless followed by a symbol.
    If lx_token$(i) = ")" Then
      If lx_type(i + 1) <> TK_SYMBOL Then pp_num_spaces = 1 : Exit Function
    EndIf

    ' Need a space before or after a ':'
    If lx_token$(i) = ":" Then pp_num_spaces = 1 : Exit Function
    If lx_token$(i + 1) = ":" Then pp_num_spaces = 1 : Exit Function
  EndIf

  ' Rules applying to minimal spacing
  Select Case lx_type(i)
    Case TK_KEYWORD, TK_IDENTIFIER, TK_NUMBER, TK_DIRECTIVE
      Select Case lx_type(i + 1)
        Case TK_KEYWORD, TK_IDENTIFIER, TK_NUMBER
          pp_num_spaces = 1
      End Select
  End Select
End Function

Sub pp_attrib(c$)
  If pp_file_num < 0 And op_colour > 0 Then pp_out(c$)
End Sub

Sub pp_out(s$)
  If pp_file_num < 0 Then
    Print s$;
  Else
    Print #pp_file_num, s$;
  EndIf
End Sub

Sub pp_endl()
  If pp_file_num < 0 Then Print Else Print #pp_file_num
End Sub
