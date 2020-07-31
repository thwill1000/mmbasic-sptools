' Copyright (c) 2020 Thomas Hugo Williams

Dim out_file_num = 0
Dim out_num_lines = 0
Dim out_append = 0

Sub out_open(f$)
  If f$ <> "" Then
    out_file_num = 10
    Open f$ For Output As #out_file_num
  EndIf
End Sub

Sub out_close()
  If out_file_num > 0 Then Close #out_file_num
  out_file_num = 0
End Sub

Sub out_print(s$)
  If out_append Then
    If out_file_num = 0 Then Print s$; Else Print #out_file_num, s$;
  Else
    out_num_lines = out_num_lines + 1
    out_append = 1
    out_print(Format$(out_num_lines, "%-4g") + ": ")
    out_print(s$)
  EndIf
End Sub

Sub out_endl()
  If out_append = 0 Then out_print() ' to print a line number
  If out_file_num = 0 Then Print Else Print #out_file_num
  out_append = 0
End Sub

