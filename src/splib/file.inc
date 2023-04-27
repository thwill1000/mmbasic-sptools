' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!ifndef NO_INCLUDE_GUARDS
On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.provides("file")
If sys.err$ <> "" Then Error sys.err$
'!endif

' Gets the number of files in directory d$ whose names match pattern$.
'
' @param   d$        directory to process.
' @param   pattern$  file pattern to match on, e.g. "*.bas".
' @param   type$     type of files to return, "dir", "file" or "all".
' @return  the number of matching files.
Function file.count_files%(d$, pattern$, type$)
  If Not file.is_directory%(d$) Then
    file.count_files% = sys.error%(sys.FAILURE, "Not a directory '" + d$ + "'")
    Exit Function
  EndIf

  Local f$
  Select Case LCase$(type$)
    Case "all"      : f$ = Dir$(d$ + "/*", All)
    Case "dir"      : f$ = Dir$(d$ + "/*", Dir)
    Case "file", "" : f$ = Dir$(d$ + "/*", File)
    Case Else
      file.count_files% = sys.error%(sys.FAILURE, "Invalid file type '" + type$ + "'")
      Exit Function
    EndIf
  End Select

  Do While f$ <> ""
    If file.fnmatch%(pattern$, f$) Then Inc file.count_files%
    f$ = Dir$()
  Loop
End Function

' Does the file/directory 'f$' exist?
'
' @return 1 if the file exists, otherwise 0
Function file.exists%(f$)
  Select Case f$
    Case ""
      ' file.exists% = 0
    Case "."
      file.exists% = 1
    Case Else
      If Mm.Device$ = "MMB4L" Or Mm.Device$ = "MMBasic for Windows" Then
        file.exists% = Mm.Info(Exists f$)
      Else
        file.exists% = Mm.Info(Exists File f$) Or Mm.Info(Exists Dir f$)
    EndIf
  End Select
End Function

' Find files whose names match pattern$
'
' @param   path$     root directory to start looking from.
' @param   pattern$  file pattern to match on, e.g. "*.bas".
' @param   type$     type of files to return, "dir", "file" or "all".
' @return  the absolute path to the first match found. To retrieve subsequent
'          matches call this function with no parameters, i.e. f$ = file.find().
'          Returns the empty string if there are no more matches.
'
' TODO: In order to return the files in alphabetical order this uses a 128K
'       workspace. I think there is an alternative implementation where it
'       just records the last file returned by the previous call and restarts
'       the search from there, however that would be much slower and probably
'       better implemented as a CSUB.
'       Alternatively need to use a more efficient way to store strings
'       (a pool?), or take advantage of the fact they have common prefixes.
Function file.find$(path$, pattern$, type$)
  Static stack_ptr%, pattern_$, type_$
  Local f$, is_dir%, lb%, name$, num%

  If path$ <> "" Then

    ' Allocate stack/workspace:
    '   ~256K workspace for MMB4L and MMB4W
    '   ~64K workspace for other platforms.
    ' Uses a GLOBAL rather than a STATIC because creation of STATICs requires
    ' temporary allocation of twice as much memory.
    On Error Skip
    Erase file.find_stack$()
    If sys.is_device%("mmb4l", "mmb4w") Then
      Dim file.find_stack$(1000) Length 255
    Else
      Dim file.find_stack$(500) Length 128
    EndIf

    stack_ptr% = Bound(file.find_stack$(), 0)
    pattern_$ = Choice(pattern$ = "", "*", pattern$)
    type_$ = Choice(type$ = "", "FILE", LCase$(type$))
    f$ = file.get_canonical$(path$)
    file.find_stack$(stack_ptr%) = f$ : Inc stack_ptr%
    If Not InStr("|all|dir|file|", "|" + type_$ + "|") Then
      Error "Invalid file type '" + type_$ + "'"
      Exit Function ' So we stop even if errors are being ignored.
    EndIf

  EndIf

  Do
    Do
      If stack_ptr% = Mm.Info(Option Base) Then file.find$ = "" : Exit Function
      Inc stack_ptr%, -1
      file.find$ = file.find_stack$(stack_ptr%)
      name$ = file.get_name$(file.find$)
    Loop Until name$ <> ".git" ' Doesn't recurse into .git directories.

    ' If it is a directory and not a symbolic-link then expand it.
    is_dir% = 0
    If file.is_directory%(file.find$) Then
      If Not file.is_symlink%(file.find$) Then
        is_dir% = 1
        lb% = stack_ptr%

        ' Add all sub-directories.
        f$ = Dir$(file.find$ + "/*", Dir)
        Do While f$ <> ""
          If InStr("|.|..|", "|" + f$ + "|") Then
            Error "DIR$() returned '" + f$ + "'"
            Exit Function
          ElseIf stack_ptr% > Bound(file.find_stack$(), 1) Then
            Error "Too many files"
            Exit Function ' So we stop even if errors are being ignored.
          EndIf
          file.find_stack$(stack_ptr%) = file.find$  + "/" + f$
          Inc stack_ptr%
          f$ = Dir$()
        Loop

        ' Add all files matching pattern.
        If type_$ <> "dir" Then
          ' f$ = Dir$(file.find$ + "/*", File)
          f$ = Dir$(file.find$ + "/" + pattern_$, File)
          Do While f$ <> ""
            If InStr("|.|..|", "|" + f$ + "|") Then
              Error "DIR$() returned '" + f$ + "'"
              Exit Function
            ElseIf stack_ptr% > Bound(file.find_stack$(), 1) Then
              Error "Too many files"
              Exit Function ' So we stop even if errors are being ignored.
            EndIf
            ' If file.fnmatch%(pattern_$, f$) Then
            file.find_stack$(stack_ptr%) = file.find$  + "/" + f$
            Inc stack_ptr%
            ' EndIf
            f$ = Dir$()
          Loop
        EndIf

        ' Sort the newly pushed dirs/files so that those beginning 'a|A'
        ' are at the top and those beginning 'z|Z' are near the bottom.
        num% = stack_ptr% - lb%
        If num% > 0 Then Sort file.find_stack$(), , &b11, lb%, num%
      EndIf
    EndIf

    If is_dir% Then
      If InStr("all|dir", type_$) Then
        If file.fnmatch%(pattern_$, name$) Then Exit Do
      EndIf
    Else
      If InStr("all|file", type_$) Then Exit Do
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
Function file.fnmatch%(pattern$, name$)
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
          Goto file.fnmatch_cont

        Case 63 ' ?
          ' Single-character wildcard
          If nx% <= Len(n$) Then
            Inc px%
            Inc nx%
            Goto file.fnmatch_cont
          EndIf

        Case Else
          ' Ordinary character
          If nx% <= Len(n$) Then
            If c% = Peek(Var n$, nx%) Then
              Inc px%
              Inc nx%
              Goto file.fnmatch_cont
            EndIf
          EndIf
      End Select

    EndIf

    If nextNx% > 0 Then
      If nextNx% <= Len(n$) + 1 Then
        px% = nextPx%
        nx% = nextNx%
        Goto file.fnmatch_cont
      EndIf
    EndIf

    Exit Function

    file.fnmatch_cont:

  Loop

  file.fnmatch% = 1

