' Copyright (c) 2020 Thomas Hugo Williams

' Initialises the list.
Sub list_init(list$(), sz)
  list_clear(list$(), sz)
End Sub

' Clears the list and resets the size.
Sub list_clear(elements$(), sz)
  Do While sz > 0
    sz = sz - 1
    elements$(sz) = Chr$(&h7F) ' so empty elements are at the end when sorted
  Loop
End Sub

' Appends an element to the end of the list.
Sub list_add(elements$(), sz, s$)
  elements$(sz) = s$
  sz = sz + 1
End Sub

' Inserts an element into the list.
Sub list_insert(elements$(), sz, index, s$)
  Local i
  If index > sz Then Error "index > sz"
  For i = sz To index + 1 Step -1
    elements$(i) = elements$(i - 1)
  Next i
  elements$(i) = s$
  sz = sz + 1
End Sub

' Removes an element from the list.
Sub list_remove(elements$(), sz, index)
  Local i
  If index >= sz Then Error "index >= sz"
  For i = index To sz - 1
    elements$(i) = elements$(i + 1)
  Next i
  sz = sz - 1
  elements$(sz) = Chr$(&h7F)
End Sub

' Removes and returns the element at the end of the list.
Function list_pop$(elements$(), sz)
  sz = sz - 1
  If sz >= 0 Then list_pop$ = elements$(sz) Else list_pop$ = Chr$(&h7F)
End Function

' Appends an element to the end of the list.
Sub list_push(elements$(), sz, s$)
  elements$(sz) = s$
  sz = sz + 1
End Sub

' Prints the contents of the list.
Sub list_dump(elements$(), sz)
  Local i
  For i = 0 To sz - 1
    Print "[" Str$(i) "] " elements$(i)
  Next i
  Print "END"
End Sub
