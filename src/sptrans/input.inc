' Copyright (c) 2020 Thomas Hugo Williams

' Stack of open input source files.
Const MAX_NUM_FILES = 5
Dim in_files$(MAX_NUM_FILES - 1)
Dim in_files_sz
list_init(in_files$(), MAX_NUM_FILES)

Dim in_line_num(MAX_NUM_FILES)

Sub in_open(f$)
  Local f2$

  If in_files_sz > 0 Then
    If Not fil.is_absolute%(f$) Then
      f2$ = fil.get_parent$(in_files$(0))
      If f2$ <> "" Then f2$ = f2$ + "/"
    EndIf
  EndIf
  f2$ = f2$ + f$

  If Not fil.exists%(f2$) Then err$ = "#Include file '" + f2$ + "' not found"
  If err$ = "" Then
    list_push(in_files$(), in_files_sz, f2$)
    Open f2$ For Input As #in_files_sz
    in_line_num(in_files_sz - 1) = 0
  EndIf
End Sub

Sub in_close()
  Close #in_files_sz
  Local s$ = list_pop$(in_files$(), in_files_sz)
End Sub

Function in_readln$()
  Local s$
  Line Input #in_files_sz, s$
  in_readln$ = s$
  Local i = in_files_sz - 1
  in_line_num(i) = in_line_num(i) + 1
End Function
