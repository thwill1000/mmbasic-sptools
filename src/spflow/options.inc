' Copyright (c) 2020 Thomas Hugo Williams

Dim op_brief
Dim op_no_files
Dim op_infile$      ' input file/path
Dim op_outfile$     ' output file/path, empty for output to console

Sub op_init()
  op_brief = 0
  op_no_files = 0
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
    Case "brief"    : op_set_brief(v$)
    Case "infile"   : op_set_infile(v$)
    Case "no-files" : op_set_no_files(v$)
    Case "outfile"  : op_set_outfile(v$)
    Case Else
      err$ = "unknown option: " + name$
  End Select
End Sub

Sub op_set_brief(v$)
  Select Case v$
    Case "default", "off", "0", "" : op_brief = 0
    Case "on", "1"                 : op_brief = 1
    Case Else
      err$ = "expects 'on|off' argument"
  End Select
End Sub

Sub op_set_infile(v$)
  op_infile$ = v$
End Sub

Sub op_set_no_files(v$)
  Select Case v$
    Case "default", "off", "0", "" : op_no_files = 0
    Case "on", "1"                 : op_no_files = 1
    Case Else
      err$ = "expects 'on|off' argument"
  End Select
End Sub

Sub op_set_outfile(v$)
  op_outfile$ = v$
End Sub
