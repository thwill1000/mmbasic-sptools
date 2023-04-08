' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.06

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("set", "keywords")
sys.provides("lexer")
If sys.err$ <> "" Then Error sys.err$

'!ifdef INLINE_CONSTANTS
'!replace TK_IDENTIFIER  1
'!replace TK_NUMBER      2
'!replace TK_COMMENT     3
'!replace TK_STRING      4
'!replace TK_KEYWORD     5
'!replace TK_SYMBOL      6
'!replace TK_DIRECTIVE   7
'!replace TK_LABEL       8
'!replace TK_OPTION      9
'!endif
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
Dim lx.num         ' number of tokens.
Dim lx.pos
Dim lx.csub        ' 1 if we are tokenising within a CSUB definition, otherwise 0.

' @return  0 on success, otherwise -1 and sets 'sys.err$'.
Function lx.parse_basic%(line$)
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

    If sys.err$ <> "" Then
      lx.parse_basic% = -1
      Exit Do
    EndIf
  Loop
End Function

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
    If InStr("abcdefh0123456789", lx.next_char$) Then
      lx.parse_hex_or_binary()
    ElseIf lx.next_char$ = "o" Then
      lx.parse_octal()
    ElseIf lx.next_char$ = "&" Then
      lx.parse_symbol()
    Else
      sys.err$ = "Unknown literal type &" + lx.next_char$
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

Sub lx.parse_hex_or_binary()
  Local start = lx.pos

  ' To facilitate transpiling BBC Basic source code the lexer accepts
  ' hex numbers which begin with just an & instead of &h.
  '
  ' This does introduce an unresolved ambiguity, e.g. is "&b0" the binary
  ' number 0 or the hex number B0 ?
  '
  ' TODO: provide an option to switch between BBC Basic and MMBasic
  '       "&-prefixed" literals.

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
  If lx.num = 0 Then
    ' Only the first token on a line will be recognised as a directive.
    If lx.next_char$ = "!" Then
      lx.parse_directive()
      Exit Sub
    EndIf
  EndIf
  lx.parse_comment()
End Sub

Sub lx.parse_directive()
  Local start = lx.pos

  lx.advance()
  lx.advance()
  lx.advance_while("-_abcdefghijklmnopqrstuvwxyz0123456789")
  lx.store(TK_DIRECTIVE, start, lx.pos - start)

  If lx.token_lc$(lx.num - 1) = "'!replace" Then lx.parse_replace_directive()
End Sub

Sub lx.parse_replace_directive()
  Local start

  Do While lx.char$ <> Chr$(10)
    If lx.char$ = " " Then
      lx.advance()
    ElseIf InStr("{}", lx.char$) Then
      lx.parse_symbol()
    Else
      start = lx.pos
      lx.advance()
      lx.advance_until(" {}" + Chr$(10))
      ' TODO: not really a KEYWORD, but a REPLACEMENT token.
      lx.store(TK_KEYWORD, start, lx.pos - start)
    EndIf

    If sys.err$ <> "" Then Exit Do
  Loop
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
  If keywords.contains%(Mid$(lx.line$, start, ln%)) Then
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
    Case "&"
      lx.advance()
      Select Case lx.char$
        Case "&"
          lx.store(TK_SYMBOL, start, 2)
          lx.advance()
        Case Else
          lx.store(TK_SYMBOL, start, 1)
      End Select
    Case "|"
      lx.advance()
      Select Case lx.char$
        Case "|"
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
  lx.token$ = Choice(i < lx.num, Mid$(lx.line$, lx.start(i), lx.len(i)), "")
End Function

' Gets the lower-case text of token 'i'.
'
' If i > the number of tokens then returns the empty string.
Function lx.token_lc$(i)
  lx.token_lc$ = Choice(i < lx.num, LCase$(Mid$(lx.line$, lx.start(i), lx.len(i))), "")
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
Function lx.number!(i)
  If lx.type(i) <> TK_NUMBER Then Error "{" + lx.token$(i) + "} is not a number literal"
  lx.number! = Val(lx.token$(i))
End Function

' @return  0 on success, otherwise -1 and sets 'sys.err$'.
Function lx.parse_command_line%(line$)
  lx.reset(line$)
  lx.advance()

  Do While lx.char$ <> Chr$(10)
    If lx.char$ = " " Then
      lx.advance()
    ' ElseIf InStr("&.0123456789", lx.char$) Then
    '   lx.parse_number()
    ' ElseIf lx.char$ = "'" Then
    '   lx.parse_comment_or_directive()
    ElseIf lx.char$ = Chr$(34) Then
      lx.parse_string()
    ElseIf InStr("./@#_abcdefghijklmnopqrstuvwxyz", lx.char$) Then
      lx.parse_argument()
    ElseIf lx.char$ = "-" Then
      lx.parse_option()
    Else
      lx.parse_symbol()
    EndIf

    If sys.err$ <> "" Then 
      lx.parse_command_line% = -1
      Exit Do
    EndIf
  Loop
End Function

Sub lx.parse_option()

  Const start = lx.pos

  Select Case lx.char$
    Case "-"
      lx.advance()
      If lx.char$ = "-" Then lx.advance()
    ' Case "/"
    '   lx.advance()
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

Sub lx.parse_argument()
  Local start% = lx.pos
  lx.advance()
  lx.advance_while(".-_/abcdefghijklmnopqrstuvwxyz0123456789")
  lx.store(TK_IDENTIFIER, start, lx.pos - start)
