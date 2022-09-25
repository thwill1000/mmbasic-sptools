' Copyright (c) 2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.05

' Set to name of file after processing #Include
Dim tr.include$
Dim tr.current%

Sub tr.transpile()
  tr.current% = 0

  Do While tr.current% < lx.num
    tr.handle_token()
    Inc tr.current%
  Loop

End Sub

Sub tr.handle_token()
  Select Case lx.type(tr.current%)
    Case TK_COMMENT    : tr.handle_comment()
    Case TK_DIRECTIVE  : tr.comment_out()
    Case TK_IDENTIFIER : tr.handle_identifier()
    Case TK_KEYWORD    : tr.handle_keyword()
  End Select
End Sub

Sub tr.handle_comment()
  ' Convert comment to // style.
  Local i% = tr.current%
  Local s$ = "//" + Mid$(lx.line$, lx.start(i%) + 1)
  lx.line$ = Mid$(lx.line$, 1, lx.start(i%) - 1) + s$
  lx.len(i%) = Len(s$)
End Sub

Sub tr.handle_identifier()
  ' Remove trailing %, $ and ! from identifier.
  Local i% = tr.current%
  Local j%
  Local s$ = lx.token$(i%)
  Select Case Right$(s$, 1)
    Case "%", "$", "!"
      Inc lx.len(i%), -1
      lx.line$ = Left$(lx.line$, lx.start(i%) + lx.len(i%) - 1) + Mid$(lx.line$, lx.start(i%) + lx.len(i%) + 1)
      For j% = i% + 1 To lx.num - 1
        Inc lx.start(j%), -1
      Next
  End Select
End Sub

Sub tr.handle_keyword()
  Local i% = tr.current%
  Select Case lx.token_lc$(i%)
    Case "chr$"     : tr.handle_chr()
    Case "dim"      : tr.handle_dim()
    Case "do"       : tr.handle_do()
    Case "else"     : tr.handle_else()
    Case "elseif"   : tr.handle_elseif()
    Case "end"      : tr.handle_end()
    Case "endif"    : tr.handle_endif()
    Case "exit"     : tr.handle_exit()
    Case "function" : tr.handle_funsub()
    Case "if"       : tr.handle_if()
    Case "loop"     : tr.handle_loop()
    Case "next"     : tr.handle_next()
    Case "option"   : tr.handle_option()
    Case "print"    : tr.no_change()
    Case "sub"      : tr.handle_funsub()
    Case "then"     : tr.handle_then()
    Case Else       : tr.comment_out()
  End Select
End Sub

Sub tr.no_change()
  ' Not transformation.
End Sub

Sub tr.comment_out()
  Local s$ = "// " + Mid$(lx.line$, lx.start(tr.current%))
  tr.replace_token(tr.current%, s$, TK_COMMENT)
  tr.remove_token(tr.current% + 1)
End Sub

Sub tr.handle_chr()
  tr.replace_token(tr.current%, "String.fromCharCode", TK_IDENTIFIER)
End Sub

Sub tr.handle_dim()
  tr.replace_token(tr.current%, "let", TK_KEYWORD)

  Local i% = tr.current%
  If Not(i% + 1 < lx.num And lx.type%(i% + 1) = TK_IDENTIFIER) Then Exit Sub

  Inc i%
  tr.current% = i%
  tr.handle_identifier()

  If i% + 1 < lx.num Then
    If lx.token$(i% + 1) = "(" Then
      Inc i%
      ' Remove until match close bracket.
      Do While (i% < lx.num) And (lx.token$(i%) <> ")")
        tr.remove_token(i%)
      Loop
      tr.remove_token(i%)
    EndIf
  EndIf

  Do While i% < lx.num
    Select Case lx.token$(i%)
      Case "(" :
        tr.replace_token(i%, "[", TK_SYMBOL)
      Case ")" :
        tr.replace_token(i%, "]", TK_SYMBOL)
      Case ":" :
        Exit Do
    End Select
    Inc i%
  Loop

End Sub

