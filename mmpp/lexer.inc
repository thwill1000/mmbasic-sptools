' Copyright (c) 2020 Thomas Hugo Williams

Const LX_IDENTIFIER = 0
Const LX_NUMBER = 1
Const LX_COMMENT = 2
Const LX_STRING = 3
Const LX_KEYWORD = 4
Const LX_SYMBOL = 5
Const LX_DIRECTIVE = 6

Dim LX_NUM_KEYWORDS = 0

Const LX_MAX_TOKENS = 50
Dim lx_type(LX_MAX_TOKENS - 1)
Dim lx_start(LX_MAX_TOKENS - 1)
Dim lx_len(LX_MAX_TOKENS - 1)

Const LX_NUM_DIRECTIVES = 8
Dim LX_DIRECTIVES$(LX_NUM_DIRECTIVES - 1)
LX_DIRECTIVES$(0) = "'!comment_if"
LX_DIRECTIVES$(1) = "'!uncomment_if"
LX_DIRECTIVES$(2) = "'!comment_if_not"
LX_DIRECTIVES$(3) = "'!uncomment_if_not"
LX_DIRECTIVES$(4) = "'!endif"
LX_DIRECTIVES$(5) = "'!enable"
LX_DIRECTIVES$(6) = "'!disable"
LX_DIRECTIVES$(7) = "'!replace"

Dim lx_char
Dim lx_error$
Dim lx_line$
Dim lx_next_char
Dim lx_num
Dim lx_pos

Sub lx_advance()
  lx_pos = lx_pos + 1
  If lx_pos > Len(lx_line$) Then
    lx_char = -1
  Else
    lx_char = Peek(Var lx_line$, lx_pos)
  EndIf
  EndIf
  If lx_pos + 1 > Len(lx_line$) Then
    lx_next_char = -1
  Else
    lx_next_char = Peek(Var lx_line$, lx_pos + 1)
  EndIf
End Sub

Sub lx_store(type, start, length)
  lx_type(lx_num) = type
  lx_start(lx_num) = start
  lx_len(lx_num) = length
  lx_num = lx_num + 1
End Sub

Function lx_get_token$(i)
  lx_get_token$ = Mid$(lx_line$, lx_start(i), lx_len(i))
End Function

Sub lx_init()
  Local count, s$

  Open "resources/keywords.txt" For Input As #1

  Do
    Line Input #1, s$
    If Len(s$) > 0 And Left$(s$, 1) <> "'" Then
      If LX_NUM_KEYWORDS = 0 Then
        LX_NUM_KEYWORDS = Val(s$)
        Dim LX_KEYWORDS$(LX_NUM_KEYWORDS - 1)
      Else
        LX_KEYWORDS$(count) = LCase$(s$)
        count = count + 1
      EndIf
    EndIf
  Loop While Not Eof(#1)
  
  Close #1
End Sub

Function lx_is_keyword(s$)
  Local i
  ' TODO: use binary chop
  For i = 0 To LX_NUM_KEYWORDS - 1
    If LCase$(s$) = LX_KEYWORDS$(i) Then lx_is_keyword = 1 : Exit Function
  Next i
End Function

Sub lx_parse_line(line$)
  Local i

  lx_error$ = ""
  lx_line$ = line$
  lx_num = 0
  lx_pos = 0
  lx_advance()
  Do While lx_char > -1
    If lx_char = 32 Then
      ' space
      lx_advance()
    ElseIf lx_is_digit(lx_char) Then
      lx_parse_number()
    ElseIf lx_char = 39 Then
      ' single-quote
      If lx_next_char = 33 Then
        ' exclamation mark
        lx_parse_directive()
      Else
        lx_parse_comment()
      EndIf
    ElseIf lx_char = 34 Then
      ' double-quote
      lx_parse_string()
    ElseIf lx_is_keyword_char(lx_char) Then
      lx_parse_keyword()
    Else
      lx_parse_symbol()
    EndIf
  Loop

End Sub

Sub lx_parse_number()
  Local start = lx_pos

  Do While lx_is_digit(lx_char) : lx_advance() : Loop

  If lx_char = Asc(".") Then
    lx_advance()
    Do While lx_is_digit(lx_char) : lx_advance() : Loop
  EndIf

  If lx_char = Asc("e") Or lx_char = Asc("E") Then
    lx_advance()
    Do While lx_is_digit(lx_char) : lx_advance() : Loop
  EndIf

  lx_store(LX_NUMBER, start, lx_pos - start)
End Sub

Sub lx_parse_comment()
  lx_store(LX_COMMENT, lx_pos, Len(lx_line$) - lx_pos + 1)
  lx_char = -1
End Sub

Sub lx_parse_string()
  Local start = lx_pos

  lx_advance()
  Do While lx_char <> -1 And lx_char <> 34 : lx_advance() : Loop

  lx_store(LX_STRING, start, lx_pos - start + 1)
  lx_advance()

End Sub

Sub lx_parse_keyword()
  Local start, t$

  start = lx_pos

  Do While lx_is_keyword_char(lx_char) : lx_advance() : Loop

  t$ = Mid$(lx_line$, start, lx_pos - start)
  If lx_is_keyword(t$) Then
    lx_store(LX_KEYWORD, start, lx_pos - start)
  Else
    lx_store(LX_IDENTIFIER, start, lx_pos - start)
  EndIf

End Sub

Sub lx_parse_directive()
  Local start

  start = lx_pos
  lx_advance()
  lx_advance()
  Do While lx_is_keyword_char(lx_char) : lx_advance() : Loop
  lx_store(LX_DIRECTIVE, start, lx_pos - start)
End Sub

Function lx_is_keyword_char(ch)
  lx_is_keyword_char = ch >= 65 And ch <= 90
  lx_is_keyword_char = lx_is_keyword_char Or (ch >=95 And ch <= 122)
  lx_is_keyword_char = lx_is_keyword_char Or (ch = 36) Or (ch = 35)
  lx_is_keyword_char = lx_is_keyword_char Or lx_is_digit(ch)
End Function

Function lx_is_digit(ch)
  lx_is_digit = ch >= 48 And ch <= 57
End Function

Sub lx_parse_symbol()
  Local start

  start = lx_pos
  If lx_char <> Asc("<") And lx_char <> Asc(">") And lx_char <> Asc("=") Then
    lx_store(LX_SYMBOL, start, 1)
    lx_advance()
  Else
    lx_advance()
    If lx_char = Asc("<") Or lx_char = Asc(">") Or lx_char = Asc("=") Then
      lx_store(LX_SYMBOL, start, 2)
      lx_advance()
    Else
      lx_store(LX_SYMBOL, start, 1)
    EndIf
  EndIf
End Sub
