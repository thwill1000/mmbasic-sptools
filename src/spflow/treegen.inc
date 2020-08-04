' Copyright (c) 2020 Thomas Hugo Williams

Const TG_CALL_STACK_MAX = 50
Dim tg_call_stack$(TG_CALL_STACK_MAX - 1) Length 40
Dim tg_call_stack_sz
list_init(tg_call_stack$(), TG_CALL_STACK_MAX)

Sub treegen(name$)
  If name$ = "" Then treegen(GLOBAL_SCOPE$) : Exit Sub

  ' Line number in the output
  Static line_num = 0

  ' Elements of this array are the line number in the output where the
  ' first call to the corresponding element of subs_k$ occurs.
  Static first_call(subs_sz - 1)

  line_num = line_num + 1
  Local i = set_get(subs_k$(), subs_sz, LCase$(name$))
  Local brief = first_call(i)
  If brief = 0 Then first_call(i) = line_num

  Local indent$ = Space$(tg_call_stack_sz * 2)
  Local v$ = subs_v$(i)
  Print Format$(line_num, "%5g") " " indent$ Field$(v$, 1, ",");
  If name$ <> GLOBAL_SCOPE$ Then Print "()";
  If Not op_no_files Then Print " <" Field$(v$, 2, ",") ":" Field$(v$, 3, ",") ">";

  i = tg_is_recursive(name$)
'  If i Then Print : Print indent$ "        (recursive: see " Str$(i) ")" : Exit Sub
  If i Then Print ": [recursive, see " Str$(i) "]" : Exit Sub

  list_push(tg_call_stack$(), tg_call_stack_sz, LCase$(name$) + "," + Str$(line_num))

  Local s = Val(Field$(v$, 4, ","))
  Local p = LInStr(work%(), ",", s)
  Local ch$ = LGetStr$(work%(), s, p - s)

  If ch$ <> Chr$(0) Then
    If brief * op_brief Then
      Print ": [see " Str$(brief) "]"
    Else
      Print ":"
      For i = 1 To 1 Step 0
        treegen(ch$)
        s = p + 1
        p = LInStr(work%(), ",", s)
        ch$ = LGetStr$(work%(), s, p - s)
        If ch$ = Chr$(0) Then Exit For
      Next i
    EndIf
  Else
    Print
  EndIf

  ch$ = list_pop$(tg_call_stack$(), tg_call_stack_sz)
End Sub

Function tg_is_recursive(name$)
  Local i
  For i = 0 To tg_call_stack_sz - 1
    If Field$(tg_call_stack$(i), 1, ",")  = LCase$(name$) Then
      tg_is_recursive = Val(Field$(tg_call_stack$(i), 2, ","))
      Exit Function
    EndIf
  Next i
End Function