Sub tr.handle_do()
  tr.replace_token(tr.current%, "do", TK_KEYWORD)
  tr.insert_token("{", TK_SYMBOL)
  Inc tr.current%
End Sub

Sub tr.handle_end()
  If tr.current% = lx.num - 1 Then
    tr.replace_token(tr.current%, "// exit(0)", TK_COMMENT)
  ElseIf lx.token$(tr.current% + 1) = ":" Then
    tr.replace_token(tr.current%, "/* exit(0) */", TK_COMMENT)
  Else
    tr.replace_token(tr.current%, "}", TK_SYMBOL)

    If lx.type(tr.current% + 1) = TK_KEYWORD Then
      Select Case lx.token_lc$(tr.current% + 1)
        Case "function", "select", "sub" : tr.remove_token(tr.current% + 1)
      End Select
    EndIf
  EndIf
End Sub

Sub tr.handle_else()
  tr.replace_token(tr.current%, "}", TK_SYMBOL)
  tr.insert_token("else", TK_KEYWORD)
  Inc tr.current%, 1
  tr.insert_token("{", TK_SYMBOL)
  Inc tr.current%, 1
End Sub

Sub tr.handle_elseif()
  tr.replace_token(tr.current%, "}", TK_SYMBOL)
  tr.insert_token("else", TK_KEYWORD)
  Inc tr.current%, 1
  tr.insert_token("if", TK_KEYWORD)
  Inc tr.current%, 1
  tr.insert_token("(", TK_SYMBOL)
  Inc tr.current%, 1
End Sub

Sub tr.handle_endif()
  tr.replace_token(tr.current%, "}", TK_SYMBOL)
End Sub

Sub tr.handle_if()
  tr.replace_token(tr.current%, "if", TK_KEYWORD)
  tr.insert_token("(", TK_SYMBOL)
  Inc tr.current%
End Sub

Sub tr.handle_exit()
  Local i% = tr.current%

  If lx.type(i% + 1) = TK_KEYWORD Then
    Select Case lx.token_lc$(i% + 1)
      Case "do"
        tr.replace_token(tr.current%, "break", TK_KEYWORD)
        tr.remove_token(tr.current% + 1)
      Case "function", "sub"
        tr.replace_token(tr.current%, "return", TK_KEYWORD)
        tr.remove_token(tr.current% + 1)
    End Select
  EndIf
End Sub

Sub tr.handle_expression()
  Do While tr.current% <= lx.num - 1
    If lx.token$(tr.current%) = ":" Then Exit Do
    Inc tr.current%
  Loop
  Print "***", lx.line$, tr.current%, lx.num
End Sub

Sub tr.handle_funsub()
  tr.replace_token(tr.current%, "function", TK_KEYWORD)
  Inc tr.current%
  If lx.type%(tr.current%) <> TK_IDENTIFIER Then Error "Expected identifier"
  Inc tr.current%
  If lx.token$(tr.current%) <> "(" Then Error "Expected open bracket"
  Inc tr.current%

  ' Skip to a matching close bracket.
  Do While tr.current% < lx.num
    If lx.token$(tr.current%) = ")" Then Exit Do
  Loop

  tr.insert_token("{", TK_SYMBOL)
End Sub

Sub tr.handle_loop()
  tr.replace_token(tr.current%, "}", TK_SYMBOL)
  If tr.current% = lx.num - 1 Then Exit Sub
  Inc tr.current%
  If lx.token_lc$(tr.current%) = "until" Then
    tr.replace_token(tr.current%, "while", TK_KEYWORD)
    tr.insert_token("(", TK_SYMBOL)
    Inc tr.current%
    tr.insert_token("!", TK_SYMBOL)
    Inc tr.current%
    tr.insert_token("(", TK_SYMBOL)
    Inc tr.current%
    Print "foo"
    tr.handle_expression()
    Print "bar"
    tr.insert_token(")", TK_SYMBOL)
    Inc tr.current%
    tr.insert_token(")", TK_SYMBOL)
    Inc tr.current%
  EndIf
End Sub

