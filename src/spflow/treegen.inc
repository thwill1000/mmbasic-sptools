' Copyright (c) 2020 Thomas Hugo Williams

Sub treegen(name$, indent_lvl)
  If name$ = "" Then treegen(GLOBAL_SCOPE$, 0) : Exit Sub

  Local ch$, i, indent$, p, s, v$

  indent$ = Space$(indent_lvl * 4)
  v$ = map_get$(subs_k$(), subs_v$(), subs_sz, LCase$(name$))
  Print indent$;
  Print Field$(v$, 1, ",") " <";
  Print Field$(v$, 2, ",") " ";
  Print Field$(v$, 3, ",") ">"
  s = Val(Field$(v$, 4, ","))
  For i = 1 To 1 Step 0
    p = LInStr(work%(), ",", s)
    ch$ = LGetStr$(work%(), s, p - s)
    s = p + 1
    If ch$ <> Chr$(0) Then treegen(ch$, indent_lvl + 1)
    If ch$ = Chr$(0) Then i = 2
  Next i

End Sub
