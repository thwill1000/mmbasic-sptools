' Copyright (c) 2020 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("array", "list", "string")
sys.provides("file")
If sys.err$ <> "" Then Error sys.err$

Const FIL.PROG_DIR$ = fil.get_parent$(Mm.Info$(Current))

' Does the file/directory 'f$' exist?
'
' @return 1 if the file exists, otherwise 0
Function fil.exists%(f$)
  Local f_$ = fil.get_canonical$(f$)
  If f_$ = "A:" Then
    fil.exists% = 1
  Else
    fil.exists% = Mm.Info(FileSize f_$) <> -1
  EndIf
End Function

' Find files whose names match pattern$
'
' @param   path$     root directory to start looking from.
' @param   pattern$  file pattern to match on, e.g. "*.bas".
' @param   type$     type of files to return, "dir", "file" or "all".
' @return  the absolute path to the first match found. To retrieve subsequent
'          matches call this function with no parameters, i.e. f$ = fil.find().
'          Returns the empty string if there are no more matches.
'
' TODO: In order to return the files in alphabetical order this uses a 128K workspace.
'       I think there is another potential implementation where it just records the last
'       file returned by the previous call and restarts the search from there, however
'       that would be much slower and probably better implemented as a CSUB.
Function fil.find$(path$, pattern$, type$)
  Static stack$(list.new%(1000)) Length 128 ' 128K workspace.
  Static pattern_$
  Static type_$
  Local base% = Mm.Info(Option Base)
  Local f$, is_dir%, lb%, name$, num%

  If path$ <> "" Then
    list.init(stack$())
    f$ = fil.get_canonical$(path$)
    list.push(stack$(), f$)
    pattern_$ = pattern$
    If pattern_$ = "" Then pattern_$ = "*"
    type_$ = UCase$(type$)
    If type_$ = "" Then type_$ = "FILE"
    If InStr("|ALL|DIR|FILE|", "|" + type_$ + "|") < 1 Then Error "unknown type: " + type_$
  EndIf

  Do
'    list.dump(stack$())
    Do
      fil.find$ = list.pop$(stack$())
      If fil.find$ = sys.NO_DATA$ Then fil.find$ = "" : Exit Function
      name$ = fil.get_name$(fil.find$)
    Loop Until name$ <> ".git" ' Doesn't recurse into .git directories.

    ' If it is a directory then expand it.
    is_dir% = fil.is_directory%(fil.find$)
    If is_dir% Then
      lb% = base% + list.size%(stack$())
      If type_$ = "DIR" Then f$ = Dir$(fil.find$ + "/*", Dir) Else f$ = Dir$(fil.find$ + "/*", All)
      Do While f$ <> ""
        list.push(stack$(), fil.find$ + "/" + f$)
        f$ = Dir$()
      Loop

      ' Sort the newly pushed dirs/files so that those beginning 'a|A'
      ' are at the top and those beginning 'z|Z' are near the bottom.
      num% = base% + list.size%(stack$()) - lb%
      If num% > 0 Then Sort stack$(), , &b11, lb%, num%)
    EndIf

    ' I've profiled it and its faster to do the name checks before the type checks.
    If fil.fnmatch%(pattern_$, name$) Then
      Select Case type_$
        Case "ALL"  : Exit Do
        Case "DIR"  : If is_dir% Then Exit Do
        Case "FILE" : If Not is_dir% Then Exit Do
      End Select
    EndIf

  Loop

End Function

' Does name$ match pattern$ ?
'
' @param   pattern$  *nix style 'shell wildcard' pattern.
' @param   name$     the name to test.
' @return  1 if the name matches the pattern otherwise 0.
'
' Derived from the work of Russ Cox: https://research.swtch.com/glob
Function fil.fnmatch%(pattern$, name$)
  Local p$ = UCase$(pattern$)
  Local n$ = UCase$(name$)
  Local c%, px% = 1, nx% = 1, nextPx% = 0, nextNx% = 0

  Do While px% <= Len(p$) Or nx% <= Len(n$)

    If px% <= Len(p$) Then

      c% = Peek(Var p$, px%)
      Select Case c%
        Case 42 ' *
          ' Zero-or-more-character wildcard
          ' Try to match at sx%,
          ' if that doesn't work out,
          ' restart at nx%+1 next.
          nextPx% = px%
          nextNx% = nx% + 1
          Inc px%
          Goto fil.fnmatch_cont

        Case 63 ' ?
          ' Single-character wildcard
          If nx% <= Len(n$) Then
            Inc px%
            Inc nx%
            Goto fil.fnmatch_cont
          EndIf

        Case Else
          ' Ordinary character
          If nx% <= Len(n$) Then
            If c% = Peek(Var n$, nx%) Then
              Inc px%
              Inc nx%
              Goto fil.fnmatch_cont
            EndIf
          EndIf
      End Select

    EndIf

    If nextNx% > 0 Then
      If nextNx% <= Len(n$) + 1 Then
        px% = nextPx%
        nx% = nextNx%
        Goto fil.fnmatch_cont
      EndIf
    EndIf

    Exit Function

    fil.fnmatch_cont:

  Loop

  fil.fnmatch% = 1

End Function

' Gets the canonical path for file/directory 'f$'.
Function fil.get_canonical$(f_$)
  Local f$ = f_$

  If fil.is_absolute%(f$) Then
    If Instr(UCase$(f$), "A:") <> 1 Then f$ = "A:" + f$
  Else
    f$ = Mm.Info$(Directory) + f$
  EndIf

  Local elements$(list.new%(20)) Length 128
  list.init(elements$())
  Local lb% = Bound(elements$(), 0)
  Local tk$ = str.next_token$(f$, "/\", 1)
  Do While tk$ <> sys.NO_DATA$
    list.add(elements$(), tk$)
    tk$ = str.next_token$()
  Loop
  elements$(lb%) = "A:"

  Local num_elements% = list.size%(elements$())
  Local i% = lb%
  Do While i% < lb% + num_elements%
    If elements$(i%) = "." Then
      list.remove(elements$(), i%)
    ElseIf elements$(i%) = ".." Then
      list.remove(elements$(), i%)
      list.remove(elements$(), i% - 1)
      Inc i%, -1
    Else
      Inc i%
    EndIf
  Loop

  fil.get_canonical$ = str.join$(elements$(), "/", lb%, list.size%(elements$()))
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
  If UCase$(f$) = "A:" Then Exit Function
  fil.is_absolute% = 0
End Function

Function fil.is_directory%(f$)
  Local f_$ = fil.get_canonical$(f$)
  If f_$ = "A:" Then
    fil.is_directory% = 1
  Else
    fil.is_directory% = Mm.Info(FileSize f_$) = -2
  EndIf
End Function

' Makes directory 'f$' if it does not already exist.
Sub fil.mkdir(f$)
  If Not fil.exists%(f$) Then MkDir f$
End Sub
