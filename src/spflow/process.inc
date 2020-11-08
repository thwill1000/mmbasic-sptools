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
'     INDEX : index into all_calls() - this element is only appended to the
'             value at the end of pass 2
'
' When pass 1 ends an entry is added to represent the global scope:
'   "global*" > "*GLOBAL*,NAME,1,INDEX"
Dim subs$(map.new%(MAX_NUM_SUBS)) Length 255

' Used by pass 2:
'   global_calls(i) = 1 if the global scope calls subroutine 'i'.
Dim global_calls(MAX_NUM_SUBS)

' Used by pass 2:
'   current_calls(i) = 1 if the current subroutine calls subroutine 'i'.
Dim current_calls(MAX_NUM_SUBS)

' Populated during pass 2. For each subroutine S in 'subs' this contains a
' sequence of elements whose values are indexes into 'subs' that correspond
' to the subroutines called by S. Each sequence is terminated by an element
' with value -1.
Dim all_calls(MAX_NUM_SUBS * 20)
Dim all_calls_sz = 0

' Name of subroutine currently being processed.
Dim current_sub$ = GLOBAL_SCOPE$

Sub pro.init()
  map.init(subs$())

  Math Set 0, current_calls()
  Math Set 0, global_calls()
  Math Set 0, all_calls()

  all_calls_sz = 0
End Sub

Sub process(pass)
  Local i

  For i = 0 To lx.num - 1

    If InStr(" cfunction csub function sub ", " " + lx.token_lc$(i) + " ") Then
      If i > 0 Then
        If lx.token_lc$(i - 1) = "end" Then
          If pass = 2 Then pass2_sub_end()
          current_sub$ = GLOBAL_SCOPE$
        EndIf
      ElseIf lx.type(i + 1) = TK_IDENTIFIER Then
        If current_sub$ <> GLOBAL_SCOPE$ Then Error "Unexpected state"
        current_sub$ = lx.token$(i + 1)
        If pass = 1 Then pass1_sub_begin()
      EndIf
    Else If pass = 2 Then
      If lx.type(i) = TK_IDENTIFIER Then pass2_identifier(i)
    EndIf

  Next i
End Sub

' Called during pass 1 when a CFUNCTION, CSUB, FUNCTION or SUB keyword
' followed by and identifier is processed.
'
' @param  i  the index of the keyword token.
Sub pass1_sub_begin(i)
  Local s$ = current_sub$ + "," + in.files$(in.num_open_files% - 1)
  s$ = s$ + "," + Str$(in.line_num(in.num_open_files% - 1))
  map.put(subs$(), LCase$(current_sub$), s$)
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
  Local v$ = GLOBAL_SCOPE$ + "," + in.files$(0) + ",1"
  map.put(subs$(), k$, v$)
End Sub

Sub pass2_completed()
  ' Record 'global_calls' in 'all_calls'.
  append_calls(GLOBAL_SCOPE$, global_calls())
End Sub

' Called during pass 2 when a TK_IDENTIFIER is processed.
'
' @param  i  the index of the identifier token.
Sub pass2_identifier(i)
  Local id$ = lx.token_lc$(i)

  ' If the 'id' is not in the 'subs' map then not a function or subroutine.
  Local idx = map.get_key_index%(subs$(), id$)
  If idx = -1 Then Exit Sub

  ' Ignore 'id' followed by =
  If i < lx.num - 1 Then
    If lx.token$(i + 1) = "=" Then Exit Sub
  EndIf

  ' Ignore 'id' preceded by function/sub.
  If i > 0 Then
    If InStr(" cfunction csub function sub ", " " + lx.token_lc$(i - 1) + " ") Then Exit Sub
  EndIf

  ' Set flag in the appropriate calls array.
  If current_sub$ = GLOBAL_SCOPE$ Then
    global_calls(idx) = 1
  Else
    current_calls(idx) = 1
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
  append_calls(current_sub$, current_calls())

  ' Clear 'current_calls' set for processing the next subroutine.
  Local i
  For i = 0 To MAX_NUM_SUBS : current_calls(i) = 0 : Next i
End Sub

' Appends the set of calls 'calls()' made by 'sub_name' to 'all_calls()'
Sub append_calls(sub_name$, calls())
  Local i, v$

'  Print sub_name$
'  For i = 0 To 5 : Print "[" i "] : " calls(i) : Next i

  ' Update the value in the 'subs' map to include a field pointing to the current
  ' position in all_calls().
  v$ = map.get$(subs$(), LCase$(sub_name$))
  v$ = v$ + "," + Str$(all_calls_sz)
  map.put(subs$(), LCase$(sub_name$), v$)

  ' Append indexes of non-zero elements to all_calls().
  For i = 0 To MAX_NUM_SUBS
    If calls(i) Then all_calls(all_calls_sz) = i : all_calls_sz = all_calls_sz + 1
  Next i
  all_calls(all_calls_sz) = -1
  all_calls_sz = all_calls_sz + 1
End Sub
