' Copyright (c) 2020 Thomas Hugo Williams

Const GLOBAL_SCOPE$ = "*GLOBAL*"
Const MAX_NUM_SUBS = 1000

' Map of all the declared subroutines created by pass 1.
'
' Entries are of the form:
'   "LNAME" => "NAME,FILE,LINE,INDEX"
'
'   where:
'     LNAME : lower-case subroutine name
'     NAME  : actual subroutine name
'     FILE  : file declaring the subroutine
'     LINE  : line of file declaring the subroutine
'     INDEX : index into calls%() - this element is only appended to the value
'             at the end of pass 2
'
' When pass 1 ends an entry is added to represent the global scope:
'   "global*" > "*GLOBAL*,NAME,1,INDEX"
Dim subs_k$(MAX_NUM_SUBS) Length 32
Dim subs_v$(MAX_NUM_SUBS) Length 64
Dim subs_sz

' Used by pass 2:
'   global_calls%(i) = 1 if the global scope calls subroutine 'i'.
Dim global_calls%(MAX_NUM_SUBS)

' Used by pass 2:
'   current_calls%(i) = 1 if the current subroutine calls subroutine 'i'.
Dim current_calls%(MAX_NUM_SUBS)

' Populated during pass 2. For each subroutine S in 'subs' this contains a comma
' separated, alphabetically sorted list of the lower-case names of subroutines
' that are called by S, each list is terminated by an empty element.
Dim calls%(MAX_NUM_SUBS * 256)

' Name of subroutine currently being processed.
Dim current_sub$ = GLOBAL_SCOPE$

Sub pr_init()
  Local i
  map_init(subs_k$(), subs_v$(), MAX_NUM_SUBS + 1)
  For i = 0 To MAX_NUM_SUBS
    current_calls%(i) = 0
    global_calls%(i) = 0
  Next i

  LongString Clear calls%()
End Sub

Sub process(pass)
  Local i

  For i = 0 To lx_num - 1

    If InStr(" cfunction csub function sub ", " " + lx_token_lc$(i) + " ") Then
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

' Called during pass 1 when a CFUNCTION, CSUB, FUNCTION or SUB keyword
' followed by and identifier is processed.
'
' @param  i  the index of the keyword token.
Sub pass1_sub_begin(i)
  Local s$ = current_sub$ + "," + in_files$(in_files_sz - 1)
  s$ = s$ + "," + Str$(in_line_num(in_files_sz - 1))
  map_put(subs_k$(), subs_v$(), subs_sz, LCase$(current_sub$), s$)
End Sub

Sub pass_completed(pass)
  Select Case pass
    Case 1 : pass1_completed()
    Case 2 : pass2_completed()
    Case Else : Error
  End Select
End Sub

Sub pass1_completed()
  ' Add map entry for the global scope.
  Local k$ = LCase$(GLOBAL_SCOPE$)
  Local v$ = GLOBAL_SCOPE$ + "," + in_files$(0) + ",1"
  map_put(subs_k$(), subs_v$(), subs_sz, k$, v$)
End Sub

Sub pass2_completed()
  ' Record 'global_calls' in 'all_calls'.
  append_calls(GLOBAL_SCOPE$, global_calls%())
End Sub

' Called during pass 2 when a TK_IDENTIFIER is processed.
'
' @param  i  the index of the identifier token.
Sub pass2_identifier(i)
  Local id$ = lx_token_lc$(i)

  ' If the 'id' is not in the 'subs' map then not a function or subroutine.
  Local idx = set_get(subs_k$(), subs_sz, id$)
  If idx = -1 Then Exit Sub

  ' Ignore if the 'id' matches the name of the current sub.
  ' TODO: handle recursive calls.
  If id$ = current_sub$ Then Exit Sub

  ' Set flag in the appropriate calls array.
  If current_sub$ = GLOBAL_SCOPE$ Then
    global_calls%(idx) = 1
  Else
    current_calls%(idx) = 1
  EndIf
End Sub

' Called during pass 2 when an END keyword followed by
' CFUNCTION, CSUB, FUNCTION or SUB is processed.
Sub pass2_sub_end()
  If current_sub$ = GLOBAL_SCOPE$ Then
    err$ = "unexpected state; is subroutine name in 'keywords.txt'?"
    Exit Sub
  EndIf

  ' Record 'current_calls' in 'all_calls'.
  append_calls(current_sub$, current_calls%())

  ' Clear 'current_calls' set for processing the next subroutine.
  Local i
  For i = 0 To MAX_NUM_SUBS : current_calls%(i) = 0 : Next i
End Sub

' Appends the set of calls 'c%()' made by 'sub_name' to 'calls%()'
Sub append_calls(sub_name$, c%())
  Local i, v$

  ' Update the value in the 'subs' map to include a field pointing to the current
  ' position in calls%()
  v$ = map_get$(subs_k$(), subs_v$(), subs_sz, LCase$(sub_name$))
  v$ = v$ + "," + Str$(LLen(calls%()) + 1)
  map_put(subs_k$(), subs_v$(), subs_sz, LCase$(sub_name$), v$)

  ' Append comma-separated list of called subroutines, terminated by empty element.
  For i = 0 To MAX_NUM_SUBS
    If c%(i) Then LongString Append calls%(), subs_k$(i) + ","
  Next i
  LongString Append calls%(), ","
End Sub
