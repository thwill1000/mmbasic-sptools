' Copyright (c) 2020 Thomas Hugo Williams

' Stack of open input source files.
Const MAX_NUM_FILES = 5
Dim in.files$(list.new%(MAX_NUM_FILES))
list.init(in.files$())

' Available as a separate variable for convenience,
' but should always = list.size%(in.files$())
Dim in.num_open_files% = 0

Dim in.line_num(MAX_NUM_FILES)

Sub in.open(f$)
  Local f2$

  If list.size%(in.files$()) > 0 Then
    If Not fil.is_absolute%(f$) Then
      f2$ = fil.get_parent$(in.files$(0))
      If f2$ <> "" Then f2$ = f2$ + "/"
    EndIf
  EndIf
  f2$ = f2$ + f$

  If Not fil.exists%(f2$) Then err$ = "#Include file '" + f2$ + "' not found"
  If err$ = "" Then
    list.push(in.files$(), f2$)
    in.num_open_files% = list.size%(in.files$())
    Open f2$ For Input As #in.num_open_files%
    in.line_num(in.num_open_files% - 1) = 0
  EndIf
End Sub

Sub in.close()
  Close #in.num_open_files%
  Local s$ = list.pop$(in.files$())
  in.num_open_files% = list.size%(in.files$())
End Sub

Function in.readln$()
  Local s$
  Line Input #in.num_open_files%, s$
  in.readln$ = s$
  Local i = in.num_open_files% - 1
  in.line_num(i) = in.line_num(i) + 1
End Function
