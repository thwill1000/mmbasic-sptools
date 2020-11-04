' Copyright (c) 2020 Thomas Hugo Williams

' Stack of open input source files.
Const MAX_NUM_FILES = 5
Dim in.files$(MAX_NUM_FILES - 1)
Dim in.files_sz
list.init(in.files$(), MAX_NUM_FILES)

Dim in.line_num(MAX_NUM_FILES)

Sub in.open(f$)
  Local f2$

  If in.files_sz > 0 Then
    If Not fil.is_absolute%(f$) Then
      f2$ = fil.get_parent$(in.files$(0))
      If f2$ <> "" Then f2$ = f2$ + "/"
    EndIf
  EndIf
  f2$ = f2$ + f$

  If Not fil.exists%(f2$) Then err$ = "#Include file '" + f2$ + "' not found"
  If err$ = "" Then
    list.push(in.files$(), in.files_sz, f2$)
    Open f2$ For Input As #in.files_sz
    in.line_num(in.files_sz - 1) = 0
  EndIf
End Sub

Sub in.close()
  Close #in.files_sz
  Local s$ = list.pop$(in.files$(), in.files_sz)
End Sub

Function in.readln$()
  Local s$
  Line Input #in.files_sz, s$
  in.readln$ = s$
  Local i = in.files_sz - 1
  in.line_num(i) = in.line_num(i) + 1
End Function
