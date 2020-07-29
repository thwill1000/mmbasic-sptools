' Copyright (c) 2020 Thomas Hugo Williams

' Initialises the set.
Sub set_init(set$(), num_elements)
  Local sz = num_elements ' don't want to change num_elements
  set_clear(set$(), sz)
End Sub

' Clears the set and resets the size.
Sub set_clear(set$(), sz)
  Local i
  For i = 0 To sz - 1
    set$(i) = Chr$(&h7F) ' so empty elements are at the end when sorted
  Next i
  sz = 0
End Sub

' Adds a value to the set.
Sub set_put(set$(), sz, s$)
  If set_get(set$(), sz, s$) <> -1  Then Exit Sub
  set$(sz) = s$
  sz = sz + 1
  If sz > 1 Then
    If set$(sz - 1) < set$(sz - 2) Then
      Sort set$()
    EndIf
  EndIf
End Sub

' Gets the index of a value in the set, or -1 if not present.
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

' Removes a value from the set if present.
Sub set_remove(set$(), sz, s$)
  Local i = set_get(set$(), sz, s$)
  If i > -1 Then
    set$(i) = Chr$(&h7F)
    Sort set$()
    sz = sz - 1
  EndIf
End Sub

' Prints the contents of the set.
Sub set_dump(set$(), sz)
  Local i
  For i = 0 To sz - 1
    Print "["; Str$(i); "] "; set$(i)
  Next i
  Print "END"
End Sub

