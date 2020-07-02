' Copyright (c) 2020 Thomas Hugo Williams

Const LX_IDENTIFIER = 0
Const LX_NUMBER = 1
Const LX_COMMENT = 2
Const LX_STRING = 3
Const LX_KEYWORD = 4
Const LX_SYMBOL = 5
Const LX_DIRECTIVE = 6

Const LX_MAX_KEYWORDS = 600
Dim lx_keywords$(LX_MAX_KEYWORDS- 1) Length 20
Dim lx_keywords_sz = 0

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
LX_DIRECTIVES$(5) = "'!set"
LX_DIRECTIVES$(6) = "'!clear"
LX_DIRECTIVES$(7) = "'!replace"

Dim lx_char$
Dim lx_error$
Dim lx_line$
Dim lx_next_char$
Dim lx_num
Dim lx_pos

' Adds a new keyword.
Sub lx_add_keyword(s$)
  lx_keywords$(lx_keywords_sz) = LCase$(s$)
  lx_keywords_sz = lx_keywords_sz + 1
  If lx_keywords_sz > 1 Then
    If lx_keywords$(lx_keywords_sz - 1) < lx_keywords$(lx_keywords_sz - 2) Then
      Sort lx_keywords$()
    EndIf
  EndIf
End Sub

' Clears the list of keywords.
Sub lx_keywords_clear()
  Local i

  For i = 0 To LX_MAX_KEYWORDS - 1
    lx_keywords$(i) = Chr$(&h7F) ' so empty elements are at the end when sorted
  Next i
End Sub

Sub lx_advance()
  lx_pos = lx_pos + 1
  If lx_next_char$ = "" Then
    If lx_pos > Len(lx_line$) Then
      lx_char$ = Chr$(10)
    Else
      lx_char$ = LCase$(Chr$(Peek(Var lx_line$, lx_pos)))
    EndIf
  Else
    lx_char$ = lx_next_char$
  EndIf
  If lx_pos + 1 > Len(lx_line$) Then
    lx_next_char$ = Chr$(10)
  Else
    lx_next_char$ = LCase$(Chr$(Peek(Var lx_line$, lx_pos + 1)))
  EndIf
End Sub

Sub lx_advance_while(allowed$)
  Do While InStr(allowed$, lx_char$) > 0 : lx_advance() : Loop
End Sub

Sub lx_advance_until(disallowed$)
  Do While Not InStr(disallowed$, lx_char$) > 0 : lx_advance() : Loop
End Sub

Sub lx_store(type, start, length)
  lx_type(lx_num) = type
  lx_start(lx_num) = start
  lx_len(lx_num) = length
  lx_num = lx_num + 1
End Sub

Function lx_get_token$(i)
  If i > lx_num - 1 Or lx_len(i) = 0 Then
    lx_get_token$ = ""
  Else
    lx_get_token$ = Mid$(lx_line$, lx_start(i), lx_len(i))
  EndIf
End Function

