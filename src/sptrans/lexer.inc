' Copyright (c) 2020-2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("set", "keywords")
sys.provides("lexer")
If sys.err$ <> "" Then Error sys.err$

'!comment_if INLINE_CONSTANTS
Const TK_IDENTIFIER = 1
Const TK_NUMBER = 2
Const TK_COMMENT = 3
Const TK_STRING = 4
Const TK_KEYWORD = 5
Const TK_SYMBOL = 6
Const TK_DIRECTIVE = 7
Const TK_LABEL = 8
Const TK_OPTION = 9
'!endif

Const LX_MAX_TOKENS = 255 ' In theory every character may be a separate token.
Dim lx.type(LX_MAX_TOKENS - 1)
Dim lx.start(LX_MAX_TOKENS - 1)
Dim lx.len(LX_MAX_TOKENS - 1)

Dim lx.char$
Dim lx.line$
Dim lx.next_char$
Dim lx.num
Dim lx.pos
Dim lx.csub ' 1 if we are tokenising within a CSUB definition, otherwise 0.

Sub lx.parse_basic(line$)
  lx.reset(line$)
  lx.advance()

  Do While lx.char$ <> Chr$(10)
    If lx.char$ = " " Then
      lx.advance()
    ElseIf InStr("&.0123456789", lx.char$) Then
      If lx.csub Then
        lx.parse_identifier()
      Else
        lx.parse_number()
      EndIf
    ElseIf lx.char$ = "'" Then
      lx.parse_comment_or_directive()
    ElseIf lx.char$ = Chr$(34) Then
      lx.parse_string()
    ElseIf InStr("@#_abcdefghijklmnopqrstuvwxyz", lx.char$) Then
      lx.parse_identifier()
    Else
      lx.parse_symbol()
    EndIf

    If sys.err$ <> "" Then Exit Do
  Loop
End Sub

Sub lx.reset(line$)
  ' Clear old token data
  Do While lx.num > 0
    Inc lx.num, -1
    lx.type(lx.num) = 0
    lx.start(lx.num) = 0
    lx.len(lx.num) = 0
  Loop

  sys.err$ = ""
  lx.line$ = line$
  lx.next_char$ = ""
  lx.pos = 0
End Sub

Sub lx.advance()
  Inc lx.pos
  lx.char$ = lx.next_char$
  If lx.char$ = "" Then
    lx.char$ = Choice(lx.pos <= Len(lx.line$), LCase$(Chr$(Peek(Var lx.line$, lx.pos))), Chr$(10))
  EndIf

  If lx.pos + 1 <= Len(lx.line$) Then
    lx.next_char$ = LCase$(Chr$(Peek(Var lx.line$, lx.pos + 1)))
  Else
    lx.next_char$ = Chr$(10)
  EndIf

End Sub

Sub lx.parse_number()
  If InStr(".0123456789", lx.char$) Then
    lx.parse_decimal()
  ElseIf lx.char$ = "&" Then
    Select Case lx.next_char$
      Case "b" : lx.parse_binary()
      Case "h" : lx.parse_hexadecimal()
      Case "o" : lx.parse_octal()
      Case Else : sys.err$ = "Unknown literal type &" + lx.next_char$
    End Select
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
    ' Handle E numbers:
    '  - if there is just a trailing E, e.g. 1234E then the E is part of the
    '    number literal.
    '  - however if followed by anything other than +, -, or <digit>,
    '    e.g. 1234ENDPROC then the E is part of a following identifier.
    If InStr(" -+0123456789" + Chr$(10), lx.next_char$) Then
      lx.advance()
      If lx.char$ = "-" Or lx.char$ = "+" Then lx.advance()
      lx.advance_while("0123456789")
    EndIf
  ElseIf lx.char$ = ":" Then
    ' Handle numeric labels.
    If lx.num = 0 Then lx.advance()
  EndIf

  lx.store(TK_NUMBER, start, lx.pos - start)
  If Right$(lx.token$(lx.num - 1), 1) = ":" Then lx.type(lx.num - 1) = TK_LABEL
End Sub