End Sub

' Gets the command-line option corresponding to token 'i'.
'
' Throws an Error if token 'i' is not a command-line option.
Function lx.option$(i)
  If lx.type(i) <> TK_OPTION Then Error "{" + lx.token$(i) + "} is not a command-line option"
  Local sz% = Choice(Mid$(lx.line$, lx.start(i), 2) = "--", 2, 1)
  lx.option$ = Mid$(lx.line$, lx.start(i) + sz%, lx.len(i) - sz%)
End Function

Sub lx.dump()
  Local i%, type$
  Print "[[[" lx.line$ "]]]"
  For i% = 0 To lx.num - 1
    Select Case lx.type%(i%)
      Case TK_IDENTIFIER : type$ = "IDENTIFIER"
      Case TK_NUMBER     : type$ = "NUMBER    "
      Case TK_COMMENT    : type$ = "COMMENT   "
      Case TK_STRING     : type$ = "STRING    "
      Case TK_KEYWORD    : type$ = "KEYWORD   "
      Case TK_SYMBOL     : type$ = "SYMBOL    "
      Case TK_DIRECTIVE  : type$ = "DIRECTIVE "
      Case TK_LABEL      : type$ = "LABEL     "
      Case TK_OPTION     : type$ = "OPTION    "
      Case Else          : type$ = "<UNKNOWN> "
    End Select
    Print Str$(i%) ": " type$ ", " Str$(lx.start%(i%)) ", " Str$(lx.len%(i%)) ", [[[" lx.token$(i%) "]]]"
  Next
End Sub

' Inserts token at given index moving the current token at that position
' and all the tokens following it one place to the right.
'
' 1. Whitespace preceeding a token is considered part of that token,
'    unless it is the first token.
' 2. Whitespace following the last token is considered part of that
'    token.
Sub lx.insert_token(idx%, token$, type%)
  If idx% > lx.num Then Error "Invalid token index: " + Str$(idx%)
  Local length% = Len(lx.line$), prefix$, suffix$

  ' Separator to insert before the token we are inserting.
  Local sep$ = Choice(idx% = 0, "", Choice(token$ = "(", "", " "))

  Select Case idx%
    Case lx.num
      prefix$ = lx.line$
    Case 0
      prefix$ = Left$(lx.line$, lx.start(idx%) - 1)
      suffix$ = " " + Mid$(lx.line$, lx.start(idx%))
    Case Else
      Local prefix_len% = lx.start(idx% - 1) + lx.len(idx% - 1) - 1
      prefix$ = Left$(lx.line$, prefix_len%)
      suffix$ = Mid$(lx.line$, prefix_len% + 1)
  End Select
  lx.line$ = prefix$ + sep$ + token$ + suffix$

  ' Shift following tokens up one index.
  Local shift% = Len(token$) + Len(sep$) + (idx% = 0)
  Local j%
  For j% = lx.num - 1 To idx% Step -1
    lx.type(j% + 1) = lx.type(j%)
    lx.start(j% + 1) = lx.start(j%) + shift%
    lx.len(j% + 1) = lx.len(j%)
  Next

  ' Insert new token.
  lx.type(idx%) = type%
  lx.start(idx%) = Len(prefix$ + sep$) + 1
  lx.len(idx%) = Len(token$)

  Inc lx.num, 1
End Sub

' Removes token at given index.
'
' 1. Whitespace preceeding a token is considered part of that token,
'    unless it is the first token.
' 2. Whitespace following the last token is considered part of that
'    token.
Sub lx.remove_token(idx%)
  If idx% >= lx.num Then Error "Invalid token index: " + Str$(idx%)
  Local length% = Len(lx.line$), prefix$, suffix$

  Select Case idx%
    Case 0
      prefix$ = Left$(lx.line$, lx.start(0) - 1)
      suffix$ = Choice(lx.num = 1, "", Mid$(lx.line$, lx.start(1)))
    Case lx.num - 1
      prefix$ = Left$(lx.line$, lx.start(idx% - 1) + lx.len(idx% - 1) - 1)
    Case Else
      prefix$ = Left$(lx.line$, lx.start(idx% - 1) + lx.len(idx% - 1) - 1)
      suffix$ = Mid$(lx.line$, lx.start(idx%) + lx.len(idx%))
  End Select
  lx.line$ = prefix$ + suffix$

  Local shift% = length% - Len(lx.line$)
  Local j%
  For j% = idx% To lx.num - 2
    lx.type(j%) = lx.type(j% + 1)
    lx.start(j%) = lx.start(j% + 1) - shift%
    lx.len(j%) = lx.len(j% + 1)
  Next

  Inc lx.num, -1
  lx.type(lx.num) = 0
  lx.start(lx.num) = 0
  lx.len(lx.num) = 0
End Sub

' Replaces token at given index.
Sub lx.replace_token(idx%, replacement$, type%)
  If idx% >= lx.num Then Error "Invalid token index: " + Str$(idx%)
  lx.line$ = Left$(lx.line$, lx.start(idx%) - 1) + replacement$ + Mid$(lx.line$, lx.start(idx%) + lx.len(idx%))
  lx.type(idx%) = type%
  Local shift% = Len(replacement$) - lx.len(idx%)
  lx.len(idx%) = Len(replacement$)
  Local j%
  For j% = idx% + 1 To lx.num - 1
    Inc lx.start(j%), shift%
  Next
End Sub
