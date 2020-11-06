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

Dim lx.keywords$(set.new%(1000)) Length 20
set.init(lx.keywords$())

Const LX_MAX_TOKENS = 255 ' In theory every character may be a separate token.
Dim lx.type(LX_MAX_TOKENS - 1)
Dim lx.start(LX_MAX_TOKENS - 1)
Dim lx.len(LX_MAX_TOKENS - 1)

Dim lx.char$
Dim lx.line$
Dim lx.next_char$
Dim lx.num
Dim lx.pos

Sub lx.load_keywords(f$)
  Local i, s$

  Open f$ For Input As #1

  Do
    Line Input #1, s$
    If Len(s$) > 0 And Left$(s$, 1) <> "'" Then
      set.put(lx.keywords$(), LCase$(s$))
    EndIf
  Loop While Not Eof(#1)

  Close #1
End Sub

Sub lx.parse_basic(line$)
  lx.reset.globals(line$)
  lx.advance()

  Do While lx.char$ <> Chr$(10)
    If lx.char$ = " " Then
      lx.advance()
    ElseIf InStr("&.0123456789", lx.char$) Then
      lx.parse_number()
    ElseIf lx.char$ = "'" Then
      lx.parse_comment_or_directive()
    ElseIf lx.char$ = Chr$(34) Then
      lx.parse_string()
    ElseIf InStr("@#_abcdefghijklmnopqrstuvwxyz", lx.char$) Then
      lx.parse_keyword()
    Else
      lx.parse_symbol()
    EndIf

    If err$ <> "" Then Exit Do
  Loop
End Sub

Sub lx.reset.globals(line$)
  ' Clear old token data
  Do While lx.num > 0
    lx.num = lx.num - 1
    lx.type(lx.num) = 0
    lx.start(lx.num) = 0
    lx.len(lx.num) = 0
  Loop

  err$ = ""
  lx.line$ = line$
  lx.next_char$ = ""
  lx.pos = 0
End Sub

Sub lx.advance()
  lx.pos = lx.pos + 1
  If lx.next_char$ = "" Then
    If lx.pos > Len(lx.line$) Then
      lx.char$ = Chr$(10)
    Else
      lx.char$ = LCase$(Chr$(Peek(Var lx.line$, lx.pos)))
    EndIf
  Else
    lx.char$ = lx.next_char$
  EndIf
  If lx.pos + 1 > Len(lx.line$) Then
    lx.next_char$ = Chr$(10)
  Else
    lx.next_char$ = LCase$(Chr$(Peek(Var lx.line$, lx.pos + 1)))
  EndIf
End Sub

Sub lx.parse_number()
  If InStr(".0123456789", lx.char$) Then
    lx.parse_decimal()
  ElseIf lx.char$ = "&" Then
    If lx.next_char$ = "b"  Then
      lx.parse_binary()
    ElseIf lx.next_char$ = "h" Then
      lx.parse_hexadecimal()
    ElseIf lx.next_char$ = "o" Then
      lx.parse_octal()
    Else
      err$ = "Unknown literal type &" + lx.next_char$ : Exit Sub
    EndIf
  EndIf
End Sub

Sub lx.parse_decimal()
  Local start = lx.pos

  lx.advance_while("0123456789")

  If lx.char$ = "." Then
    lx.advance()
    lx.advance_while("0123456789")
  EndIf

  If lx.char$ = "e" Then
    lx.advance()
    If lx.char$ = "-" Or lx.char$ = "+" Then lx.advance()
    lx.advance_while("0123456789")
  EndIf

  lx.store(TK_NUMBER, start, lx.pos - start)
End Sub

Sub lx.store(type, start, length)
  If length = 0 Then Error "Empty token"
  lx.type(lx.num) = type
  lx.start(lx.num) = start
  lx.len(lx.num) = length
  lx.num = lx.num + 1
End Sub

Sub lx.advance_while(allowed$)
  Do While InStr(allowed$, lx.char$) > 0 : lx.advance() : Loop
End Sub

Sub lx.parse_binary()
  Local start = lx.pos

  lx.advance()
  lx.advance()
  lx.advance_while("01")
  lx.store(TK_NUMBER, start, lx.pos - start)
End Sub

Sub lx.parse_hexadecimal()
  Local start = lx.pos

  lx.advance()
  lx.advance()
  lx.advance_while("0123456789abcdefABCDEF")
  lx.store(TK_NUMBER, start, lx.pos - start)
End Sub

Sub lx.parse_octal()
  Local start = lx.pos

  lx.advance()
  lx.advance()
  lx.advance_while("01234567")
  lx.store(TK_NUMBER, start, lx.pos - start)
End Sub

Sub lx.parse_comment_or_directive()
  If lx.next_char$ = "!" Then
    lx.parse_directive()
  Else
    lx.parse_comment()
  EndIf
End Sub

Sub lx.parse_directive()
  Local start = lx.pos

  lx.advance()
  lx.advance()
  lx.advance_while("-_abcdefghijklmnopqrstuvwxyz0123456789")
  lx.store(TK_DIRECTIVE, start, lx.pos - start)
End Sub

Sub lx.parse_comment()
  lx.store(TK_COMMENT, lx.pos, Len(lx.line$) - lx.pos + 1)
  lx.char$ = Chr$(10)
End Sub

Sub lx.parse_string()
  Local start = lx.pos

  lx.advance()
  lx.advance_until(Chr$(10) + Chr$(34))
  If lx.char$ = Chr$(10) Then err$ = "No closing quote" : Exit Sub
  lx.store(TK_STRING, start, lx.pos - start + 1)
  lx.advance()
End Sub

Sub lx.advance_until(disallowed$)
  Do While Not InStr(disallowed$, lx.char$) > 0 : lx.advance() : Loop
End Sub

Sub lx.parse_keyword()
  Local start = lx.pos

  lx.advance()
  lx.advance_while("._abcdefghijklmnopqrstuvwxyz0123456789")
  If InStr("$!%", lx.char$) Then lx.advance()
  If lx.is_keyword(Mid$(lx.line$, start, lx.pos - start)) Then
    lx.store(TK_KEYWORD, start, lx.pos - start)
  Else
    lx.store(TK_IDENTIFIER, start, lx.pos - start)
  EndIf
End Sub

Function lx.is_keyword(t$)
  lx.is_keyword = set.get%(lx.keywords$(), LCase$(t$)) > -1
End Function

Sub lx.parse_symbol()
  Local start = lx.pos

  If lx.char$ <> "<" And lx.char$ <> ">" And lx.char$ <> "=" Then
    lx.store(TK_SYMBOL, start, 1)
    lx.advance()
  Else
    lx.advance()
    If lx.char$ = "<" Or lx.char$ = ">" Or lx.char$ = "=" Then
      lx.store(TK_SYMBOL, start, 2)
      lx.advance()
    Else
      lx.store(TK_SYMBOL, start, 1)
    EndIf
  EndIf
End Sub

' Gets the text of token 'i'.
'
' If i > the number of tokens then returns the empty string.
Function lx.token$(i)
  If i < lx.num And lx.len(i) > 0 Then
    lx.token$ = Mid$(lx.line$, lx.start(i), lx.len(i))
  EndIf
End Function

' Gets the lower-case text of token 'i'.
'
' If i > the number of tokens then returns the empty string.
Function lx.token_lc$(i)
  lx.token_lc$ = LCase$(lx.token$(i))
End Function

' Gets the directive corresponding to token 'i' without the leading single quote.
'
' Throws an Error if token 'i' is not a directive.
Function lx.directive$(i)
  If lx.type(i) <> TK_DIRECTIVE Then Error "{" + lx.token$(i) + "} is not a directive"
  lx.directive$ = Mid$(lx.line$, lx.start(i) + 1, lx.len(i) - 1)
End Function

' Gets the string corresponding to token 'i' without the surrounding quotes.
'
' Throws an Error if token 'i' is not a string literal.
Function lx.string$(i)
  If lx.type(i) <> TK_STRING Then Error "{" + lx.token$(i) + "} is not a string literal"
  lx.string$ = Mid$(lx.line$, lx.start(i) + 1, lx.len(i) - 2)
End Function

' Gets the number corresponding to token 'i'.
'
' Throws an Error if token 'i' is not a number literal.
Function lx.number(i) As Float
  If lx.type(i) <> TK_NUMBER Then Error "{" + lx.token$(i) + "} is not a number literal"
  lx.number = Val(lx.token$(i))
End Function

' Performs simple space separator based tokenisation.
Sub lx.tokenise(line$)
  Local start = -1

  err$ = ""
  lx.line$ = line$
  lx.next_char$ = ""
  lx.num = 0
  lx.pos = 0
  lx.advance()

  Do While lx.char$ <> Chr$(10)
    If lx.char$ = " " Then
      If start > -1 Then
        lx.store(TK_IDENTIFIER, start, lx.pos - start)
        start = -1
      EndIf
    Else
      If start = -1 Then start = lx.pos
    EndIf
    lx.advance()
  Loop

  If start > -1 Then lx.store(TK_IDENTIFIER, start, lx.pos - start)
End Sub

Sub lx.parse_command_line(line$)
  lx.reset.globals(line$)
  lx.advance()

  Do While lx.char$ <> Chr$(10)
    If lx.char$ = " " Then
      lx.advance()
    ElseIf InStr("&.0123456789", lx.char$) Then
      lx.parse_number()
    ElseIf lx.char$ = "'" Then
      lx.parse_comment_or_directive()
    ElseIf lx.char$ = Chr$(34) Then
      lx.parse_string()
    ElseIf InStr("@#_abcdefghijklmnopqrstuvwxyz", lx.char$) Then
      lx.parse_keyword()
    ElseIf InStr("-/", lx.char$) Then
      lx.parse_option()
    Else
      lx.parse_symbol()
    EndIf

    If err$ <> "" Then Exit Do
  Loop
End Sub

Sub lx.parse_option()
  Local e = 0
  Local legal$ = "-_abcdefghijklmnopqrstuvwxyz0123456789"
  Local start = lx.pos

  If lx.char$ = "-" Then
    lx.advance()
    If lx.char$ = "-" Then lx.advance()
    If InStr(legal$, lx.char$) < 1 Then e = 1 Else lx.advance_while(legal$)
  ElseIf lx.char$ = "/" Then
    lx.advance()
    If InStr(legal$, lx.char$) < 1 Then e = 1 Else lx.advance_while(legal$)
  Else
    Error ' this should never happen
  EndIf

  If e = 1 Or InStr("= " + Chr$(10), lx.char$) < 1 Then
    If InStr("= " + Chr$(10), lx.char$) < 1 Then lx.advance()
    err$ = "Illegal command-line option format: " + Mid$(lx.line$, start, lx.pos - start)
    Exit Sub
  EndIf

  lx.store(TK_OPTION, start, lx.pos - start)
End Sub

' Gets the command-line option corresponding to token 'i'.
'
' Throws an Error if token 'i' is not a command-line option.
Function lx.option$(i)
  If lx.type(i) <> TK_OPTION Then Error "{" + lx.token$(i) + "} is not a command-line option"
  If Mid$(lx.line$, lx.start(i), 2) = "--" Then
    lx.option$ = Mid$(lx.line$, lx.start(i) + 2, lx.len(i) - 2)
  Else
    lx.option$ = Mid$(lx.line$, lx.start(i) + 1, lx.len(i) - 1)
  EndIf
End Function