End Function

' Gets the canonical path for file/directory 'f$'.
Function file.get_canonical$(f$)
  Local tmp$ = f$

  Select Case Left$(tmp$, 1)
    Case "/", "\"
      tmp$ = "A:" + tmp$
    Case "~"
      If tmp$ = "~" Then
        tmp$ = sys.string_prop$("home")
      ElseIf Left$(tmp$, 2) = "~/" Or Left$(tmp$, 2) = "~\" Then
        tmp$ = sys.string_prop$("home") + Mid$(tmp$, 2)
      Else
        tmp$ = Mm.Info$(Directory) + tmp$
      EndIf
    Case "a" To "z", "A" To "Z"
      If Mid$(tmp$, 2, 1) = ":" Then
        ' Do nothing
      Else
        tmp$ = Mm.Info$(Directory) + tmp$
      EndIf
    Case Else
      tmp$ = Mm.Info$(Directory) + tmp$
  End Select

  ' Convert backslash to slash to simplify algorithm.
  ' On Windows we convert back to backslash before returning the result.
  Local i%
  For i% = 1 To Len(tmp$)
    If Peek(Var tmp$, i%) = 92 Then Poke Var tmp$, i%, 47
  Next

  ' Capitalise first letter of a drive specification.
  If Mid$(tmp$, 2, 1) = ":" Then Poke Var tmp$, 1, Asc(UCase$(Chr$(Peek(Var tmp$, 1))))

  ' Ensure there is a trailing slash,
  ' this helps with the next step and is ultimately stripped off.
  If Right$(tmp$, 1) <> "/" Then Cat tmp$, "/"

  ' Process dot, dot-dot and consecutive slash characters.
  file.get_canonical$ = tmp$
  tmp$ = ""
  Local ch%, j%, s$ = ""
  For i% = 1 To Len(file.get_canonical$) + 1
    ch% = Peek(Var file.get_canonical$, i%)
    Select Case ch%
      Case 47 ' /
        Select Case s$
          Case "/", "/."
            ' Do nothing
          Case "/.."
            ' Back track
            For j% = Len(tmp$) To 1 Step -1
              If Peek(Var tmp$, j%) = 47 Then
                Poke Var tmp$, 0, j% - 1 : Exit For
              EndIf
            Next
          Case Else
            Cat tmp$, s$
        End Select
        s$ = "/"
      Case Else
        Cat s$, Chr$(ch%)
    End Select
  Next

  ' On Windows convert slash to backslash.
  If Mm.Device$ = "MMBasic for Windows" Then
    For i% = 1 To Len(tmp$)
      If Peek(Var tmp$, i%) = 47 Then Poke Var tmp$, i%, 92
    Next
  EndIf

  file.get_canonical$ = tmp$
