' Copyright (c) 2020 Thomas Hugo Williams

' Global error variable.
Dim err$

Sub check_included(s$)
  On Error Skip 1
  Local x% = Eval("check_" + s$ + "_included%()")
  If Mm.ErrNo <> 0 Then Error "'" + Mm.Info$(Current) + "' requires '" + s$ + ".inc'"
End Sub
