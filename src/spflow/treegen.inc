' Copyright (c) 2020 Thomas Hugo Williams

Const TG_CALL_STACK_MAX = 50
Dim tg_call_stack$(TG_CALL_STACK_MAX - 1) Length 40
Dim tg_call_stack_sz
list_init(tg_call_stack$(), TG_CALL_STACK_MAX)

Sub treegen()

  ' Elements of this array are the line number in the output where the
  ' first call to the corresponding element of subs_k$ occurs.
  Dim tg_first_call(subs_sz - 1)

  out_line_num_fmt$ = "%5g "

  tg_subtree(GLOBAL_SCOPE$)

  ' TODO: handle orphan subroutines
  '       - those that can't be reached from global scope.
End Sub

Sub tg_subtree(name$)
  Local brief, i, j, indent$, v$

  i = set_get(subs_k$(), subs_sz, LCase$(name$))
  brief = tg_first_call(i)
  If brief = 0 Then tg_first_call(i) = out_line_num + 1

  indent$ = Space$(tg_call_stack_sz * 2)
  v$ = subs_v$(i)
  out_print(indent$ + Field$(v$, 1, ","))
  If name$ <> GLOBAL_SCOPE$ Then out_print("()")
  If Not op_no_files Then
    out_print(" <")
    If in_line_num(1) > 0 Then out_print(Field$(v$, 2, ",") + ":")
    out_print(Field$(v$, 3, ",") + ">")
  EndIf

  i = tg_is_recursive(name$)
'  If i Then Print : Print indent$ "        (recursive: see " Str$(i) ")" : Exit Sub
  If i Then out_println(": [recursive, see " + Str$(i) + "]") : Exit Sub

  list_push(tg_call_stack$(), tg_call_stack_sz, LCase$(name$) + "," + Str$(out_line_num))

  i = Val(Field$(v$, 4, ","))

  If all_calls(i) > -1 Then
    If brief * op_brief Then
      out_println(": [see " + Str$(brief) + "]")
    Else
      out_println(":")
      For j = 1 To 1 Step 0
        If all_calls(i) = -1 Then Exit For
        tg_subtree(subs_k$(all_calls(i)))
        i = i + 1
      Next j
    EndIf
  Else
    out_println()
  EndIf

  v$ = list_pop$(tg_call_stack$(), tg_call_stack_sz)
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
