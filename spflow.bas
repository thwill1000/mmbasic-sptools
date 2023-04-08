' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Const file$ =  Mm.Info$(Path) + "src/spflow/spflow.bas"
If Mm.Device$ = "MMB4L" Then
  Run file$, Mm.CmdLine$
Else
  Execute "Run " + Chr$(34) + file$ + Chr$(34) + ", " + Mm.CmdLine$
EndIf
