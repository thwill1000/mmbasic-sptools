' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("list")
sys.provides("input")
If sys.err$ <> "" Then Error sys.err$
'!endif

' List of buffered input lines; in.readln$() first reads values from
' this list. Only if it is empty does it read from an input file.
Const in.BUFFER_SIZE = 5
Dim in.buffer$(list.new%(in.BUFFER_SIZE))

' Stack of open input source files.
Const MAX_NUM_FILES = 5
Dim in.files$(list.new%(MAX_NUM_FILES))

' Available as a separate variable for convenience,
' but should always = list.size%(in.files$())
 ' Initialised to -1 to flag that init() has not been called.
Dim in.num_open_files% = -1

Dim in.line_num%(MAX_NUM_FILES)

Sub in.init()
  list.init(in.files$())
  in.num_open_files% = 0
  Local i%
  For i% = Bound(in.line_num%(), 0) To Bound(in.line_num%(), 1)
    in.line_num%(i%) = 0
  Next
End Sub

Function in.open%(f$)
  If in.num_open_files% = -1 Then Error "Not initialised"
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
  If list.size%(in.buffer$()) Then
    in.readln$ = list.get$(in.buffer$(), 0)
    list.remove(in.buffer$(), 0)
  Else
    Line Input #in.num_open_files%, in.readln$
    Inc in.line_num%(in.num_open_files% - 1)
  EndIf
End Function

Function in.buffer_line%(line$)
  If list.is_full%(in.buffer$()) Then
    in.buffer_line% = sys.error%(sys.FAILURE, "Input buffer full")
  Else
    list.add(in.buffer$(), line$)
  EndIf
End Function
