' Copyright (c) 2020 Thomas Hugo Williams

Dim op_infile$      ' input file/path
Dim op_outfile$     ' output file/path, empty for output to console

Sub op_init()
  op_infile$ = ""
  op_outfile$ = ""
End Sub

' Sets the value for an option.
'
' If name$ or value$ are invalid then sets err$.
Sub op_set(name$, value$)
  Local n$ = LCase$(name$)
  Local v$ = LCase$(value$)

  Select Case n$
    Case "infile"      : op_set_infile(v$)
    Case "outfile"     : op_set_outfile(v$)
    Case Else
      err$ = "unknown option: " + name$
  End Select
End Sub

Sub op_set_infile(value$)
  op_infile$ = value$
End Sub

Sub op_set_outfile(value$)
  op_outfile$ = value$
End Sub
