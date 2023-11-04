' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.provides("output")
If sys.err$ <> "" Then Error sys.err$
'!endif

Dim out.append% = 0
Dim out.eol$ = Chr$(10)
Dim out.file_num% = 0
Dim out.line_num% = 0
Dim out.line_num_width% = 5
Dim out.write_cb$ = "out.default_cb"

Sub out.default_cb(fnbr%, s$)
  Print #fnbr%, s$;
End Sub

Sub out.open(f$)
  If f$ <> "" Then
    out.file_num% = 10
    Open f$ For Output As #out.file_num%
  EndIf
End Sub

Sub out.close()
  If out.file_num% > 0 Then Close #out.file_num%
  out.file_num% = 0
End Sub

Sub out.print(s$)
  If out.append% Then
    Call out.write_cb$, out.file_num%, s$
  Else
    Inc out.line_num%
    out.append% = 1
    If out.line_num_width% Then out.print(str.rpad$(Str$(out.line_num%), out.line_num_width%) + " ")
    out.print(s$)
  EndIf
End Sub

Sub out.endl()
  If out.append% = 0 Then out.print() ' to print a line number if necessary
  Call out.write_cb$, out.file_num%, out.eol$
  out.append% = 0
End Sub

Sub out.println(s$)
  out.print(s$)
  out.endl()
End Sub

