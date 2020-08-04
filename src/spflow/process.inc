' Copyright (c) 2020 Thomas Hugo Williams

Const GLOBAL_SCOPE$ = "*GLOBAL*"

' 1 MB of workspace should be more than enough for even the most convoluted mess.
Dim work%(1024 * 1024 / 8 - 1)

Dim current_sub$ = GLOBAL_SCOPE$
Dim num_subs
Dim sub_name_len = Len(GLOBAL_SCOPE$)
Dim sub_def_len

Sub process(pass)
  Local i

  For i = 0 To lx_num - 1

    If InStr(" csub function sub ", " " + lx_token_lc$(i) + " ") Then
      If i > 0 Then
        If lx_token_lc$(i - 1) = "end" Then
          If pass = 2 Then pass2_sub_end()
          current_sub$ = GLOBAL_SCOPE$
        EndIf
      ElseIf lx_type(i + 1) = TK_IDENTIFIER Then
        If current_sub$ <> GLOBAL_SCOPE$ Then Error "Unexpected state"
        current_sub$ = lx_token$(i + 1)
        If pass = 1 Then pass1_sub_begin()
      EndIf
    Else If pass = 2 Then
      If lx_type(i) = TK_IDENTIFIER Then pass2_identifier(i)
    EndIf

  Next i
End Sub

' Called during pass 1 when a CSUB, FUNCTION or SUB keyword
' followed by and identifier is processed.
'
' @param  i  the index of the keyword token.
Sub pass1_sub_begin(i)
  num_subs = num_subs + 1
  sub_name_len = Max(sub_name_len, Len(current_sub$))
  Local s$ = current_sub$ + "," + in_files$(in_files_sz - 1)
  s$ = s$ + "," + Str$(cur_line_no(in_files_sz - 1))
  sub_def_len = Max(sub_def_len, Len(s$))
  LongString Append work%(), s$ + ","
End Sub

' Called when pass 1 has completed to initialise the data-structures for pass 2.
Sub pass1_completed()
  init_subs_map()
  init_global_calls_set()
  init_current_calls_set()

  LongString Clear work%()
End Sub

' Process work%() to create the 'subs' map,
' with entries of the form:
'   lower case subroutine name => actual name, file, line num
'
' Also contains an entry:
'   *global* => *GLOBAL*, main file, 1
Sub init_subs_map()
  Local k$, p, s, v$

  sub_def_len = sub_def_len + 10
  Dim subs_k$(num_subs) Length sub_name_len
  Dim subs_v$(num_subs) Length sub_def_len
  Dim subs_sz
  map_init(subs_k$(), subs_v$(), num_subs + 1)
  k$ = LCase$(GLOBAL_SCOPE$)
  v$ = GLOBAL_SCOPE$ + "," + in_files$(0) + ",1"
  map_put(subs_k$(), subs_v$(), subs_sz, k$, v$)

  s = 1
  Do
    p = LInStr(work%(), ",", s)
    k$ = LGetStr$(work%(), s, p - s)
    v$ = k$
    s = p + 1
    p = LInStr(work%(), ",", s)
    v$ = v$ + "," + LGetStr$(work%(), s, p - s)
    s = p + 1
    p = LInStr(work%(), ",", s)
    v$ = v$ + "," + LGetStr$(work%(), s, p - s)
    s = p + 1
    map_put(subs_k$(), subs_v$(), subs_sz, LCase$(k$), v$)
  Loop Until s >= LLen(work%())
End Sub

Sub init_global_calls_set()
  Dim global_calls$(subs_sz - 1) Length sub_name_len
  Dim global_calls_sz
  set_init(global_calls$(), subs_sz)
End Sub

Sub init_current_calls_set()
  Dim current_calls$(subs_sz - 1) Length sub_name_len
  Dim current_calls_sz
  set_init(current_calls$(), subs_sz)
End Sub

' Called during pass 2 when a TK_IDENTIFIER is processed.
'
' @param  i  the index of the identifier token.
Sub pass2_identifier(i)
  Local id$ = lx_token_lc$(i)

  ' If the 'id' is not in the 'subs' map then not a csub/function/sub.
  If map_get$(subs_k$(), subs_v$(), subs_sz, id$) = Chr$(0) Then Exit Sub

  ' Ignore if the 'id' matches the name of the current sub.
  ' TODO: handle recursive calls.
  If id$ = current_sub$ Then Exit Sub

  ' Add the 'id' to the appropriate 'calls' set.
  If current_sub$ = GLOBAL_SCOPE$ Then
    set_put(global_calls$(), global_calls_sz, id$)
  Else
    set_put(current_calls$(), current_calls_sz, id$)
  EndIf
End Sub

' Called during pass 2 when an END keyword followed by
' CSUB, FUNCTION or SUB is processed.
Sub pass2_sub_end()
  ' Record calls made from the current sub in the workspace.
  append_calls_to_work(current_sub$, current_calls$(), current_calls_sz)

  ' Clear the 'current_calls' set for when we process the next sub.
  set_clear(current_calls$(), current_calls_sz)
End Sub

' Appends a set of calls made by 'sub_name' to the workspace.
Sub append_calls_to_work(sub_name$, calls$(), calls_sz)
  Local i, v$

  ' Update the value in the 'subs' map to include a field pointing to the current
  ' position in work%()
  v$ = map_get$(subs_k$(), subs_v$(), subs_sz, LCase$(sub_name$))
  v$ = v$ + "," + Str$(LLen(work%()) + 1)
  map_put(subs_k$(), subs_v$(), subs_sz, LCase$(sub_name$), v$)

  ' Append comma-separated list of called subroutines, terminated by NULL element.
  For i = 0 To calls_sz - 1
    LongString Append work%(), calls$(i) + ","
  Next i
  LongString Append work%(), Chr$(0) + ","
End Sub

' Called when pass 2 has completed.
Sub pass2_completed()
  ' Record calls made from the global scope in the workspace.
  append_calls_to_work(GLOBAL_SCOPE$, global_calls$(), global_calls_sz)
End Sub
