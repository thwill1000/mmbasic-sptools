' Copyright (c) 2019-20 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.05

Function check_strings_included() : check_strings_included = 1 : End Function

Function str.centre$(s$, x%)
  If Len(s$) < x% Then
    str.centre$ = Space$((x% - Len(s$)) \ 2) + s$
    str.centre$ = str.centre$ + Space$(x% - Len(str.centre$))
  Else
    str.centre$ = s$
  EndIf
End Function

Sub str.tokenise(s$, sep$, tokens$(), tokens_sz%)
  Local c$, i%, start% = 1
  For i% = 1 To Len(s$)
    c$ = Mid$(s$, i%, 1)
    If Instr(sep$, c$) > 0 Then
      tokens$(tokens_sz%) = Mid$(s$, start%, i% - start%)
      tokens_sz% = tokens_sz% + 1
      start% = i% + 1
    EndIf
  Next i%

  If i% > start% Then
    tokens$(tokens_sz%) = Mid$(s$, start%, i% - start%)
    tokens_sz% = tokens_sz% + 1
  EndIf
End Sub

Function str.join$(tokens$(), tokens_sz%, ch$)
  Local i%
  For i% = 0 To tokens_sz% - 1
    If i% > 0 Then str.join$ = str.join$ + ch$
    str.join$ = str.join$ + tokens$(i%)
  Next i%
End Function

Function str.lpad$(s$, x%)
  str.lpad$ = s$
  If Len(s$) < x% Then str.lpad$ = Space$(x% - Len(s$)) + s$
End Function

' Returns the next space separated token from a string.
' Any excess spaces are ignored, empty tokens are never returned
' except when there are no tokens remaining.
'
' @param[in, out]  on input the string,
'                  on output the remainder of the string after the
'                  next token has been returned.
' @return          the next token, or the empty string if there are
'                  no more tokens.
Function str.next_token$(s$)
  Local en%, st% = 1
  Do
    en% = InStr(st%, s$, " ")
    If en% < 1 Then
      str.next_token$ = Mid$(s$, st%)
      s$ = ""
      Exit Function
    EndIf

    If en% = st% Then
      st% = st% + 1
    Else
      str.next_token$ = Mid$(s$, st%, en% - st%)
      s$ = Mid$(s$, en%)
      Exit Function
    EndIf
  Loop
End Function

Function str.rpad$(s$, x%)
  str.rpad$ = s$
  If Len(s$) < x% Then str.rpad$ = s$ + Space$(x% - Len(s$))
End Function