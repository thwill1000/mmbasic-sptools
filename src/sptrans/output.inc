' Copyright (c) 2020 Thomas Hugo Williams

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.provides("output")
If sys.err$ <> "" Then Error sys.err$

Dim out.append = 0
Dim out.file_num = 0
Dim out.line_num = 0
Dim out.line_num_fmt$ = "%-5g "

Sub out.open(f$)
  If f$ <> "" Then
    out.file_num = 10
    Open f$ For Output As #out.file_num
  EndIf
End Sub

Sub out.close()
  If out.file_num > 0 Then Close #out.file_num
  out.file_num = 0
End Sub

Sub out.print(s$)
  If out.append Then
    If out.file_num = 0 Then Print s$; Else Print #out.file_num, s$;
  Else
    out.line_num = out.line_num + 1
    out.append = 1
    If out.line_num_fmt$ <> "" Then out.print(Format$(out.line_num, out.line_num_fmt$))
    out.print(s$)
  EndIf
End Sub

Sub out.endl()
  If out.append = 0 Then out.print() ' to print a line number if necessary
  If out.file_num = 0 Then Print Else Print #out.file_num
  out.append = 0
End Sub

Sub out.println(s$)
  out.print(s$)
  out.endl()
End Sub

