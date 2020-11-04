' Copyright (c) 2020 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.05

Const FIL.PROG_DIR$ = fil.get_parent$(Mm.Info$(Current))

Function check_file_included() : check_file_included = 1 : End Function

' Does the file/directory 'f$' exist?
'
' @return 1 if the file exists, otherwise 0
Function fil.exists%(f$)
  On Error Skip
  fil.exists% = LCase$(Dir$(f$, ALL)) = LCase$(fil.get_name$(f$))
End Function

' Gets the canonical path for file/directory 'f$'.
Function fil.get_canonical$(f$)
  Local i%
  Local sz% = 20
  Local elements$(sz% - 1) Length 40

  list.init(elements$(), sz%)

  If fil.is_absolute%(f$) Then
    If Instr(UCase$(f$), "A:") = 1 Then
      str.tokenise(f$, "/\", elements$(), sz%)
    Else
      str.tokenise("A:" + f$, "/\", elements$(), sz%)
    EndIf
  Else
    str.tokenise(Cwd$ + "/" + f$, "/\", elements$(), sz%)
  EndIf

  elements$(0) = "A:"

  Do While i% < sz%
    If elements$(i%) = "." Then
      list.remove(elements$(), sz%, i%)
    ElseIf elements$(i%) = ".." Then
      list.remove(elements$(), sz, i%)
      list.remove(elements$(), sz, i% - 1)
      i% = i% - 1
    Else
      i% = i% + 1
    EndIf
  Loop

  fil.get_canonical$ = str.join$(elements$(), sz%, "/")
End Function

' Gets the name of file/directory 'f$' minus any path information.
Function fil.get_name$(f$)
  Local i%

  For i% = Len(f$) To 1 Step -1
    If InStr("/\", Mid$(f$, i%, 1)) > 0 Then Exit For
  Next i%

  fil.get_name$ = Mid$(f$, i% + 1)
End Function

' Gets the parent directory of 'f$', or the empty string if it does not have one.
Function fil.get_parent$(f$)
  Local i%

  For i% = Len(f$) To 1 Step -1
    If InStr("/\", Mid$(f$, i%, 1)) > 0 Then Exit For
  Next i%

  If i% > 0 Then fil.get_parent$ = Left$(f$, i% - 1)
End Function

Function fil.is_absolute%(f$)
  fil.is_absolute% = 1
  If InStr(f$, "/") = 1 Then Exit Function
  If InStr(f$, "\") = 1 Then Exit Function
  If InStr(UCase$(f$), "A:\") = 1 Then Exit Function
  If InStr(UCase$(f$), "A:/") = 1 Then Exit Function
  fil.is_absolute% = 0
End Function

' Makes directory 'f$' if it does not already exist.
Sub fil.mkdir(f$)
  If Not fil.exists%(f$) Then MkDir f$
End Sub

