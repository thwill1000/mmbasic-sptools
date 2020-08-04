' Copyright (c) 2020 Thomas Hugo Williams

Const TG_CALL_STACK_MAX = 50
Dim tg_call_stack$(TG_CALL_STACK_MAX - 1) Length 40
Dim tg_call_stack_sz
list_init(tg_call_stack$(), TG_CALL_STACK_MAX)

Sub treegen(name$, count, indent_lvl)
  If name$ = "" Then treegen(GLOBAL_SCOPE$, 0, 0) : Exit Sub

  Local ch$, i, indent$, p, s, v$

  count = count + 1
  indent$ = Space$(indent_lvl * 2)
  v$ = map_get$(subs_k$(), subs_v$(), subs_sz, LCase$(name$))
  Print Format$(count, "%5g") " " indent$;
  Print Field$(v$, 1, ",");
  If name$ <> GLOBAL_SCOPE$ Then Print "()";
  Print " <" Field$(v$, 2, ",") " " Field$(v$, 3, ",") ">"

  i = tg_is_recursive(name$)
  If i Then Print indent$ "      (recursive: see " Str$(i) ")" : Exit Sub

  list_push(tg_call_stack$(), tg_call_stack_sz, LCase$(name$) + "," + Str$(count))

  s = Val(Field$(v$, 4, ","))
  For i = 1 To 1 Step 0
    p = LInStr(work%(), ",", s)
    ch$ = LGetStr$(work%(), s, p - s)
    s = p + 1
    If ch$ <> Chr$(0) Then treegen(ch$, count, indent_lvl + 1)
    If ch$ = Chr$(0) Then i = 2
  Next i

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
