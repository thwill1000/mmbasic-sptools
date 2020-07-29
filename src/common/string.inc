' Copyright (c) 2020 Thomas Hugo Williams

Sub str_tokenise(s$, sep$, tokens$(), tokens_sz)
  Local c$, i, start = 1
  For i = 1 To Len(s$)
    c$ = Mid$(s$, i, 1)
    If Instr(sep$, c$) > 0 Then
      tokens$(tokens_sz) = Mid$(s$, start, i - start)
      tokens_sz = tokens_sz + 1
      start = i + 1
    EndIf
  Next i

  If i > start Then 
    tokens$(tokens_sz) = Mid$(s$, start, i - start)
    tokens_sz = tokens_sz + 1
  EndIf
End Sub

Function str_join$(tokens$(), tokens_sz, ch$)
  Local i
  For i = 0 To tokens_sz - 1
    If i > 0 Then str_join$ = str_join$ + ch$
    str_join$ = str_join$ + tokens$(i)
  Next i
End Function