Sub tr.handle_next()
  tr.replace_token(tr.current%, "}", TK_SYMBOL)
End Sub

Sub tr.handle_option()
  Local s$ = "// " + Mid$(lx.line$, lx.start(tr.current%))
  tr.replace_token(tr.current%, s$, TK_COMMENT)
  tr.remove_token(tr.current% + 1)
End Sub

Sub tr.handle_then()
  tr.replace_token(tr.current%, "{", TK_SYMBOL)
End Sub

' Inserts token at given index moving the current token at that position
' and all the tokens following it one place to the right.
Sub tr.insert_token(idx%, token$, type%)
  Local i% = idx%
  Local length% = Len(lx.line$)
  Local sep$ ' Separator to insert before the token we are inserting,
             ' unless it is the first token.
  Select Case token$
    Case "(" : sep$ = ""
    Case Else : sep$ = " "
  End Select
  If i% = 0 Then sep$ = "" ' No separator before the first token.
  
  ' IMPORTANT: the space after a token is considered part of that token.
  
  If i% = lx.num Then
    lx.line$ = lx.line$ + sep$ + token$
  ElseIf i% = 0 Then
    lx.line$ = Left$(lx.line$, lx.start(i%) - 1) + sep$ + token$ + " " + Mid$(lx.line$, lx.start(i%))
  Else
    lx.line$ = Left$(lx.line$, lx.start(i% - 1) + lx.len(i% - 1)) + sep$ + token$ + Mid$(lx.line$, lx.start(i%))
  EndIf

  Local start% ' Start position for new token.
  If lx.num = 0 Then
    start% = length% + 1
  ElseIf i% = 0 Then
    start% = lx.start(0)
  ElseIf i% = lx.num Then
    start% = length% + Len(sep$) + 1
  Else
    start% = lx.start(i%)
  EndIf

  ' Shift following tokens up one index.
  Local shift% = Len(token$) + Len(sep$) + (i% = 0)
  Local j%
  For j% = lx.num - 1 To i% Step -1
    lx.type(j% + 1) = lx.type(j%)
    lx.start(j% + 1) = lx.start(j%) + shift%
    lx.len(j% + 1) = lx.len(j%)
  Next

  ' Insert new token.
  lx.type(i%) = type%
  lx.start(i%) = start%
  lx.len(i%) = Len(token$)

  Inc lx.num, 1
End Sub

' Removes token at given index.
Sub tr.remove_token(idx%)
  If idx% >= lx.num Then Exit Sub
  Local i% = idx%, length% = Len(lx.line$)

  ' Whitespace preceeding a removed token should be removed, unless we
  ' are removing the first token, idx% = 0.
  ' Whitespace following a removed token should be preserved, unless it
  ' is the final token, idx% = lx.num - 1.
  If i% = 0 Then
    lx.line$ = Left$(lx.line$, lx.start(0) - 1) + Mid$(lx.line$, lx.start(1))
  ElseIf i% = lx.num - 1 Then
    lx.line$ = Left$(lx.line$, lx.start(i% - 1) + lx.len(i% - 1) - 1)
  Else
    lx.line$ = Left$(lx.line$, lx.start(i% - 1) + lx.len(i% - 1) - 1) + Mid$(lx.line$, lx.start(i%) + lx.len(i%))
  EndIf

  'Print : Print idx%, lx.token$(idx%), lx.line$

  Local shift% = length% - Len(lx.line$)
  Local j%
  For j% = i% To lx.num - 2
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
Sub tr.replace_token(idx%, replacement$, type%)
  If idx% >= lx.num Then Error "Invalid token index: " + Str$(idx%)
  lx.line$ = Left$(lx.line$, lx.start(idx%) - 1) + replacement$ + Mid$(lx.line$, lx.start(idx%) + lx.len(idx%))
  lx.type(idx%) = type%
  Local shift% = Len(replacement$) - lx.len(idx%)
  lx.len(idx%) = Len(replacement$)
  Local i%
  For i% = idx% + 1 To lx.num - 1
    Inc lx.start(i%), shift%
  Next
End Sub
