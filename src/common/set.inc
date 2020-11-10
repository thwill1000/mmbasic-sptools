' Copyright (c) 2020 Thomas Hugo Williams

Function check_set_included%() : End Function

' Used as the value for elements beyond the size of the set.
' Note: the length of the strings in the array holding the set must be at least 8 characters.
Const set.NULL$ = String$(8, Chr$(&h7F))

' Gets the upper-bound that should be used to dimension an array to hold a set
' of the given capacity, irrespective of OPTION BASE.
'
' e.g. To create a string array that can be used as a set of 10 elements:
'        Dim my_set$(set.new%(10))
Function set.new%(capacity%)
  set.new% = capacity% + Mm.Info(Option Base)
End Function

' Gets the capacity of the set.
Function set.capacity%(set$())
  set.capacity% = Bound(set$(), 1) - Bound(set$(), 0)
End Function

' Initialises the set.
Sub set.init(set$())
  Local lb% = Bound(set$(), 0)
  Local ub% = Bound(set$(), 1)
  Local i%
  For i% = lb% To ub% : set$(i%) = set.NULL$ : Next
  set$(ub%) = "0"
End Sub

' Clears the set and resets its size to 0.
Sub set.clear(set$())
  Local lb% = Bound(set$(), 0)
  Local ub% = Bound(set$(), 1)
  Local sz% = Val(set$(ub%))
  Local i%
  For i% = lb% To lb% + sz% - 1 : set$(i%) = set.NULL$ : Next
  set$(ub%) = "0"
End Sub

' Prints the contents of the set.
Sub set.dump(set$())
  Local lb% = Bound(set$(), 0)
  Local ub% = Bound(set$(), 1)
  Local sz% = Val(set$(ub%))
  Local i%
  For i% = lb% To lb% + sz% - 1 : Print "[" Str$(i%) "] " set$(i%) : Next
  Print "END"
End Sub

' Gets the index of a value in the set, or -1 if not present.
Function set.get%(set$(), s$)
  Local lb% = Bound(set$(), 0)
  Local ub% = Bound(set$(), 1)
  Local sz% = Val(set$(ub%))
  Local i%

  ' Binary search of set$()
  ub% = lb% + sz% - 1
  Do While ub% >= lb%
    i% = (lb% + ub%) \ 2
    If s$ > set$(i%) Then
      lb% = i% + 1
    ElseIf s$ < set$(i%) Then
      ub% = i% - 1
    Else
      set.get% = i% : Exit Function
    EndIf
  Loop ' Until ub% < lb%

  set.get% = -1
End Function

' Adds a value to the set.
Sub set.put(set$(), s$)
  If set.get%(set$(), s$) <> -1  Then Exit Sub

  Local lb% = Bound(set$(), 0)
  Local ub% = Bound(set$(), 1)
  Local sz% = Val(set$(ub%))

  If sz% = ub% - lb% Then Error "set full"

  set$(lb% + sz%) = s$
  sz% = sz% + 1
  set$(ub%) = Str$(sz%)

  If sz% <= 1 Then Exit Sub
  If set$(lb% + sz% - 1) >= set$(lb% + sz% - 2) Then Exit Sub

  set$(ub%) = set.NULL$
  Sort set$()
  set$(ub%) = Str$(sz%)
End Sub

' Removes a value from the set if present.
Sub set.remove(set$(), s$)
  Local i% = set.get%(set$(), s$)
  If i% = -1 Then Exit Sub

  Local ub% = Bound(set$(), 1)
  Local sz% = Val(set$(ub%))
  set$(i%) = set.NULL$
  set$(ub%) = set.NULL$
  Sort set$()
  set$(ub%) = Str$(sz% - 1)
  EndIf
End Sub

' Gets the size of the set.
Function set.size%(set$())
  set.size% = Val(set$(Bound(set$(), 1)))
End Function
