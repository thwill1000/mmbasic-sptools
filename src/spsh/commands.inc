' Copyright (c) 2021-2024 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 6.00

' TODO
' ----
' Get it working on PicoMite
' File dates in 'ls'
' Allow 'cat' to write to a file
' Implement sys.run() without using EXECUTE
' Redirect output from 'ls' to a file
' Does EDIT work on the PicoMite ?
' Copy/Delete/Move directories
' Wildcards/Globbing
' Compact 'ls' output

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("console", "file", "string")
sys.provides("commands")
If sys.err$ <> "" Then Error sys.err$
'!endif

Const cmd.ALL_COMMANDS$ = " backup cd cat cp edit exit help ls mkdir mv pwd rm touch version "
Const cmd.EXIT_SUCCESS% = 0
Const cmd.EXIT_ERROR% = 1
Const cmd.MAX_FILES% = 200

Dim cmd.cmd$
Dim cmd.args$(9)
Dim cmd.num_args%
Dim cmd.errno%

Sub cmd.do_command()
  sys.err$ = ""
  cmd.errno% = cmd.EXIT_SUCCESS%
  If InStr(cmd.ALL_COMMANDS$, cmd.cmd$) Then Call("cmd." + cmd.cmd$) Else cmd.execute()
  If sys.err$ <> "" Then con.errorln("ERROR: " + sys.err$)
End Sub

Sub cmd.backup()
  If cmd.num_args% < 1 Then Error "expects 1 or more arguments"

  ' TODO: doesn't handle gaps in the list of backup files.

  Local f$, i%, j%
  For i% = 0 To cmd.num_args% - 1
    f$ = cmd.args$(i%)
    If Not file.exists%(f$) Then
      cmd.error_no_such_file(f$)
    ElseIf file.is_directory%(f$) Then
      cmd.error_not_a_file(f$)
    Else
      If file.exists%(f$ + ".10") Then Kill f$ + ".10"
      For j% = 9 To 1 Step -1
        If file.exists%(f$ + "." + Str$(j%)) Then
          Rename f$ + "." + Str$(j%) As f$ + "." + Str$(j% + 1)
        EndIf
      Next
      Copy f$ To f$ + ".1"
    EndIf
  Next
End Sub

Sub cmd.error_no_such_file(f$)
  con.errorln("No such file or directory: " + f$)
  cmd.errno% = cmd.EXIT_ERROR%
End Sub

Sub cmd.error_not_a_file(f$)
  con.errorln("Not a file: " + f$)
  cmd.errno% = cmd.EXIT_ERROR%
End Sub

Sub cmd.cd()
  If cmd.num_args% <> 1 Then Error "expects 1 argument"

  Local f$ = file.get_canonical$(cmd.args$(0))
  If f$ = "A:" Then ChDir(f$) : Exit Sub
  Select Case Mm.Info(FileSize f$)
    Case -2   : ChDir(f$)
    Case -1   : cmd.error_no_such_file(cmd.args$(0))
    Case Else : cmd.error_not_a_directory(cmd.args$(0))
  End Select
End Sub

Sub cmd.error_not_a_directory(f$)
  con.errorln("Not a directory: " + f$)
  cmd.errno% = cmd.EXIT_ERROR%
End Sub

