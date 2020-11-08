' Copyright (c) 2020 Thomas Hugo Williams

Function check_map_included() : End Function

' Used as the value for keys/values beyond the size of the map.
' Note: the length of the strings in the array holding the map must be at least 8 characters.
Const map.NULL$ = String$(8, Chr$(&h7F))

' Gets the upper-bound that should be used to dimension an array to hold a map
' of the given capacity, irrespective of OPTION BASE.
'
' e.g. To create a string array that can be used as a map of 10 elements:
'        Dim my_map$(map.new%(10))
Function map.new%(capacity%)
  map.new% = 2 * capacity% + Mm.Info(Option Base)
End Function

' Initialises the map.
Sub map.init(mp$())
  Local lb% = Bound(mp$(), 0)
  Local ub% = Bound(mp$(), 1)
  Local i%
  For i% = lb% To ub% : mp$(i%) = map.NULL$ : Next
  mp$(ub%) = "0"
End Sub

' Gets the capacity of the map.
Function map.capacity%(mp$())
  map.capacity% = (Bound(mp$(), 1) - Bound(mp$(), 0)) \ 2
End Function

' Clears the keys and values and resets the size to 0.
Sub map.clear(mp$())
  Local lb% = Bound(mp$(), 0)
  Local ub% = Bound(mp$(), 1)
  Local off% = (ub% - lb%) \ 2
  Local sz% = Val(mp$(ub%))
  Local i%
  For i% = lb% To sz% + lb% - 1
    mp$(i%) = map.NULL$
    mp$(i% + off%) = map.NULL$
  Next
  mp$(ub%) = "0"
End Sub

' Prints the contents of the map.
Sub map.dump(mp$())
  Local lb% = Bound(mp$(), 0)
  Local ub% = Bound(mp$(), 1)
  Local off% = (ub% - lb%) \ 2
  Local sz% = Val(mp$(ub%))
  Local i%, length%
  For i% = lb% To lb% + sz% - 1 : length% = Max(length%, Len(mp$(i%))) : Next
  For i% = lb% To lb% + sz% - 1
    Print "[" Str$(i%) "] ";
    Print mp$(i%);
    Print Space$(length% - Len(mp$(i%)));
    Print " => ";
    Print mp$(i% + off%)
  Next
  Print "END"
End Sub

' Gets the value corresponding to a key, or amp2.NULL$ if the key is not present.
Function map.get$(mp$(), k$)
  Local i% = map.get_key_index%(mp$(), k$)
  If i% > -1 Then
    map.get$ = mp$(i% + (Bound(mp$(), 1) - Bound(mp$(), 0)) \ 2)
  Else
    map.get$ = map.NULL$
  EndIf
End Function

Function map.get_key_index%(mp$(), k$)
  Local lb% = Bound(mp$(), 0)
  Local ub% = Bound(mp$(), 1)
  Local sz% = Val(mp$(ub%))
  Local i%

  ' Binary search of keys.
  ub% = lb% + sz% - 1
  Do
    i% = (lb% + ub%) \ 2
    If k$ > mp$(i%) Then
      lb% = i% + 1
    ElseIf k$ < mp$(i%) Then
      ub% = i% - 1
    Else
      map.get_key_index% = i% : Exit Function
    EndIf
  Loop Until ub% < lb%

  map.get_key_index% = -1
End Function

' Adds a key/value pair.
Sub map.put(mp$(), k$, v$)
  Local lb% = Bound(mp$(), 0)
  Local ub% = Bound(mp$(), 1)
  Local off% = (ub% - lb%) \ 2
  Local i% = map.get_key_index%(mp$(), k$)
  If i% <> -1 Then mp$(i% + off%) = v$ : Exit Sub

  Local sz% = Val(mp$(ub%))

  If sz% = off% Then Error "map full" : Exit Sub

  sz% = sz% + 1
  mp$(sz% + lb% - 1) = k$
  mp$(sz% + off% - 1) = v$
  mp$(ub%) = Str$(sz%)
  If sz% > 1 Then
    If k$ < mp$(sz% + lb% - 2) Then map.sort(mp$())
  EndIf
End Sub

' Removes a key/value pair.
Sub map.remove(mp$(), k$)
  Local lb% = Bound(mp$(), 0)
  Local ub% = Bound(mp$(), 1)
  Local off% = (ub% - lb%) \ 2
  Local i% = map.get_key_index%(mp$(), k$)
  If i% = -1 Then Exit Sub

  mp$(i%) = map.NULL$
  mp$(i% + off%) = map.NULL$
  Local sz% = Val(mp$(ub%))
  If sz% > 1 Then map.sort(mp$())
  mp$(ub%) = Str$(sz% - 1)
End Sub

' Gets the size / number of entries in the map.
Function map.size%(mp$())
  map.size% = Val(mp$(Bound(mp$(), 1)))
End Function

' Sorts the map to place the keys in ascending order.
Sub map.sort(mp$())
  Local lb% = Bound(mp$(), 0)
  Local ub% = Bound(mp$(), 1)
  Local off% = (ub% - lb%) \ 2
  ub% = lb% + Val(mp$(ub%)) - 1
  Local i%, idx%(ub%), tmp$(ub%)

  ' Copy unsorted keys to tmp$().
  For i% = lb% To ub% : tmp$(i%) = mp$(i%) : Next

  Sort tmp$(), idx%()

  ' Copy sorted keys back into mp$().
  For i% = lb% To ub% : mp$(i%) = tmp$(i%) : Next

  ' Copy values to tmp$().
  For i% = lb% To ub% : tmp$(i%) = mp$(i% + off%) : Next

  ' Copy re-ordered values back into mp$().
  For i% = lb% To ub% : mp$(i% + off%) = tmp$(idx%(i%)) : Next
End Sub
