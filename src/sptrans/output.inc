' Copyright (c) 2020 Thomas Hugo Williams

Dim out_append = 0
Dim out_file_num = 0
Dim out_line_num = 0
Dim out_line_num_fmt$ = "%-5g "

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
    out_line_num = out_line_num + 1
    out_append = 1
    If out_line_num_fmt$ <> "" Then out_print(Format$(out_line_num, out_line_num_fmt$))
    out_print(s$)
  EndIf
End Sub

Sub out_endl()
  If out_append = 0 Then out_print() ' to print a line number if necessary
  If out_file_num = 0 Then Print Else Print #out_file_num
  out_append = 0
End Sub

Sub out_println(s$)
  out_print(s$)
  out_endl()
End Sub