Sub cmd.cat()
  If cmd.num_args% < 1 Then Error "expects 1 or more arguments"

  Local i%, f$, s$
  For i% = 0 To cmd.num_args% - 1
    f$ = cmd.args$(i%)
    If Not file.exists%(f$) Then
      cmd.error_no_such_file(f$)
    ElseIf file.is_directory%(f$) Then
      cmd.error_not_a_file(f$)
    Else
      Open f$ For Input As #1
      Do While Not Eof(#1)
        Line Input #1, s$
        con.println(s$)
      Loop
      Close #1
    EndIf
  Next
End Sub

' @param  move_flag%  if <> 0 then do a 'move' instead of a 'copy'.
Sub cmd.cp(move_flag%)
  If cmd.num_args% < 2 Then Error "expects 2 or more arguments"

  Local dst$ = cmd.args$(cmd.num_args% - 1)

  ' Error if try to copy over existing file.
  If file.exists%(dst$) And Not file.is_directory%(dst$) Then
    cmd.error_file_exists(dst$)
    Exit Sub
  EndIf

  ' Error if multiple sources and destination is not a directory.
  If cmd.num_args% > 2 And Not file.is_directory%(dst$) Then
    cmd.error_not_a_directory(dst$)
    Exit Sub
  EndIf

  Local f$, i%, src$
  For i% = 0 To cmd.num_args% - 2
    src$ = cmd.args$(i%)
    If Not file.exists%(src$) Then
      cmd.error_no_such_file(src$)
    ElseIf Not move_flag% And file.is_directory%(src$) Then
      cmd.error_not_a_file(src$)
    Else
      f$ = Choice(file.is_directory%(dst$), dst$ + "/" + file.get_name$(src$), dst$)
      If file.exists%(f$) Then
        cmd.error_file_exists(f$)
      ElseIf move_flag% Then
        Rename src$ As f$
      Else
        Copy src$ To f$
      EndIf
    EndIf
  Next
End Sub

Sub cmd.error_file_exists(f$)
  con.errorln("File already exists: " + f$)
  cmd.errno% = cmd.EXIT_ERROR%
End Sub

Sub cmd.edit()
  con.println("'edit' not supported on Colour Maximite 2 yet.")
End Sub

Sub cmd.execute()
  Local program$ = cmd.cmd$
  If LCase$(file.get_extension$(program$)) <> ".bas" Then Cat program$, ".bas"

  If Not file.exists%(program$) Then program$ = Mm.Info(Option Search Path) + program$

  If Not file.exists%(program$) Then
    con.errorln("No such file or command: " + program$)
    cmd.errno% = cmd.EXIT_ERROR%
  Else
    Local cmd_line$, i%
    For i% = 0 To cmd.num_args% - 1 : Cat cmd_line$, cmd.args$(i%) + " " : Next
    sys.run(program$, str.trim$(cmd_line$))
  EndIf
End Sub

' Executes a BASIC program.
'
' @param  program$   file path to the program.
' @param  cmd_line$  command line to execute the program with.
Sub sys.run(program$, cmd_line$)
  Local cmd$ = "RUN " + Chr$(34) + program$ + Chr$(34)
  If cmd_line$ <> "" Then Cat cmd$, ", " + cmd_line$

  Execute cmd$
'  Open "/tmp/spsh-run.bas" For Output As #1
'  Print #1, cmd$
'  Close #1
'  Run "/tmp/spsh-run.bas"
End Sub

Sub cmd.exit()
  End
End Sub

Sub cmd.help()
  con.println("Commands are:")
  con.println("  backup          create a backup copy of a file")
  con.println("  cd              change directory")
  con.println("  cat             print file to console")
  con.println("  cp              copy files and directories")
  con.println("  edit            edit file")
  con.println("  exit            exit the spsh shell")
  con.println("  help            print this help text")
  con.println("  ls              list directory contents")
  con.println("  mkdir           make directories")
  con.println("  mv              move (rename) files or directories")
  con.println("  pwd             print current working directory")
  con.println("  rm              remove files or directories")
  con.println("  touch           create an empty file")
  con.println("  version         print version information about spsh")
  con.println("  <program name>  execute the named program")
End Sub

Sub cmd.ls()
  If cmd.num_args% > 1 Then Error "expects 0 or 1 arguments"

  Local d$ = Choice(cmd.args$(0) = "", ".", cmd.args$(0))
  If file.is_directory%(d$) Then Cat d$, "/*"
  Local files$(cmd.MAX_FILES% - 1) Length 64
  d$ = cmd.get_files$(d$, files$())

  Local f$, fg$, i%, sz%
  For i% = 0 To Bound(files$(), 1)
    If files$(i%) = "" Then Exit For
    f$ = d$ + "/" + files$(i%)
    sz% = Mm.Info(FileSize f$)
    Select Case sz%
      Case -2 : fg$ = "blue" ' Directory
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

Function cmd.get_files$(f$, ofiles$())
  Local i%
  For i% = Bound(ofiles$(), 0) To Bound(ofiles$(), 1) : ofiles$(i%) = "" : Next
  Local d$ = file.get_canonical$(Choice(f$ = "", ".", f$))
  If (f$ = "A:") Or (Mm.Info(FileSize f$) = -2) Then
    ' Directory
    ofiles$(0) = file.get_name$(d$)
    cmd.get_files$ = file.get_parent$(d$)
    Exit Function
  Else
    Local pattern$ = file.get_name$(d$)
    d$ = file.get_parent$(d$)
  EndIf
  file.get_files(d$, pattern$, "all", ofiles$())
  cmd.get_files$ = d$
End Function


Sub cmd.mkdir()
  If cmd.num_args% < 1 Then Error "expects 1 or more arguments"

  Local f$, i%
  For i% = 0 To cmd.num_args% - 1
    f$ = cmd.args$(i%)
    If file.exists%(f$) Then
      cmd.error_file_exists(f$)
    Else
      MkDir f$
    EndIf
  Next
End Sub

Sub cmd.mv()
  cmd.cp(1)
End Sub

Sub cmd.pwd()
  con.println(Cwd$)
End Sub

Sub cmd.rm()
  If cmd.num_args% < 1 Then Error "expects 1 or more arguments"

  Local count%, d$, f$, i%, j%
  Local files$(cmd.MAX_FILES%) Length 64
  For i% = 0 To cmd.num_args% - 1
    d$ = cmd.get_files$(cmd.args$(i%), files$())
    count% = 0
    For j% = 0 To Bound(files$(), 1)
      f$ = files$(j%)
      If f$ = "" Then Exit For
      f$ = d$ + "/" + f$
      If Not file.exists%(f$) Then
        cmd.error_no_such_file(f$)
      ElseIf file.is_directory%(f$) Then
        cmd.error_not_a_file(f$)
        Inc count%
      Else
        ' Kill f$
        con.println("Delete " + f$)
        Inc count%
      EndIf
    Next
    If count% = 0 Then cmd.error_no_such_file(cmd.args$(i%))
  Next
End Sub

Sub cmd.touch()
  If cmd.num_args% < 1 Then Error "expects 1 or more arguments"

  Local f$, i%
  For i% = 0 To cmd.num_args% -1
    f$ = cmd.args$(i%)
    If file.exists%(f$) Then
      cmd.error_file_exists(f$)
    Else
      Open f$ For Output As #1
      Close #1
    EndIf
  Next
End Sub

Sub cmd.version()
  spt.print_version("spsh", , , "con.println")
End Sub
