' Copyright (c) 2021-2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 2022.01.00

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("console", "file", "string")
sys.provides("spsh")
If sys.err$ <> "" Then Error sys.err$

Const spsh.IN_FNBR% = 2
Const spsh.MAX_FILES% = 200

Sub spsh.cmd_chdir(cmd$, argc%, argv$())
  If argc% <> 1 Then Error "expects 1 argument"

  Local f$ = file.get_canonical$(argv$(0))
  If f$ = "A:" Then ChDir(f$) : Exit Sub
  Select Case Mm.Info(FileSize f$)
    Case -2   : ChDir(f$)
    Case -1   : spsh.error_no_such_file(argv$(0))
    Case Else : spsh.error_not_a_directory(argv$(0))
  End Select
End Sub

Sub spsh.error_no_such_file(f$)
  sys.err$ = "Error: no such file or directory: " + f$
End Sub

Sub spsh.error_not_a_directory(f$)
  sys.err$ = "Error: not a directory: " + f$
End Sub

Sub spsh.error_not_a_file(f$)
  sys.err$ = "Error: not a file: " + f$
End Sub

Sub spsh.error_file_exists(f$)
  sys.err$ = "Error: file already exists: " + f$
End Sub

' @param  move_flag%  if <> 0 then do a 'move' instead of a 'copy'.
Sub spsh.cmd_copy(cmd$, argc%, argv$(), move_flag%)
  If argc% < 2 Then Error "expects 2 or more arguments"

  Local dst$ = argv$(argc% - 1)

  ' Error if try to copy over existing file.
  If file.exists%(dst$) And Not file.is_directory%(dst$) Then
    spsh.error_file_exists(dst$)
    Exit Sub
  EndIf

  ' Error if multiple sources and destination is not a directory.
  If argc% > 2 And Not file.is_directory%(dst$) Then
    spsh.error_not_a_directory(dst$)
    Exit Sub
  EndIf

  Local f$, i%, src$
  For i% = 0 To argc% - 2
    src$ = argv$(i%)
    If Not file.exists%(src$) Then
      spsh.error_no_such_file(src$)
    ElseIf Not move_flag% And file.is_directory%(src$) Then
      spsh.error_not_a_file(src$)
    Else
      f$ = Choice(file.is_directory%(dst$), dst$ + "/" + file.get_name$(src$), dst$)
      If file.exists%(f$) Then
        spsh.error_file_exists(f$)
      ElseIf move_flag% Then
        Rename src$ As f$
      Else
        Copy src$ To f$
      EndIf
    EndIf
  Next
End Sub

Sub spsh.cmd_files(cmd$, argc%, argv$())
  If argc% > 1 Then Error "expects 0 or 1 arguments"

  Local d$ = Choice(argv$(0) = "", ".", argv$(0))
  If file.is_directory%(d$) Then Cat d$, "/*"
  Select Case Mm.Device$
    Case "MMB4L", "MMBasic for Windows"
      Local files$(spsh.MAX_FILES% - 1)
    Case Else
      Local files$(spsh.MAX_FILES% - 1) Length 64
  End Select
  d$ = spsh.get_files$(d$, files$())

  Local f$, fg$, i%, sz%
  For i% = 0 To Bound(files$(), 1)
    If files$(i%) = "" Then Exit For
    f$ = d$ + "/" + files$(i%)
    sz% = Mm.Info(FileSize f$)
    Select Case sz%
      Case -2 : fg$ = "bright blue" ' Directory
      Case Else
        Select Case LCase$(file.get_extension$(f$))
          Case ".bas" : fg$ = "green"
          Case ".inc" : fg$ = "magenta"
          Case Else   : fg$ = "default"
        End Select
    End Select
    con.foreground("default")
    con.print(Choice(sz% < 0, " <DIR>", str.lpad$(Str$(sz%), 6)))
    con.foreground(fg$)
    con.println(" " + files$(i%))
  Next
  con.foreground("default")
End Sub

Function spsh.get_files$(f$, out$())
  Local i%
  For i% = Bound(out$(), 0) To Bound(out$(), 1) : out$(i%) = "" : Next
  Local d$ = file.get_canonical$(Choice(f$ = "", ".", f$))
  If (f$ = "A:") Or (Mm.Info(FileSize f$) = -2) Then
    ' Directory
    out$(0) = file.get_name$(d$)
    spsh.get_files$ = file.get_parent$(d$)
    Exit Function
  Else
    Local pattern$ = file.get_name$(d$)
    d$ = file.get_parent$(d$)
  EndIf
  file.get_files(d$, pattern$, "all", out$())
  spsh.get_files$ = d$
End Function

Sub spsh.cmd_pwd(cmd$, argc%, argv$())
  If argc% <> 0 Then Error "expects 0 arguments")
  con.println(Cwd$)
End Sub

Sub spsh.cmd_rename(cmd$, argc%, argv$())
  spsh.cmd_copy(cmd$, argc%, argv$(), 1)
End Sub

Sub spsh.cmd_type(cmd$, argc%, argv$())
  If argc% < 1 Then Error "expects 1 or more arguments")

  Local i%, f$, s$
  For i% = 0 To argc% - 1
    f$ = str.unquote$(argv$(i%))
    If Not file.exists%(f$) Then
      spsh.error_no_such_file(f$)
    ElseIf file.is_directory%(f$) Then
      spsh.error_not_a_file(f$)
    Else
      Open f$ For Input As #spsh.IN_FNBR%
      Do While Not Eof(#spsh.IN_FNBR%)
        Line Input #spsh.IN_FNBR%, s$
        con.println(s$)
      Loop
      Close #spsh.IN_FNBR%
    EndIf
  Next
End Sub
