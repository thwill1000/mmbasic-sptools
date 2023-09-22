' Copyright (c) 2021-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Base 0
Option Default None
Option Explicit On

#Include "../splib/system.inc"
#Include "../splib/string.inc"
#Include "../splib/file.inc"
#Include "../common/sptools.inc"
#Include "console.inc"
#Include "commands.inc"

main()
End

Sub main()

  Local cmd_line$ = sys.cmdline$()
  If cmd_line$ <> "" Then parse(cmd_line$)
  If cmd.cmd$ <> "" Then
    cmd.do_command()

    ' Move cursor up one line on both VGA and Serial Console.
    Option Console Screen
    Local y% = Mm.Info(VPos) - Mm.Info(FontHeight)
    Print @(0, y%);
    Option Console Serial
    Print Chr$(27) "[A";
    Option Console Both

    End
  EndIf

  Do
    con.print("spsh$ ")
    cmd_line$ = con.readln$()
    parse(cmd_line$)
    If cmd.cmd$ <> "" Then cmd.do_command()
  Loop
End Sub

Function sys.cmdline$()
  sys.cmdline$ = str.trim$(Mm.CmdLine$)
End Function

Sub parse(cmd_line$)
  cmd.cmd$ = str.next_token$(cmd_line$)
  If cmd.cmd$ = sys.NO_DATA$ Then cmd.cmd$ = ""
  If Left$(cmd.cmd$, 1) = "*" Then cmd.cmd$ = Mid$(cmd.cmd$, 2)

  ' Read no more arguments than will fit in array and fill remainder with empty strings.
  cmd.num_args% = 0
  Local i%, s$
  For i% = 0 To Bound(cmd.args$(), 1)
    s$ = str.next_token$()
    If s$ = sys.NO_DATA$ Then s$ = "" Else Inc cmd.num_args%
    cmd.args$(i%) = s$
  Next
End Sub
