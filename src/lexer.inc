' Copyright (c) 2020 Thomas Hugo Williams

'!comment_if INLINE_CONSTANTS
Const TK_IDENTIFIER = 1
Const TK_NUMBER = 2
Const TK_COMMENT = 3
Const TK_STRING = 4
Const TK_KEYWORD = 5
Const TK_SYMBOL = 6
Const TK_DIRECTIVE = 7
Const TK_OPTION = 8
'!endif

Const LX_MAX_KEYWORDS = 1000
Dim lx_keywords$(LX_MAX_KEYWORDS - 1) Length 20
Dim lx_keywords_sz = 0
set_init(lx_keywords$(), LX_MAX_KEYWORDS)

Const LX_MAX_TOKENS = 100
Dim lx_type(LX_MAX_TOKENS - 1)
Dim lx_start(LX_MAX_TOKENS - 1)
Dim lx_len(LX_MAX_TOKENS - 1)

Dim lx_char$
Dim lx_line$
Dim lx_next_char$
Dim lx_num
Dim lx_pos

Sub lx_load_keywords(f$)
  Local i, s$

  Open f$ For Input As #1

  Do
    Line Input #1, s$
    If Len(s$) > 0 And Left$(s$, 1) <> "'" Then
      set_put(lx_keywords$(), lx_keywords_sz, LCase$(s$))
    EndIf
  Loop While Not Eof(#1)

  Close #1
End Sub

Sub lx_parse_basic(line$)
  lx_reset_globals(line$)
  lx_advance()

  Do While lx_char$ <> Chr$(10)
    If lx_char$ = " " Then
      lx_advance()
    ElseIf InStr("&.0123456789", lx_char$) Then
      lx_parse_number()
    ElseIf lx_char$ = "'" Then
      lx_parse_comment_or_directive()
    ElseIf lx_char$ = Chr$(34) Then
      lx_parse_string()
    ElseIf InStr("@#_abcdefghijklmnopqrstuvwxyz", lx_char$) Then
      lx_parse_keyword()
    Else
      lx_parse_symbol()
    EndIf

    If err$ <> "" Then Exit Do
  Loop
End Sub

Sub lx_reset_globals(line$)
  ' Clear old token data
  Do While lx_num > 0
    lx_num = lx_num - 1
    lx_type(lx_num) = 0
    lx_start(lx_num) = 0
    lx_len(lx_num) = 0
  Loop

  err$ = ""
  lx_line$ = line$
  lx_next_char$ = ""
  lx_pos = 0
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

Sub lx_parse_number()
  If InStr(".0123456789", lx_char$) Then
    lx_parse_decimal()
  ElseIf lx_char$ = "&" Then
    If lx_next_char$ = "b"  Then
      lx_parse_binary()
    ElseIf lx_next_char$ = "h" Then
      lx_parse_hexadecimal()
    ElseIf lx_next_char$ = "o" Then
      lx_parse_octal()
    Else
      Then err$ = "Unknown literal type &" + lx_next_char$ : Exit Sub
    EndIf
  EndIf
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

  lx_store(TK_NUMBER, start, lx_pos - start)
End Sub

Sub lx_store(type, start, length)
  If length = 0 Then Error "Empty token"
  lx_type(lx_num) = type
  lx_start(lx_num) = start
  lx_len(lx_num) = length
  lx_num = lx_num + 1
End Sub

Sub lx_advance_while(allowed$)
  Do While InStr(allowed$, lx_char$) > 0 : lx_advance() : Loop
End Sub

Sub lx_parse_binary()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("01")
  lx_store(TK_NUMBER, start, lx_pos - start)
End Sub

Sub lx_parse_hexadecimal()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("0123456789abcdefABCDEF")
  lx_store(TK_NUMBER, start, lx_pos - start)
End Sub

Sub lx_parse_octal()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("01234567")
  lx_store(TK_NUMBER, start, lx_pos - start)
End Sub

Sub lx_parse_comment_or_directive()
  If lx_next_char$ = "!" Then
    lx_parse_directive()
  Else
    lx_parse_comment()
  EndIf
End Sub

Sub lx_parse_directive()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("-_abcdefghijklmnopqrstuvwxyz0123456789")
  lx_store(TK_DIRECTIVE, start, lx_pos - start)
End Sub

Sub lx_parse_comment()
  lx_store(TK_COMMENT, lx_pos, Len(lx_line$) - lx_pos + 1)
  lx_char$ = Chr$(10)
End Sub

Sub lx_parse_string()
  Local start = lx_pos

  lx_advance()
  lx_advance_until(Chr$(10) + Chr$(34))
  If lx_char$ = Chr$(10) Then err$ = "No closing quote" : Exit Sub
  lx_store(TK_STRING, start, lx_pos - start + 1)
  lx_advance()
End Sub

Sub lx_advance_until(disallowed$)
  Do While Not InStr(disallowed$, lx_char$) > 0 : lx_advance() : Loop
End Sub

Sub lx_parse_keyword()
  Local start = lx_pos

  lx_advance()
  lx_advance_while("._abcdefghijklmnopqrstuvwxyz0123456789")
  If lx_char$ = "$" Then lx_advance()
  If lx_is_keyword(Mid$(lx_line$, start, lx_pos - start)) Then
    lx_store(TK_KEYWORD, start, lx_pos - start)
  Else
    lx_store(TK_IDENTIFIER, start, lx_pos - start)
  EndIf
End Sub

Function lx_is_keyword(t$)
  lx_is_keyword = set_get(lx_keywords$(), lx_keywords_sz, LCase$(t$)) > -1
End Function

Sub lx_parse_symbol()
  Local start = lx_pos

  If lx_char$ <> "<" And lx_char$ <> ">" And lx_char$ <> "=" Then
    lx_store(TK_SYMBOL, start, 1)
    lx_advance()
  Else
    lx_advance()
    If lx_char$ = "<" Or lx_char$ = ">" Or lx_char$ = "=" Then
      lx_store(TK_SYMBOL, start, 2)
      lx_advance()
    Else
      lx_store(TK_SYMBOL, start, 1)
    EndIf
  EndIf
End Sub

' Gets the text of token 'i'.
'
' If i > the number of tokens then returns the empty string.
Function lx_token$(i)
  If i < lx_num And lx_len(i) > 0 Then
    lx_token$ = Mid$(lx_line$, lx_start(i), lx_len(i))
  EndIf
End Function

' Gets the lower-case text of token 'i'.
'
' If i > the number of tokens then returns the empty string.
Function lx_token_lc$(i)
  lx_token_lc$ = LCase$(lx_token$(i))
End Function

' Gets the directive corresponding to token 'i' without the leading single quote.
'
' Throws an Error if token 'i' is not a directive.
Function lx_directive$(i)
  If lx_type(i) <> TK_DIRECTIVE Then Error "{" + lx_token$(i) + "} is not a directive"
  lx_directive$ = Mid$(lx_line$, lx_start(i) + 1, lx_len(i) - 1)
End Function

' Gets the string corresponding to token 'i' without the surrounding quotes.
'
' Throws an Error if token 'i' is not a string literal.
Function lx_string$(i)
  If lx_type(i) <> TK_STRING Then Error "{" + lx_token$(i) + "} is not a string literal"
  lx_string$ = Mid$(lx_line$, lx_start(i) + 1, lx_len(i) - 2)
End Function

' Gets the number corresponding to token 'i'.
'
' Throws an Error if token 'i' is not a number literal.
Function lx_number(i) As Float
  If lx_type(i) <> TK_NUMBER Then Error "{" + lx_token$(i) + "} is not a number literal"
  lx_number = Val(lx_token$(i))
End Function

' Performs simple space separator based tokenisation.
Sub lx_tokenise(line$)
  Local start = -1

  err$ = ""
  lx_line$ = line$
  lx_next_char$ = ""
  lx_num = 0
  lx_pos = 0
  lx_advance()

  Do While lx_char$ <> Chr$(10)
    If lx_char$ = " " Then
      If start > -1 Then
        lx_store(TK_IDENTIFIER, start, lx_pos - start)
        start = -1
      EndIf
    Else
      If start = -1 Then start = lx_pos
    EndIf
    lx_advance()
  Loop

  If start > -1 Then lx_store(TK_IDENTIFIER, start, lx_pos - start)
End Sub

Sub lx_parse_command_line(line$)
  lx_reset_globals(line$)
  lx_advance()

  Do While lx_char$ <> Chr$(10)
    If lx_char$ = " " Then
      lx_advance()
    ElseIf InStr("&.0123456789", lx_char$) Then
      lx_parse_number()
    ElseIf lx_char$ = "'" Then
      lx_parse_comment_or_directive()
    ElseIf lx_char$ = Chr$(34) Then
      lx_parse_string()
    ElseIf InStr("@#_abcdefghijklmnopqrstuvwxyz", lx_char$) Then
      lx_parse_keyword()
    ElseIf InStr("-/", lx_char$) Then
      lx_parse_option()
    Else
      lx_parse_symbol()
    EndIf

    If err$ <> "" Then Exit Do
  Loop
End Sub

Sub lx_parse_option()
  Local e = 0
  Local legal$ = "-_abcdefghijklmnopqrstuvwxyz0123456789"
  Local start = lx_pos

  If lx_char$ = "-" Then
    lx_advance()
    If lx_char$ = "-" Then lx_advance()
    If InStr(legal$, lx_char$) < 1 Then e = 1 Else lx_advance_while(legal$)
  ElseIf lx_char$ = "/" Then
    lx_advance()
    If InStr(legal$, lx_char$) < 1 Then e = 1 Else lx_advance_while(legal$)
  Else
    Error ' this should never happen
  EndIf

  If e = 1 Or InStr("= " + Chr$(10), lx_char$) < 1 Then
    If InStr("= " + Chr$(10), lx_char$) < 1 Then lx_advance()
    err$ = "Illegal command-line option format: " + Mid$(lx_line$, start, lx_pos - start)
    Exit Sub
  EndIf

  lx_store(TK_OPTION, start, lx_pos - start)
End Sub

' Gets the command-line option corresponding to token 'i'.
'
' Throws an Error if token 'i' is not a command-line option.
Function lx_option$(i)
  If lx_type(i) <> TK_OPTION Then Error "{" + lx_token$(i) + "} is not a command-line option"
  If Mid$(lx_line$, lx_start(i), 2) = "--" Then
    lx_option$ = Mid$(lx_line$, lx_start(i) + 2, lx_len(i) - 2)
  Else
    lx_option$ = Mid$(lx_line$, lx_start(i) + 1, lx_len(i) - 1)
  EndIf
End Function
