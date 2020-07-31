' Copyright (c) 2020 Thomas Hugo Williams

' Stack of open input source files.
Dim in_files$(MAX_NUM_FILES - 1)
Dim in_files_sz
list_init(in_files$(), MAX_NUM_FILES)

Dim cur_line_no(MAX_NUM_FILES)

Sub in_open(f$)
  Local f2$, p

  cout(Chr$(13)) ' CR

  If in_files_sz > 0 Then
    If Not fi_is_absolute(f$) Then
      f2$ = fi_get_parent$(in_files$(0))
      If f2$ <> "" Then f2$ = f2$ + "/"
    EndIf
  EndIf
  f2$ = f2$ + f$

  If Not fi_exists(f2$) Then
    err$ = "#Include file '" + f2$ + "' not found"
    Exit Sub
  EndIf
  cout(Space$(in_files_sz * 2) + f2$) : cendl()
  list_push(in_files$(), in_files_sz, f2$)
  Open f2$ For Input As #in_files_sz
  cout(Space$(1 + in_files_sz * 2))
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
  cur_line_no(i) = cur_line_no(i) + 1
End Function
