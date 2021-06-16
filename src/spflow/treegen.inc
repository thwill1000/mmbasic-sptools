' Copyright (c) 2020 Thomas Hugo Williams

Dim tg.call_stack$(list.new%(50)) Length 40
list.init(tg.call_stack$())

' Elements of this array are the line number in the output where the
' first call to the corresponding element of subs_k$ occurs.
Dim tg.first_call(MAX_NUM_SUBS)

Sub treegen()
  out.line_num_fmt$ = "%5g "
  tg.subtree(GLOBAL_SCOPE$)
  If opt.all Then tg.orphans()
End Sub

Sub tg.subtree(name$)
  Local brief, i, j, indent$, v$

  i = map.get_key_index%(subs$(), LCase$(name$))
  brief = tg.first_call(i)
  If brief = 0 Then tg.first_call(i) = out.line_num + 1

  indent$ = Space$(list.size%(tg.call_stack$()) * 2)
  v$ = subs$(i + MAX_NUM_SUBS)
  out.print(indent$ + Field$(v$, 1, ","))
  If name$ <> GLOBAL_SCOPE$ Then out.print("()")
  If Not opt.no_location Then
    out.print(" <")
    If in.line_num(1) > 0 Then out.print(Field$(v$, 2, ",") + ":")
    out.print(Field$(v$, 3, ",") + ">")
  EndIf

  i = tg.is_recursive(name$)
  If i Then out.println(" [recursive, see " + Str$(i) + "]") : Exit Sub

  list.push(tg.call_stack$(), LCase$(name$) + "," + Str$(out.line_num))

  i = Val(Field$(v$, 4, ","))

  If all_calls(i) > -1 Then
    If brief * opt.brief Then
      out.println(" [see " + Str$(brief) + "]")
    Else
      out.println()
      For j = 1 To 1 Step 0
        If all_calls(i) = -1 Then Exit For
        tg.subtree(subs$(all_calls(i)))
        i = i + 1
      Next j
    EndIf
  Else
    out.println()
  EndIf

  v$ = list.pop$(tg.call_stack$())
End Sub

Function tg.is_recursive(name$)
  Local i
  Local sz = list.size%(tg.call_stack$())
  For i = 0 To sz - 1
    If Field$(tg.call_stack$(i), 1, ",")  = LCase$(name$) Then
      tg.is_recursive = Val(Field$(tg.call_stack$(i), 2, ","))
      Exit Function
    EndIf
  Next i
End Function

Sub tg.orphans()
  Local i
  Local ub% = map.size%(subs$()) - 1
  For i = 0 To ub%
    If tg.first_call(i) = 0 Then
      out.println()
      tg.subtree(subs$(i))
    EndIf
  Next i
End Sub
