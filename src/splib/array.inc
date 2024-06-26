' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.provides("array")
If sys.err$ <> "" Then Error sys.err$
'!endif

' Gets the upper-bound that should be used to dimension an array of the given
' capacity, irrespective of OPTION BASE.
'
' e.g. To create a string array that can hold 10 elements:
'        Dim my_array$(array.new%(10))
Function array.new%(capacity%)
  array.new% = capacity% + Mm.Info(Option Base) - 1
End Function

' Binary search for a value in a SORTED array.
'
' @param  a$()    the array.
' @param  s$      the value to search for.
' @param  flags$  "i" to search case-insensitively,
' @param  lb%     the lower bound to search from,
'                 if 0/unset then search from the first element.
' @param  num%    the number of elements to search,
'                 if 0/unset then search all the elements (from lb%).
' @return         the index of the element containing the value,
'                 or -1 if not present.
Function array.bsearch%(a$(), s$, flags$, lb_%, num_%)
  Local lb% = Choice(lb_% = 0, Bound(a$(), 0), lb_%)
  Local num% = Choice(num_% = 0, Bound(a$(), 1) - Bound(a$(), 0) + 1, num_%)
  Local ub% = lb% + num% - 1
  Local i%

  If InStr(UCase$(flags$), "I") Then
    Local us$ = UCase$(s$)
    Local ua$
    Do While ub% >= lb%
      i% = (lb% + ub%) \ 2
      ua$ = UCase$(a$(i%))
      If us$ > ua$ Then
        lb% = i% + 1
      ElseIf us$ < ua$ Then
        ub% = i% - 1
      Else
        Exit Do
      EndIf
    Loop
  Else
    Do While ub% >= lb%
      i% = (lb% + ub%) \ 2
      If s$ > a$(i%) Then
        lb% = i% + 1
      ElseIf s$ < a$(i%) Then
        ub% = i% - 1
      Else
        Exit Do
      EndIf
    Loop
  EndIf

  If ub% >= lb% Then array.bsearch% = i% Else array.bsearch% = -1
End Function

' Gets the capacity (number of elements) that string array a$() can hold.
Function array.capacity%(a$())
  array.capacity% = Bound(a$(), 1) - Bound(a$(), 0) + 1
End Function

' Copies a string array.
'
' @param  src$()    the source array.
' @param  dst$()    the destination array.
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
  Local i%, lb% = Bound(a$(), 0), ub% = Bound(a$(), 1)
  For i% = lb% To ub% : a$(i%) = x$ : Next
End Sub

' Finds a string in an array.
'
' @param  a$()    the array.
' @param  s$      the string to find.
' @param  flags$  "i" to search case-insensitively.
' @return         the index of the element containing the value,
'                 or -1 if not present.
Function array.find_string%(a$(), s$, flags$)
  Local i%
  For i% = Bound(a$(), 0) To Bound(a$(), 1)
    If Choice(InStr(flags$, "i"), LCase$(a$(i%)) = LCase$(s$), a$(i%) = s$) Then
      array.find_string% = i%
      Exit Function
    Endif
  Next
  array.find_string% = -1
End Function

' Returns a string consisting of the concatenated elements of a float array
' joined together with a delimiter.
'
' @param   a!()    the array.
' @param   delim$  delimiter to place between each element, if empty/unset then uses comma.
' @param   lb%     lower bound to start from, if 0/unset then the 1st element.
' @param   num%    number of elements to join, if 0/unset then all elements.
' @param   slen%   maximum length of string to return, if 0/unset then 255 chars.
' @return          a string composed of the array elements separated by the delimiter. If the
'                  string had to be truncated to slen% then it is terminated with an ellipsis "..."
Function array.join_floats$(a!(), delim$, lb%, num%, slen%)
  Local delim_$ = Choice(delim$ = "", ",", delim$)
  Local lb_% = Choice(lb% = 0, Mm.Info(Option Base), lb%)
  Local ub_% = Choice(num% = 0, Bound(a!(), 1), lb_% + num% - 1)
  Local slen_% = Choice(slen% = 0, 255, slen%)

  Local s$ = Str$(a!(lb_%))
  Inc lb_%

  Do While lb_% <= ub_%
    Cat s$, Left$(delim_$, 255 - Len(s$))
    Cat s$, Left$(Str$(a!(lb_%)), 255 - Len(s$))
    Inc lb_%
  Loop

  If Len(s$) <= slen_% Then
    array.join_floats$ = s$
  Else
    array.join_floats$ = Left$(s$, slen_% - 3) + "..."
  EndIf
End Function

