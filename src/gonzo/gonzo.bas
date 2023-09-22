#!/usr/local/bin/mmbasic -i

' Copyright (c) 2021-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 0.6.0

Option Base 0
Option Default None
Option Explicit On

#Include "../splib/system.inc"
#Include "../splib/array.inc"
#Include "../splib/map.inc"
#Include "../splib/string.inc"
#Include "../splib/inifile.inc"
#Include "../splib/file.inc"
#Include "../common/sptools.inc"
#Include "history.inc"
#Include "console.inc"
#Include "spsh.inc"
#Include "gonzo.inc"
#Include "command.inc"

Option CodePage "CMM2"

Const INI_FILE = gonzo.DOT_DIR$ + "/gonzo.ini"
Const HISTORY_FILE = gonzo.DOT_DIR$ + "/gonzo.history"
Const HISTORY_FNBR = gonzo.INI_FNBR

main()
End

Sub main()
  Local argc%, argv$(array.new%(10)), cmd$
  Local cmd_line$ = str.trim$(Mm.CmdLine$), result%

  If file.mkdir%("~/.gonzo") <> sys.SUCCESS Then Error sys.err$

  If Not gonzo.load_inifile%(INI_FILE) Then
    con.errorln(sys.err$)
    Exit Sub
  EndIf

  sys.override_break()

  If cmd_line$ <> "" Then gonzo.parse_cmd_line(cmd_line$, cmd$, argc%, argv$())

  Select Case cmd$
    Case ""
      con.cls()
      con.foreground("yellow")
      con.println("Welcome to gonzo v" + sys.format_version$())
    Case "-v", "--version"
      result% = cmd.do_command%("version", 0, argv$())
      cmd$ = "exit"
  End Select

  If cmd$ <> "exit" Then gonzo.connect(cmd$ = "");

  If cmd$ <> "" Then
    result% = cmd.do_command%(cmd$, argc%, argv$())

    If Mm.Device$ <> "MMB4L" Then
      ' Move cursor up one line on both VGA and Serial Console.
      Option Console Screen
      Local y% = Mm.Info(VPos) - Mm.Info(FontHeight)
      Print @(0, y%);
      Option Console Serial
      Print Chr$(27) "[A";
      Option Console Both
    EndIf

    sys.restore_break()
    End
  EndIf

  If file.exists%(HISTORY_FILE) Then
    history.load(gonzo.history%(), HISTORY_FILE, HISTORY_FNBR)
  EndIf

  Do
    sys.break_flag% = 0
    con.foreground("yellow")
    con.print("gonzo$ ")
    cmd_line$ = con.readln$("", gonzo.history%(), HISTORY_FILE, HISTORY_FNBR)
    If sys.break_flag% Then con.println() : Exit Do
    gonzo.parse_cmd_line(cmd_line$, cmd$, argc%, argv$())
    ' con.foreground("default")
  Loop Until Choice(cmd$ = "", 0, cmd.do_command%(cmd$, argc%, argv$()))

  If Not gonzo.save_inifile%(INI_FILE) Then con.errorln(sys.err$)
  sys.restore_break()
  If Pos > 1 Then con.cursor_previous() ' So that we don't get an extra newline when program ends.
End Sub
