' Copyright (c) 2020 Thomas Hugo Williams

Function check_file_included() : End Function

' Gets the parent directory of 'f$', or the empty string if it does not have one.
Function fi_get_parent$(f$)
  Local c, i

  For i = Len(f$) To 1 Step -1
    c = Asc(Mid$(f$, i, 1))
    ' ASCII 47= / and ASCII 92 = \
    If c = 47 Or c = 92 Then Exit For
  Next i
  If i = 0 Then
    fi_get_parent$ = ""
  Else
    fi_get_parent$ = Left$(f$, i - 1)
  EndIf
End Function

' Gets the name of file/directory 'f$' minus any path information.
Function fi_get_name$(f$)
  Local c, i

  For i = Len(f$) To 1 Step -1
    c = Asc(Mid$(f$, i, 1))
    ' ASCII 47= / and ASCII 92 = \
    If c = 47 Or c = 92 Then Exit For
  Next i
  fi_get_name$ = Mid$(f$, i + 1)
End Function

Function fi_is_absolute(f$)
  fi_is_absolute = 1
  If InStr(f$, "/") = 1 Then Exit Function
  If InStr(f$, "\") = 1 Then Exit Function
  If InStr(UCase$(f$), "A:\") = 1 Then Exit Function
  If InStr(UCase$(f$), "A:/") = 1 Then Exit Function
  fi_is_absolute = 0
End Function

' Gets the canonical path for file/directory 'f$'.
Function fi_get_canonical$(f$)
  Local i
  Local sz = 20
  Local elements$(sz - 1) Length 40

  list_init(elements$(), sz)

  If fi_is_absolute(f$) Then
    If Instr(UCase$(f$), "A:") = 1 Then
      str_tokenise(f$, "/\", elements$(), sz)
    Else
      str_tokenise("A:" + f$, "/\", elements$(), sz)
    EndIf
  Else
    str_tokenise(Cwd$ + "/" + f$, "/\", elements$(), sz)
  EndIf

  elements$(0) = "A:"

  Do While i < sz
    If elements$(i) = "." Then
      list_remove(elements$(), sz, i)
    ElseIf elements$(i) = ".." Then
      list_remove(elements$(), sz, i)
      list_remove(elements$(), sz, i - 1)
      i = i - 1
    Else
      i = i + 1
    EndIf
  Loop

  fi_get_canonical$ = str_join$(elements$(), sz, "/")
End Function

' Does the file/directory 'f$' exist?
'
' @return  1 if the file exists, otherwise 0.
Function fi_exists(f$)
  fi_exists = Mm.Info(FileSize fi_get_canonical$(f$)) <> -1
End Function
