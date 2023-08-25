' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("list")
sys.provides("input")
If sys.err$ <> "" Then Error sys.err$

' Stack of open input source files.
Const MAX_NUM_FILES = 5
Dim in.files$(list.new%(MAX_NUM_FILES))
list.init(in.files$())

' Available as a separate variable for convenience,
' but should always = list.size%(in.files$())
Dim in.num_open_files% = 0

Dim in.line_num%(MAX_NUM_FILES)

Function in.open%(f$)
  If in.num_open_files% = MAX_NUM_FILES Then
    in.open% = sys.error%(sys.FAILURE, "Too many open #Include files")
    Exit Function
  EndIf

  Local f_abs$
  If list.size%(in.files$()) > 0 Then
    If Not file.is_absolute%(f$) Then
      f_abs$ = file.get_parent$(in.files$(0))
      If f_abs$ <> "" Then Cat f_abs$, "/"
    EndIf
  EndIf
  Cat f_abs$, f$

  If file.is_directory%(f_abs$) Then
    in.open% = sys.error%(sys.FAILURE, "Cannot #Include directory '" + f_abs$ + "'")
  ElseIf file.exists%(f_abs$) Then
    list.push(in.files$(), f_abs$)
    in.num_open_files% = list.size%(in.files$())
    Open f_abs$ For Input As #in.num_open_files%
    in.line_num%(in.num_open_files% - 1) = 0
  Else
    in.open% = sys.error%(sys.FAILURE, "#Include file '" + f_abs$ + "' not found")
  EndIf
End Function

Sub in.close()
  Close #in.num_open_files%
  Local s$ = list.pop$(in.files$())
  in.num_open_files% = list.size%(in.files$())
End Sub

Function in.readln$()
  Local s$
  Line Input #in.num_open_files%, s$
  in.readln$ = s$
  Inc in.line_num%(in.num_open_files% - 1)
End Function