Sub lx_load_keywords()
  Local i, s$

  Open "/cmm/mmpp/resources/keywords.txt" For Input As #1

  Do
    Line Input #1, s$
    If Len(s$) > 0 And Left$(s$, 1) <> "'" Then
      lx_add_keyword(s$)
    EndIf
  Loop While Not Eof(#1)

  Close #1
End Sub

Function lx_is_keyword(t$)
  Local i, lb, s$, ub

  ' Binary search of lx_keywords$()
  lb = 0
  ub = lx_keywords_sz - 1
  s$ = LCase$(t$)
  Do
    i = (lb + ub) \ 2
    If s$ > lx_keywords$(i) Then
      lb = i + 1
    ElseIf s$ < lx_keywords$(i) Then
      ub = i - 1
    Else
      lx_is_keyword = 1 : Exit Function
    EndIf
  Loop Until ub < lb
End Function

' Performs simple space separator based tokenisation.
Sub lx_tokenise(line$)
  Local start = -1

  lx_error$ = ""
  lx_line$ = line$
  lx_next_char$ = ""
  lx_num = 0
  lx_pos = 0
  lx_advance()

  Do While lx_char$ <> Chr$(10)
    If lx_char$ = " " Then
      If start > -1 Then
        lx_store(LX_IDENTIFIER, start, lx_pos - start)
        start = -1
      EndIf
    Else
      If start = -1 Then start = lx_pos
    EndIf
    lx_advance()
  Loop

  If start > -1 Then lx_store(LX_IDENTIFIER, start, lx_pos - start)

End Sub

Sub lx_parse_line(line$)
  lx_error$ = ""
  lx_line$ = line$
  lx_next_char$ = ""
  lx_num = 0
  lx_pos = 0
  lx_advance()

  Do While lx_char$ <> Chr$(10)
    If lx_char$ = " " Then
      lx_advance()
    ElseIf InStr(".0123456789", lx_char$) Then
      lx_parse_decimal()
    ElseIf lx_char$ = "&" Then
      If lx_next_char$ = "b"  Then
        lx_parse_binary()
      ElseIf lx_next_char$ = "h" Then
        lx_parse_hexadecimal()
      ElseIf lx_next_char$ = "o" Then
        lx_parse_octal()
      Else
        Error
      EndIf
    ElseIf lx_char$ = "'" Then
      If lx_next_char$ = "!" Then
        lx_parse_directive()
      Else
        lx_parse_comment()
      EndIf
    ElseIf lx_char$ = Chr$(34) Then
      lx_parse_string()
    ElseIf InStr("@#_abcdefghijklmnopqrstuvwxyz", lx_char$) Then
      lx_parse_keyword()
    Else
      lx_parse_symbol()
    EndIf

    If lx_error$ <> "" Then Exit Do
  Loop

End Sub

Sub lx_parse_binary()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("01")
  lx_store(LX_NUMBER, start, lx_pos - start)
End Sub

Sub lx_parse_hexadecimal()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("0123456789abcdefABCDEF")
  lx_store(LX_NUMBER, start, lx_pos - start)
End Sub

Sub lx_parse_decimal()
  Local start = lx_pos

  lx_advance_while("0123456789")

  If lx_char$ = "." Then
    lx_advance()
    lx_advance_while("0123456789")
  EndIf

  If lx_char$ = "e" Then
    lx_advance()
    If lx_char$ = "-" Or lx_char$ = "+" Then lx_advance()
    lx_advance_while("0123456789")
  EndIf

  lx_store(LX_NUMBER, start, lx_pos - start)
End Sub

Sub lx_parse_octal()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("01234567")
  lx_store(LX_NUMBER, start, lx_pos - start)
End Sub

Sub lx_parse_comment()
  lx_store(LX_COMMENT, lx_pos, Len(lx_line$) - lx_pos + 1)
  lx_char$ = Chr$(10)
End Sub

Sub lx_parse_string()
  Local start = lx_pos

  lx_advance()
  lx_advance_until(Chr$(10) + Chr$(34))
  If lx_char$ = Chr$(10) Then lx_error$ = "No closing quote" : Exit Sub
  lx_store(LX_STRING, start, lx_pos - start + 1)
  lx_advance()
End Sub

Sub lx_parse_keyword()
  Local start = lx_pos

  lx_advance()
  lx_advance_while("._abcdefghijklmnopqrstuvwxyz0123456789")
  If lx_char$ = "$" Then lx_advance()
  If lx_is_keyword(Mid$(lx_line$, start, lx_pos - start)) Then
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
  lx_advance_while("_abcdefghijklmnopqrstuvwxyz0123456789")
  lx_store(LX_DIRECTIVE, start, lx_pos - start)
End Sub

Sub lx_parse_symbol()
  Local start

  start = lx_pos
  If lx_char$ <> "<" And lx_char$ <> ">" And lx_char$ <> "=" Then
    lx_store(LX_SYMBOL, start, 1)
    lx_advance()
  Else
    lx_advance()
    If lx_char$ = "<" Or lx_char$ = ">" Or lx_char$ = "=" Then
      lx_store(LX_SYMBOL, start, 2)
      lx_advance()
    Else
      lx_store(LX_SYMBOL, start, 1)
    EndIf
  EndIf
End Sub
