' Copyright (c) 2020 Thomas Hugo Williams

Function check_map_included() : End Function

' Initialises the keys and values.
Sub map.init(keys$(), values$(), num_elements)
  Local sz = num_elements ' don't want to change num_elements
  map.clear(keys$(), values$(), sz)
End Sub

' Clears the keys and values and resets the size.
Sub map.clear(keys$(), values$(), sz)
  Local i
  For i = 0 To sz - 1
    keys$(i) = Chr$(&h7F) ' so empty elements are at the end when sorted
    values$(i) = Chr$(0)
  Next i
  sz = 0
End Sub

' Adds a key/value pair.
Sub map.put(keys$(), values$(), sz, k$, v$)
  Local i = map.get_key_index%(keys$(), sz, k$)
  If i <> -1 Then values$(i) = v$ : Exit Sub
  keys$(sz) = k$
  values$(sz) = v$
  sz = sz + 1
  If sz > 1 Then
    If keys$(sz - 1) < keys$(sz - 2) Then map.sort(keys$(), values$(), sz)
  EndIf
End Sub

Function map.get_key_index%(keys$(), sz, s$)
  Local i, lb, ub

  ' Binary search of keys$()
  lb = 0
  ub = sz - 1
  Do
    i = (lb + ub) \ 2
    If s$ > keys$(i) Then
      lb = i + 1
    ElseIf s$ < keys$(i) Then
      ub = i - 1
    Else
      map.get_key_index% = i : Exit Function
    EndIf
  Loop Until ub < lb

  map.get_key_index% = -1
End Function

' Resorts the keys and values.
Sub map.sort(keys$(), values$(), sz)
  Local i, idx(sz - 1), k$(sz - 1), v$(sz - 1)

  For i = 0 To sz - 1
    k$(i) = keys$(i)
    v$(i) = values$(i)
  Next i

  Sort k$(), idx()

  For i = 0 To sz - 1
    keys$(i) = k$(i)
    values$(i) = v$(idx(i))
  Next i
End Sub

' Gets the value corresponding to a key, or Chr$(0) if the key is not present.
Function map.get$(keys$(), values$(), sz, k$)
  Local i = map.get_key_index%(keys$(), sz, k$)
  If i > -1 Then map.get$ = values$(i) Else map.get$ = Chr$(0)
End Function

' Removes a key/value pair.
Sub map.remove(keys$(), values$(), sz, k$)
  Local i = map.get_key_index%(keys$(), sz, k$)
  If i > -1 Then
    keys$(i) = Chr$(&h7F)
    values$(i) = Chr$(0)
    If sz > 1 Then map.sort(keys$(), values$(), sz)
    sz = sz - 1
  EndIf
End Sub

' Prints the contents of the map.
Sub map.dump(keys$(), values$(), sz)
  Local i, length
  For i = 0 To sz - 1
    If Len(keys$(i)) > length Then length = Len(keys$(i))
  Next i
  For i = 0 To sz - 1
    Print "["; Str$(i); "] "; keys$(i); Space$(length - Len(keys$(i))); " => "; values$(i)
  Next i
  Print "END"
End Sub
