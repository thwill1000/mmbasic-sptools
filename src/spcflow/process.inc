' Copyright (c) 2020 Thomas Hugo Williams

'Const MAX_NUM_CALLS = 10000
'Dim calls$(MAX_NUM_CALLS - 1) Length 65
'Dim calls_sz = 0
'set_init(calls$(), MAX_NUM_CALLS)

Const GLOBAL_SCOPE$ = "*GLOBAL*"

' 1 MB of workspace should be more than enough for even the most convoluted mess.
Dim work%(1024 * 1024 / 8 - 1)

Dim current_sub$ = GLOBAL_SCOPE$
Dim num_subs
Dim sub_name_len = Len(GLOBAL_SCOPE$)
Dim sub_def_len

Sub process(pass)
  Local i, t$
  For i = 0 To lx_num - 1
    t$ = " " + lx_token_lc$(i) + " "
    If InStr(" csub function sub ", t$) Then
      If i > 0 Then
        If lx_token_lc$(i - 1) = "end" Then current_sub$ = GLOBAL_SCOPE$
      ElseIf lx_type(i + 1) = TK_IDENTIFIER Then
        If current_sub$ <> GLOBAL_SCOPE$ Then Error "Unexpected state"
        current_sub$ = lx_token$(i + 1)
        If pass = 1 Then process_sub_decl()
      EndIf
    EndIf
  Next i
End Sub

Sub process_identifier(i, pass)
  Select Case pass
    Case 1 : process_identifier_pass1(i)
    Case 2 : 'process_identifier_pass2(i)
    Case Else : Error
  End Select
End Sub

' 'i' is the index of the CSUB, FUNCTION or SUB keyword
Sub process_sub_decl(i)
  num_subs = num_subs + 1
  sub_name_len = Max(sub_name_len, Len(current_sub$))
  Local s$ = current_sub$ + "," + in_files$(in_files_sz - 1)
  s$ = s$ + "," + Str$(cur_line_no(in_files_sz - 1))
  sub_def_len = Max(sub_def_len, Len(s$))
  LongString Append work%(), s$ + ","
End Sub

' Process work%() to create the 'subs' map, with entries of the form:
'   lower case subroutine name => actual name, file, line num
'
' Also contains an entry:
'   *global* => *GLOBAL*, main file, 1
Sub create_subs_map()
  Local k$, p, s, v$

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

Sub process_identifier_pass2(i)
  Local id$ = lx_token_lc$(i)
  If i > 0 Then
    If InStr(" csub function sub ", lx_token_lc$(i - 1)) Then
      ' Subroutine declaration
      current_sub$ = id$
      Exit Sub
    EndIf
  EndIf

  If id$ = current_sub$ Then Exit Sub

  If map_get$(subs_keys$(), subs_values$(), subs_sz, id$) = Chr$(0) Then Exit Sub

  set_put(calls$(), calls_sz, current_sub$ + "#" + id$)
End Sub

Sub generate()
  Local i
  For i = 0 To subs_sz - 1
    Print Field$(subs_v$(i), 1, ",") " <";
    Print Field$(subs_v$(i), 2, ",") " ";
    Print Field$(subs_v$(i), 3, ",") ">"
    Print "    foo"
    Print "    bar"
    Print "    wombat"
  Next i
End Sub