Sub lx.store(type, start, length)
  If length = 0 Then Error "Empty token"
  lx.type(lx.num) = type
  lx.start(lx.num) = start
  lx.len(lx.num) = length
  Inc lx.num
End Sub

Sub lx.advance_while(allowed$)
  Do While InStr(allowed$, lx.char$) : lx.advance() : Loop
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
  If lx.next_char$ = "!" Then lx.parse_directive() Else lx.parse_comment()
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
  If lx.char$ = Chr$(10) Then sys.err$ = "No closing quote" : Exit Sub
  lx.store(TK_STRING, start, lx.pos - start + 1)
  lx.advance()
End Sub

Sub lx.advance_until(disallowed$)
  Do While Not InStr(disallowed$, lx.char$) : lx.advance() : Loop
End Sub

Sub lx.parse_identifier()
  Local start = lx.pos

  lx.advance()
  lx.advance_while("._abcdefghijklmnopqrstuvwxyz0123456789")

  If lx.char$ = " " Then
    ' Handle old-school REM statements.
    If LCase$(Mid$(lx.line$, start, lx.pos - start)) = "rem") Then
      lx.store(TK_COMMENT, start, Len(lx.line$) - start + 1)
      lx.char$ = Chr$(10)
      Exit Sub
    EndIf
  ElseIf lx.char$ = ":" Then
    ' Handle labels.
    If lx.num = 0 Then lx.advance()
  ElseIf InStr("$!%", lx.char$) Then
    ' Handle trailing type symbol.
    lx.advance()
  EndIf

  Local ln% = lx.pos - start
  If keywords.contains(Mid$(lx.line$, start, ln%)) Then
    lx.store(TK_KEYWORD, start, ln%)
    If lx.token_lc$(lx.num - 1) = "csub" Then lx.csub = Not lx.csub
  Else
    lx.store(TK_IDENTIFIER, start, ln%)
    If Right$(lx.token$(lx.num - 1), 1) = ":" Then lx.type(lx.num - 1) = TK_LABEL
  EndIf
End Sub

Sub lx.parse_symbol()
  Local start = lx.pos

  Select Case lx.char$
    Case "<", ">", "="
      lx.advance()
      Select Case lx.char$
        Case "<", ">", "="
          lx.store(TK_SYMBOL, start, 2)
          lx.advance()
        Case Else
          lx.store(TK_SYMBOL, start, 1)
      End Select
    Case Else
      lx.store(TK_SYMBOL, start, 1)
      lx.advance()
  End Select
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

Sub lx.parse_command_line(line$)
  lx.reset(line$)
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
      lx.parse_identifier()
    ElseIf InStr("-/", lx.char$) Then
      lx.parse_option()
    Else
      lx.parse_symbol()
    EndIf

    If sys.err$ <> "" Then Exit Do
  Loop
End Sub

Sub lx.parse_option()

  Const start = lx.pos

  Select Case lx.char$
    Case "-"
      lx.advance()
      If lx.char$ = "-" Then lx.advance()
    Case "/"
      lx.advance()
    Case Else
      Error "Unexpected badly formed option" ' Should never happen.
  End Select

  Const legal$ = "-_abcdefghijklmnopqrstuvwxyz0123456789"
  Local ok% = InStr(legal$, lx.char$) > 0
  If ok% Then lx.advance_while(legal$)
  ok% = ok% And (InStr("= " + Chr$(10), lx.char$) > 0)

  If ok% Then
    lx.store(TK_OPTION, start, lx.pos - start)
  Else
    If Not InStr("= " + Chr$(10), lx.char$) Then lx.advance()
    sys.err$ = "Illegal command-line option format: " + Mid$(lx.line$, start, lx.pos - start)
  EndIf

End Sub

' Gets the command-line option corresponding to token 'i'.
'
' Throws an Error if token 'i' is not a command-line option.
Function lx.option$(i)
  If lx.type(i) <> TK_OPTION Then Error "{" + lx.token$(i) + "} is not a command-line option"
  Local sz% = Choice(Mid$(lx.line$, lx.start(i), 2) = "--", 2, 1)
  lx.option$ = Mid$(lx.line$, lx.start(i) + sz%, lx.len(i) - sz%)
End Function
