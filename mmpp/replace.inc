' Copyright (c) 2020 Thomas Hugo Williams

Const RP_MAX_REPLACEMENTS = 200
Dim rp_replace$(RP_MAX_REPLACEMENTS - 1) Length 20
Dim rp_with$(RP_MAX_REPLACEMENTS - 1) Length 80
Dim rp_replace_sz
map_init(rp_replace$(), rp_with$(), RP_MAX_REPLACEMENTS)

Sub rp_clear()
  map_clear(rp_replace$(), rp_with$(), rp_replace_sz)
End Sub

' Adds a new replacement replace$ -> with$.
' TODO: What if the replacement already exists?
Sub rp_add(replace$, with$)
  map_put(rp_replace$(), rp_with$(), rp_replace_sz, LCase$(replace$), with$)
End Sub

' Applies replacements to the currently lexed line, lx_line$.
Sub rp_apply()
  Local i, s$, t$, u$

  If rp_replace_sz = 0 Then Exit Sub

  For i = 0 TO lx_num - 1
    t$ = lx_token_lc$(i)
    u$ = rp_get$(t$)
    If t$ <> u$ Then
      s$ = Left$(lx_line$, lx_start(i) - 1) + u$ + Mid$(lx_line$, lx_start(i) + lx_len(i))
      lx_parse_line(s$)
      ' TODO: what if this changes the number of tokens?
    EndIf
  Next i
End Sub

' Gets the replacement for a given string t$.
' If there is no replacement then just returns t$.
Function rp_get$(t$)
  rp_get$ = map_get$(rp_replace$(), rp_with$(), rp_replace_sz, LCase$(t$))
  If rp_get$ = Chr$(0) Then rp_get$ = t$
End Function