End Function

' Gets the dot file-extension, from filename f$.
' e.g. file.get_extension("foo.bas") => ".bas"
Function file.get_extension$(f$)
  Local i%
  For i% = Len(f$) To 1 Step -1
    Select Case Peek(Var f$, i%)
      Case 46     ' .
        file.get_extension$ = Mid$(f$, i%)
        Exit Function
      Case 47, 92 ' / or \
        Exit For
    End Select
  Next
End Function

' Gets the files in directory d$ whose names match pattern$.
'
' @param       d$        directory to process.
' @param       pattern$  file pattern to match on, e.g. "*.bas".
' @param       type$     type of files to return, "dir", "file" or "all".
' @param[out]  out$()    the names of matching files are copied into this array.
' @return                the number of files matching the pattern.
Function file.get_files%(d$, pattern$, type$, out$())
  If Not file.is_directory%(d$) Then
    file.get_files% = sys.error%(sys.FAILURE, "Not a directory '" + d$ + "'")
    Exit Function
  EndIf

  Local f$
  Select Case LCase$(type$)
    Case "all"      : f$ = Dir$(d$ + "/*", All)
    Case "dir"      : f$ = Dir$(d$ + "/*", Dir)
    Case "file", "" : f$ = Dir$(d$ + "/*", File)
    Case Else
      file.get_files% = sys.error%(sys.FAILURE, "Invalid file type '" + type$ + "'")
      Exit Function
  End Select

  Do While f$ <> ""
    If file.fnmatch%(pattern$, f$) Then
      out$(file.get_files% + Mm.Info(Option Base)) = f$
      Inc file.get_files%
    EndIf
    f$ = Dir$()
  Loop

  If file.get_files% > 0 Then
    Sort out$(), , &b10, Mm.Info(Option Base), file.get_files%
  EndIf
End Function

