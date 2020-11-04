' Copyright (c) 2020 Thomas Hugo Williams

Function list2.included%() : End Function

' Used as the value for elements beyond the size of the list.
Const LIST2.NULL$ = String$(4, Chr$(&h7F))

' Gets the upper-bound that should be used to dimension an array to hold a list
' of the given capacity, irrespective of OPTION BASE.
'
' e.g. To create a string array that can be used as a list of 10 elements:
'        Dim my_list$(list2.new%(10))
Function list2.new%(capacity%)
  list2.new% = capacity% + Mm.Info(Option Base)
End Function

' Gets the capacity of the list.
Function list2.capacity%(list$())
  list2.capacity% = Bound(list$(), 1) - Bound(list$(), 0)
End Function

' Initialises the list.
Sub list2.init(lst$())
  Local i%
  For i% = Bound(lst$(), 0) To Bound(lst$(), 1)
    lst$(i%) = LIST2.NULL$
  Next
  lst$(Bound(lst$(), 1)) = "0"
End Sub

' Appends an element to the end of the list.
Sub list2.add(lst$(), s$)
  Local sz% = Val(lst$(Bound(lst$(), 1)))
  lst$(sz% - Bound(lst$(), 0)) = s$
  lst$(Bound(lst$(), 1)) = Str$(sz% + 1)
End Sub

' Clears the list and resets its size to 0.
Sub list2.clear(lst$())
  Local sz% = Val(lst$(Bound(lst$(), 1)))
  Local i%
  For i% = Bound(lst$(), 0) To sz% + Bound(lst$(), 0) - 1
    lst$(i%) = LIST2.NULL$
  Next
  lst$(Bound(lst$(), 1)) = "0"
End Sub

' Prints the contents of the list.
Sub list2.dump(lst$())
  Local sz% = Val(lst$(Bound(lst$(), 1)))
  Local i%
  For i% = Bound(lst$(), 0) To sz% + Bound(lst$(), 0) - 1
    Print "[" Str$(i%) "] " lst$(i%)
  Next
  Print "END"
End Sub

' Gets a list element with bounds checking.
' To get a list element without bounds checking just do s$ = lst$(index%) directly.
Function list2.get$(lst$(), index%)
  Local sz% = Val(lst$(Bound(lst$(), 1)))
  If index% >= sz% + Bound(lst$(), 0) Then Error "index out of bounds: " + Str$(index%)
  list2.get$ = lst$(index%)
End Function

' Inserts an element into the list.
Sub list2.insert(lst$(), index%, s$)
  Local i%
  Local sz% = Val(lst$(Bound(lst$(), 1)))
  If index% > sz% - Bound(lst$(), 0) + 1 Then Error "index out of bounds: " + Str$(index%)
  For i% = sz% To index% + 1 Step -1
    lst$(i%) = lst$(i% - 1)
  Next
  lst$(i%) = s$
  lst$(Bound(lst$(), 1)) = Str$(sz% + 1)
End Sub

' Removes and returns the element at the end of the list.
' If the list is empty then returns LIST2.NULL$
Function list2.pop$(lst$())
  Local sz% = Val(lst$(Bound(lst$(), 1)))
  sz% = sz% - 1
  If sz% >= Bound(lst$(), 0) Then
    list2.pop$ = lst$(sz%)
    lst$(Bound(lst$(), 1)) = Str$(sz%)
  Else
    list2.pop$ = LIST2.NULL$
  EndIf
End Function

' Synonym for add().
Sub list2.push(lst$(), s$)
  Local sz% = Val(lst$(Bound(lst$(), 1)))
  lst$(sz% - Bound(lst$(), 0)) = s$
  lst$(Bound(lst$(), 1)) = Str$(sz% + 1)
End Sub

' Removes an element from the list.
Sub list2.remove(lst$(), index%)
  Local i%
  Local sz% = Val(lst$(Bound(lst$(), 1)))
  If index% >= sz% - Bound(lst$(), 0) + 1 Then Error "index out of bounds: " + Str$(index%)
  For i% = index% To sz% - 1
    lst$(i) = lst$(i + 1)
  Next
  lst$(Bound(lst$(), 1)) = Str$(sz% - 1)
End Sub

' Sets a list element with bounds checking.
' To set a list element without bounds checking just do lst$(index%) = s$ directly.
Sub list2.set(lst$(), index%, s$)
  Local sz% = Val(lst$(Bound(lst$(), 1)))
  If index% >= sz% + Bound(lst$(), 0) Then Error "index out of bounds: " + Str$(index%)
  lst$(index%) = s$
End Sub

' Sorts the list.
Sub list2.sort(lst$())
  Local sz% = Val(lst$(Bound(lst$(), 1)))
  lst$(Bound(lst$(), 1)) = LIST2.NULL$
  Sort lst$()
  lst$(Bound(lst$(), 1)) = Str$(sz%)
End Sub

' Gets the size of the list.
Function list2.size%(list$())
  list2.size% = Val(list$(Bound(list$(), 1)))
End Function
