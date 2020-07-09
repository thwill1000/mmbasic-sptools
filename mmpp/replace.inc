' Copyright (c) 2020 Thomas Hugo Williams

Const RP_MAX_REPLACEMENTS = 200
Dim rp_replace$(RP_MAX_REPLACEMENTS - 1) Length 20
Dim rp_with$(RP_MAX_REPLACEMENTS - 1) Length 80
Dim rp_replace_sz
rp_clear()

' Clears the list of replacements.
Sub rp_clear()
  Local i

  For i = 0 To RP_MAX_REPLACEMENTS - 1
    rp_replace$(i) = Chr$(&h7F) ' so empty elements are at the end when sorted
    rp_with$(i) = ""
  Next i
  rp_replace_sz = 0
End Sub

' Adds a new replacement replace$ -> with$.
' TODO: What if the replacement already exists?
Sub rp_add(replace$, with$)
  rp_replace$(rp_replace_sz) = LCase$(replace$)
  rp_with$(rp_replace_sz) = with$
  rp_replace_sz = rp_replace_sz + 1
  If rp_replace_sz > 1 Then
    If rp_replace$(rp_replace_sz - 1) < rp_replace$(rp_replace_sz - 2) Then rp_sort()
  EndIf
End Sub

' Sorts rp_replace$() ensuring that the mapping with rp_with$() is maintained.
Sub rp_sort()
  Local i
  Local indexes(RP_MAX_REPLACEMENTS - 1)
  Local with$(RP_MAX_REPLACEMENTS - 1)

  For i = 0 To rp_replace_sz - 1 : with$(i) = rp_with$(i) : Next i
  Sort rp_replace$(), indexes()
  For i = 0 To rp_replace_sz - 1 : rp_with$(i) = with$(indexes(i)) : Next i
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
  Local i, lb, ub, s$

  ' Binary search
  s$ = LCase$(t$)
  lb = 0
  ub = rp_replace_sz - 1
  Do
    i = (lb + ub) \ 2
    If s$ > rp_replace$(i) Then
      lb = i + 1
    ElseIf s$ < rp_replace$(i) Then
      ub = i - 1
    Else
      rp_get$ = rp_with$(i) : Exit Function
    EndIf
  Loop Until ub < lb

  ' No replacement
  rp_get$ = t$
End Function