' Gets the name of file/directory 'f$' minus any path information.
Function file.get_name$(f$)
  Local i%

  For i% = Len(f$) To 1 Step -1
    If InStr("/\", Mid$(f$, i%, 1)) > 0 Then Exit For
  Next i%

  file.get_name$ = Mid$(f$, i% + 1)
End Function

' Gets the parent directory of 'f$', or the empty string if it does not have one.
Function file.get_parent$(f$)
  Local i%

  For i% = Len(f$) To 1 Step -1
    If InStr("/\", Mid$(f$, i%, 1)) > 0 Then Exit For
  Next i%

  If i% > 0 Then file.get_parent$ = Left$(f$, i% - 1)
End Function

Function file.is_absolute%(f$)
  Select Case Left$(f$, 1)
    Case "a", "A"
      Select Case Mid$(f$, 2, 2)
        Case ":", ":\", ":/" : file.is_absolute% = 1
      End Select
    Case "/", "\"
      file.is_absolute% = 1
  End Select
End Function

Function file.is_directory%(f$)
  ' TODO: handle ~ prefix
  ' TODO: does this work on PicoMite
  Select Case f$
    Case ""
      ' file.is_directory% = 0
    Case "."
      file.is_directory% = 1
    Case Else
      file.is_directory% = Mm.Info(Exists Dir f$)
  End Select
End Function

Function file.is_symlink%(f$)
  If Mm.Device$ = "MMB4L" Then
    file.is_symlink% = Mm.Info(Exists SymLink f$)
  EndIf
End Function

' Makes directory 'f$' and its parents if they do not already exist.
Function file.mkdir%(f$)
  Local ad%, faddr% = Peek(VarAddr f$), parent$
  sys.err$ = ""
  For ad% = faddr% To faddr% + Len(f$)
    Select Case Peek(Byte ad%)
      Case 47, 92 ' / and \
        parent$ = Left$(f$, ad% - faddr% - 1)
        If file.exists%(parent$) Then
          If Not file.is_directory%(parent$) Then
            file.mkdir% = sys.error%(sys.FAILURE, "File exists")
            Exit Function
          EndIf
        Else
          If parent$ <> "" Then MkDir parent$
        EndIf
    End Select
  Next
  If file.exists%(f$) Then
    If Not file.is_directory%(f$) Then file.mkdir% = sys.error%(sys.FAILURE, "File exists")
  Else
    MkDir f$
  EndIf
End Function

' Performs depth-first recursion of the filesystem from a given root$
' calling the supplied callback$ function for each file encountered.
'
' @param  root$      Root of the traversal.
' @param  callback$  Callback function to call, first parameter should be a string (the absolute
'                    filename of the file node being processed) and return 0 on success.
' @param  xtra%      Value to be passed as second argument to callback.
'                    This could be used to pass the address of a value other than an integer.
' @return            0 on success, or if a callback function returns a non-zero value then the
'                    traversal stops and that value is returned.
Function file.depth_first%(root$, callback$, xtra%)
  Local root_$ = file.get_canonical$(root$)
  If Not file.exists%(root_$) Then
    file.depth_first% = sys.error%(sys.FAILURE, "No such file or directory '" + root_$ + "'")
    Exit Function
  EndIf

  Local depth% = 0, current$ = root_$, name$, parent$
  Local f$ = Choice(file.is_directory%(root_$) And Not file.is_symlink%(root_$), Dir$(root_$ + "/*", All), "")
  Do While file.depth_first% = sys.SUCCESS
    If InStr("|.|..|", "|" + f$ + "|") Then
      Error "DIR$() returned '" + f$ + "'"
      Exit Function
    ElseIf f$ = "" Then ' No more entries.
      If current$ <> root_$ Then
        ' Protection from accidentally navigating above root$ which would
        ' have disasterous consequences if performing a recursive delete.
        Inc depth%, -1
        If depth% < 0 Then
          Error "Safety check failed!"
          Exit Function ' So we stop even if errors are being ignored.
        EndIf

        ' Update f$ to point to the entry after current$ in its parent;
        ' traversal will continue from there.
        name$ = file.get_name$(current$)
        parent$ = file.get_parent$(current$)
        f$ = Dir$(parent$ + "/*", All)
        Do While f$ <> name$ : f$ = Dir$() : Loop
        f$ = Dir$()
      EndIf

      ' Note that unless we are acting on the root$ we will have navigated to
      ' the parent before calling the callback$, this is essential if the
      ' callback deletes or renames the directory.
      file.depth_first% = Call(callback$, current$, xtra%)
      If current$ = root_$ Then Exit Do
      current$ = parent$
    Else
      f$ = current$ + "/" + f$
      If file.is_symlink%(f$) Then
        file.depth_first% = Call(callback$, f$, xtra%)
        f$ = Dir$()
      ElseIf file.is_directory%(f$) Then
        current$ = f$
        f$ = Dir$(current$ + "/*", All)
        Inc depth%
      Else
        file.depth_first% = Call(callback$, f$, xtra%)
        f$ = Dir$()
      EndIf
    EndIf
  Loop
End Function

Function file.delete%(f$, yes_to_all%)
  Local f_$ = file.get_canonical$(f$), is_root%
  Select Case Len(f_$)
    Case 1 : is_root% = InStr("/\", f_$)
    Case 2 : is_root% = Mid$(f_$, 2, 1) = ":"
    Case 3 : is_root% = Mid$(f_$, 2, 1) = ":" And InStr("/\", Mid$(f_$, 3, 1))
  End Select
  If is_root% Then
    file.delete% = sys.error%(sys.FAILURE, "Cannot delete '" + f_$ + "'")
  Else
    file.delete% = file.depth_first%(f_$, "file.delete_callback%", yes_to_all%)
  EndIf
End Function

Function file.delete_callback%(f$, yes_to_all%)
  Local s$ = Choice(yes_to_all%, "y", "n")
  If s$ = "n" Then Line Input "Delete '" + f$ + "' [y|N] ? ", s$
  If LCase$(s$) = "y" Then
    If file.is_directory%(f$) And Not file.is_symlink%(f$) Then RmDir f$ Else Kill f$
  EndIf
End Function

' Returns a copy of f$ with any dot file-extension removed.
' e.g. file.trim_extension("foo.bas") => "foo"
Function file.trim_extension$(f$)
  Local i%
  For i% = Len(f$) To 1 Step -1
    Select Case Peek(Var f$, i%)
      Case 46     ' .
        file.trim_extension$ = Mid$(f$, 1, i% - 1)
        Exit Function
      Case 47, 92 ' / or \
        Exit For
    End Select
  Next
  file.trim_extension$ = f$
End Function
