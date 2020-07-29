' Copyright (c) 2020 Thomas Hugo Williams

Sub check_included(s$)
  Local x
  On Error Skip 1
  x = Eval("check_" + s$ + "_included()")
  If Mm.ErrNo <> 0 Then Error "'" + Mm.Info$(Current) + "' requires '" + s$ + ".inc'"
End Sub