' Returns a string consisting of the concatenated elements of an integer array
' joined together with a delimiter.
'
' @param   a%()    the array.
' @param   delim$  delimiter to place between each element, if empty/unset then uses comma.
' @param   lb%     lower bound to start from, if 0/unset then the 1st element.
' @param   num%    number of elements to join, if 0/unset then all elements.
' @param   slen%   maximum length of string to return, if 0/unset then 255 chars.
' @return          a string composed of the array elements separated by the delimiter. If the
'                  string had to be truncated to slen% then it is terminated with an ellipsis "..."
Function array.join_ints$(a%(), delim$, lb%, num%, slen%)
  Local delim_$ = Choice(delim$ = "", ",", delim$)
  Local lb_% = Choice(lb% = 0, Mm.Info(Option Base), lb%)
  Local ub_% = Choice(num% = 0, Bound(a%(), 1), lb_% + num% - 1)
  Local slen_% = Choice(slen% = 0, 255, slen%)

  Local s$ = Str$(a%(lb_%))
  Inc lb_%

  Do While lb_% <= ub_%
    Cat s$, Left$(delim_$, 255 - Len(s$))
    Cat s$, Left$(Str$(a%(lb_%)), 255 - Len(s$))
    Inc lb_%
  Loop

  If Len(s$) <= slen_% Then
    array.join_ints$ = s$
  Else
    array.join_ints$ = Left$(s$, slen_% - 3) + "..."
  EndIf
End Function

' Returns a string consisting of the concatenated elements of a string array
' joined together with a delimiter.
'
' @param   a$()    the array.
' @param   delim$  delimiter to place between each element, if empty/unset then uses comma.
' @param   lb%     lower bound to start from, if 0/unset then the 1st element.
' @param   num%    number of elements to join, if 0/unset then all elements.
' @param   slen%   maximum length of string to return, if 0/unset then 255 chars.
' @return          a string composed of the array elements separated by the delimiter. If the
'                  string had to be truncated to slen% then it is terminated with an ellipsis "..."
Function array.join_strings$(a$(), delim$, lb%, num%, slen%)
  Local delim_$ = Choice(delim$ = "", ",", delim$)
  Local lb_% = Choice(lb% = 0, Mm.Info(Option Base), lb%)
  Local ub_% = Choice(num% = 0, Bound(a$(), 1), lb_% + num% - 1)
  Local slen_% = Choice(slen% = 0, 255, slen%)

  Local s$ = a$(lb_%)
  Inc lb_%

  Do While lb_% <= ub_%
    Cat s$, Left$(delim_$, 255 - Len(s$))
    Cat s$, Left$(a$(lb_%), 255 - Len(s$))
    Inc lb_%
  Loop

  If Len(s$) <= slen_% Then
    array.join_strings$ = s$
  Else
    array.join_strings$ = Left$(s$, slen_% - 3) + "..."
  EndIf
End Function

' Partitions an integer array and returns the pivot index.
Function array.partition_ints%(a%(), low%, high%, compare_fn$)
  Local i% = low% - 1, j%, pivot% = a%(high%), swap%, tmp%
  For j% = low% To high% - 1
    swap% = Choice(compare_fn$ = "", a%(j%) <= pivot%, Call(compare_fn$, a%(j%), pivot%) <= 0)
    If swap% Then
      Inc i%
      tmp% = a%(i%) : a%(i%) = a%(j%) : a%(j%) = tmp%
    EndIf
  Next j%
  Inc i%
  tmp% = a%(i%) : a%(i%) = a%(high%) : a%(high%) = tmp%
  array.partition_ints% = i%
End Function

' Quick sorts an integer array.
'
' @param[in,out]  a%()  array to be sorted.
' @param  lb%           lower bound to start the sort from;
'                       if 0/unset then sort from the first element.
' @param  num%          number of elements to sort; defaults to all.
' @param  compare_fn$   comparison function; defaults to ascending.
' @return               sys.SUCCESS on success, otherwise sys.FAILURE;
'                       see sys.err$ for details.
Function array.qsort_ints%(a%(), lb%, num%, compare_fn$)
   Const BASE = Mm.Info(Option Base)
   Local low% = Choice(lb% = 0, BASE, lb%)
   Local high% = Choice(num% = 0, Bound(a%(), 1), lb% + num% - 1)
   Local stack%(array.new%(2), array.new%(Max(2, high% - low% + 1)))
   Local pivot_index%, top% = BASE
   stack%(BASE, top%) = low%
   stack%(BASE + 1, top%) = high%
   Do
     If top% >= BASE Then
       low% = stack%(BASE, top%)
       high% = stack%(BASE + 1, top%)
       Inc top%, -1
       pivot_index% = array.partition_ints%(a%(), low%, high%, compare_fn$)
       If pivot_index% - 1 > low% Then
         Inc top%
         stack%(BASE, top%) = low%
         stack%(BASE + 1, top%) = pivot_index% - 1
       EndIf
       If pivot_index% + 1 < high% Then
         Inc top%
         stack%(BASE, top%) = pivot_Index% + 1
         stack%(BASE + 1, top%) = high%
       EndIf
     EndIf
   Loop Until top% < BASE
End Function
