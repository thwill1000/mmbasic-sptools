' Copyright (c) 2020 Thomas Hugo Williams

Const RP_MAX_NUM = 100
Dim rp_num = 0
Dim rp_replace$(RP_MAX_NUM) Length 20
Dim rp_with$(RP_MAX_NUM) Length 20

Sub rp_add(replace$, with$)
  rp_replace$(rp_num) = replace$
  rp_with$(rp_num) = with$
  rp_num = rp_num + 1
End Sub

Sub rp_apply()
  Local i, j, s$, t$, u$
  If rp_num = 0 Then Exit Sub
  For i = 0 TO lx_num - 1
    t$ = LCase$(lx_get_token$(i))
    For j = 0 To rp_num - 1
      u$ = rp_replace$(j)
      If t$ = LCase$(u$) Then
        s$ = Left$(lx_line$, lx_start(i) - 1) + rp_with$(j) + Mid$(lx_line$, lx_start(i) + lx_len(i))
        lx_parse_line(s$)
        ' TODO: what if this changes the number of tokens?
      EndIf
    Next j
  Next i
End Sub

