' Copyright (c) 2022-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

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
    Case "do"       : tr.handle_do()
    Case "else"     : tr.handle_else()
    Case "elseif"   : tr.handle_elseif()
    Case "end"      : tr.handle_end()
    Case "endif"      : tr.handle_endif()
    Case "exit"     : tr.handle_exit()
    Case "function" : tr.handle_function()
    Case "if"       : tr.handle_if()
    Case "loop"     : tr.handle_loop()
    Case "next"     : tr.handle_next()
    Case "sub"      : tr.handle_sub()
    Case "then"     : tr.handle_then()
  End Select
End Sub

Sub tr.handle_do()
  Local i% = tr.current%
  tr.replace_token("do", TK_KEYWORD)
  tr.insert_token("{", TK_SYMBOL)
  Inc tr.current%
End Sub

Sub tr.handle_end()
  Local i% = tr.current%
  tr.replace_token("}", TK_SYMBOL)

  If lx.type(i% + 1) = TK_KEYWORD Then
    Select Case lx.token_lc$(i% + 1)
      Case "function", "select", "sub" : tr.remove_next_token()
    End Select
  EndIf
End Sub

Sub tr.handle_else()
  tr.replace_token("}", TK_SYMBOL)
  tr.insert_token("else", TK_KEYWORD)
  Inc tr.current%, 1
  tr.insert_token("{", TK_SYMBOL)
  Inc tr.current%, 1
End Sub

Sub tr.handle_elseif()
  tr.replace_token("}", TK_SYMBOL)
  tr.insert_token("else", TK_KEYWORD)
  Inc tr.current%, 1
  tr.insert_token("if", TK_KEYWORD)
  Inc tr.current%, 1
  tr.insert_token("(", TK_SYMBOL)
  Inc tr.current%, 1
End Sub

Sub tr.handle_endif()
  tr.replace_token("}", TK_SYMBOL)
End Sub

Sub tr.handle_if()
  tr.replace_token("if", TK_KEYWORD)
  tr.insert_token("(", TK_SYMBOL)
  Inc tr.current%
End Sub

Sub tr.handle_exit()
  Local i% = tr.current%

  If lx.type(i% + 1) = TK_KEYWORD Then
    Select Case lx.token_lc$(i% + 1)
      Case "do"
        tr.replace_token("break", TK_KEYWORD)
        tr.remove_next_token()
      Case "function", "sub"
        tr.replace_token("return", TK_KEYWORD)
        tr.remove_next_token()
    End Select
  EndIf
End Sub

Sub tr.handle_function()
  tr.replace_token("function", TK_KEYWORD)
End Sub

Sub tr.handle_loop()
  tr.replace_token("}", TK_SYMBOL)
End Sub

Sub tr.handle_next()
  tr.replace_token("}", TK_SYMBOL)
End Sub

Sub tr.handle_sub()
  tr.replace_token("function", TK_KEYWORD)
End Sub

Sub tr.handle_then()
  tr.replace_token("{", TK_SYMBOL)
End Sub

Sub tr.insert_token(token$, type%)
  Local i% = tr.current%
  Local sep$
  Select Case token$
    Case "(" : sep$ = ""
    Case Else : sep$ = " "
  End Select
  If i% = lx.num - 1 Then
    lx.line$ = Left$(lx.line$, lx.start(i%) + lx.len(i%)) + sep$ + token$
  Else
    lx.line$ = Left$(lx.line$, lx.start(i% + 1) - 1) + token$ + sep$ + Mid$(lx.line$, lx.start(i% + 1))
  EndIf

  ' Shift following tokens up one index.
  Local shift% = Len(token$) + Len(sep$)
  Local j%
  For j% = lx.num - 1 To i% + 1 Step -1
    lx.type(j% + 1) = lx.type(j%)
    lx.start(j% + 1) = lx.start(j%) + shift%
    lx.len(j% + 1) = lx.len(j%)
  Next

  ' Insert new token.
  lx.type(i% + 1) = type%
  lx.start(i% + 1) = lx.start(i%) + lx.len(i%) + 1
  lx.len(i% + 1) = Len(token$)

  Inc lx.num, 1

  ' Print
  ' lx.dump()
  ' End
End Sub

Sub tr.remove_next_token()
  Local i% = tr.current%

  lx.line$ = Left$(lx.line$, lx.start(i%) + lx.len(i%) - 1)
  If i% + 1 < lx.num - 1 Then Cat lx.line$, Mid$(lx.line$, lx.start(i% + 2))
  Inc i%

  Local shift% = lx.start(i% + 1) - lx.start(i%)
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

Sub tr.replace_token(replacement$, type%)
  Local i% = tr.current%
  lx.line$ = Left$(lx.line$, lx.start(i%) - 1) + replacement$ + Mid$(lx.line$, lx.start(i%) + lx.len(i%))
  lx.type(i%) = type%
  Local shift% = Len(replacement$) - lx.len(i%)
  lx.len(i%) = Len(replacement$)
  Local j%
  For j% = i% + 1 To lx.num - 1
    Inc lx.start(j%), shift%
  Next
End Sub
