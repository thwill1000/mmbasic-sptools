' Copyright (c) 2020 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.05

' Gets the upper-bound that should be used to dimension an array of the given
' capacity, irrespective of OPTION BASE.
'
' e.g. To create a string array that can hold 10 elements:
'        Dim my_array$(array.new%(10))
Function array.new%(capacity%)
  array.new% = capacity% + Mm.Info(Option Base) - 1
End Function

' Case-sensitive binary search for a value in a SORTED array.
'
' @param  a$()    the array.
' @param  s$      the value to search for.
' @param  flags$  "i" to search case-insensitively,
' @param  lb%     the lower bound to search from,
'                 if 0/unset then search from the first element.
' @param  ub%     the upper bound to search from,
'                 if 0/unset then search from the last element.
' @return         the index of the element containing the value,
'                 or -1 if not present.
Function array.bsearch%(a$(), s$, flags$, lb%, ub%)
  Local lb_% = Max(Mm.Info(Option Base), lb%)
  Local ub_% = ub%
  If ub_% = 0 Then ub_% = Bound(a$(), 1)
  Local i%

  If InStr(UCase$(flags$), "I") Then
    Local us$ = UCase$(s$)
    Local ua$
    Do While ub_% >= lb_%
      i% = (lb_% + ub_%) \ 2
      ua$ = UCase$(a$(i%))
      If us$ > ua$ Then
        lb_% = i% + 1
      ElseIf us$ < ua$ Then
        ub_% = i% - 1
      Else
        Exit Do
      EndIf
    Loop
  Else
    Do While ub_% >= lb_%
      i% = (lb_% + ub_%) \ 2
      If s$ > a$(i%) Then
        lb_% = i% + 1
      ElseIf s$ < a$(i%) Then
        ub_% = i% - 1
      Else
        Exit Do
      EndIf
    Loop
  EndIf

  If ub_% >= lb_% Then array.bsearch% = i% Else array.bsearch% = -1
End Function

' Gets the capacity (number of elements) that string array a$() can hold.
Function array.capacity%(a$())
  array.capacity% = Bound(a$(), 1) - Bound(a$(), 0) + 1
End Function

' Copies a string array.
'
' @param  src$()    the source array.
' @param  dst$()    the destination array.
' @param  flags$    "r" to copy elements in reverse order.
' @param  src_idx%  the start index in the source,
'                   if 0/unset then use the index of the first element.
' @param  dst_idx%  the start index in the destination,
'                   if 0/unset then use the index of the first element.
' @param  num%      the number of elements to copy,
'                   if 0/unset then copy all the elements (from idx%) from the source.
Sub array.copy(src$(), dst$(), src_idx%, dst_idx%, num%)
  Local base% = Mm.Info(Option Base 0)
  Local i%
  Local j% = Max(base%, dst_idx%)
  Local lb% = Max(base%, src_idx%)
  Local ub% = src_idx% + num% - 1
  If num% = 0 Then ub% = Bound(src$(), 1)

  ' TODO: Use a memory copy instead of a loop.
  For i% = lb% To ub% : dst$(j%) = src$(i%) : Inc j% : Next
End Sub

' Fills all the elements of string array a$() to x$.
Sub array.fill(a$(), x$)
  Local lb% = Bound(a$(), 0)
  Local ub% = Bound(a$(), 1)
  Local i%
  For i% = lb% To ub% : a$(i%) = x$ : Next
End Sub

' Sorts a string array.
'
' @param  array$()  array to sort
' @param  flags$  "i" to sort case-insensitively,
'                 "d" to sort into descending order.
' @param  idx%    the index in array$() to sort from,
'                 if 0/unset then use the index of the first element.
' @param  num%    the number of elements to sort,
'                 if 0/unset then sort all the elements (from idx%) in array$().
Sub array.sort(a$(), flags$, idx%, num%)
  Local base% = Mm.Info(Option Base)
  Local lb% = Max(idx%, base%)
  Local num_% = num%
  If num_% = 0 Then num_% = Bound(a$(), 1) - lb% + 1
  If num_% <= 1 Then Exit Sub
  Local ub% = lb% + num_% - 1

  ' If possible just use the default sort.
  If lb% = base% Then
    If ub% = Bound(a$(), 1) Then
      If flags$ = "" Then Sort a$() : Exit Sub
    EndIf
  EndIf

  Local tmp$(array.new%(num_%))
  Local i%
  Local j% = base%

  If InStr(UCase$(flags$), "I") Then
    ' Case-insensitive sort.
    Local tmp_ub% = Bound(tmp$(), 1)
    Local indexes%(array.new%(num_%))
    For i% = lb% To ub% : tmp$(j%) = UCase$(a$(i%)) : Inc j% : Next
    Sort tmp$(), indexes%()
    For i% = base% To tmp_ub% : tmp$(i%) = a$(indexes%(i%) + lb% - base%) : Next
  Else
    ' Case-sensitive sort.
    ' TODO: Use a memory copy instead of a loop.
    For i% = lb% To ub% : tmp$(j%) = a$(i%) : Inc j% : Next
    Sort tmp$()
  EndIf

  j% = base%
  If InStr(UCase$(flags$), "D") Then
    ' Descending sort.
    For i% = ub% To lb% Step -1 : a$(i%) = tmp$(j%) : Inc j% : Next
  Else
    ' Ascending sort.
    ' TODO: Use a memory copy instead of a loop.
    For i% = lb% To ub% : a$(i%) = tmp$(j%) : Inc j% : Next
  EndIf
End Sub
