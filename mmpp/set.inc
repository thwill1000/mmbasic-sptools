' Copyright (c) 2020 Thomas Hugo Williams

Sub set_init(set$(), sz)
  Local i
  For i = 0 To sz - 1
    set$(i) = Chr$(&h7F) ' so empty elements are at the end when sorted
  Next i
End Sub

Sub set_put(set$(), sz, s$)
  set$(sz) = s$
  sz = sz + 1
  If sz > 1 Then
    If set$(sz - 1) < set$(sz - 2) Then
      Sort set$()
    EndIf
  EndIf
End Sub

Function set_get(set$(), sz, s$)
  Local i, lb, ub

  ' Binary search of set$()
  lb = 0
  ub = sz - 1
  Do
    i = (lb + ub) \ 2
    If s$ > set$(i) Then
      lb = i + 1
    ElseIf s$ < set$(i) Then
      ub = i - 1
    Else
      set_get = i : Exit Function
    EndIf
  Loop Until ub < lb

  set_get = -1
End Function

Sub set_remove(set$(), sz, s$)
  Local i = set_get(set$(), sz, s$)
  If i > -1 Then
    set$(i) = Chr$(&h7F)
    sz = sz - 1
    Sort set$()
  EndIf
End Sub

