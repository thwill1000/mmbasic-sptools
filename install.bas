' Copyright (c) 2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Base 0
Option Default None
Option Explicit On

#Include "src/splib/system.inc"
#Include "src/splib/array.inc"
#Include "src/splib/list.inc"
#Include "src/splib/string.inc"
#Include "src/splib/file.inc"

Const BIN_DIR$ = Mm.Info(Search Path)
Const SHELL_PROGRAM$ = "src/spsh/spsh.bas"

main()
End

Sub main()
  install_programs()
  install_shell_commands()
End Sub

Sub install_programs()
  install_program(SHELL_PROGRAM$)
  install_program(SHELL_PROGRAM$, "sh")
  install_program("src/spfind/spfind")
  install_program("src/spflow/main", "spflow")
  install_program("src/sptest/sptest")
  install_program("src/sptrans/main", "sptrans")
End Sub

Sub install_program(src_$, dst_$)
  Local src$ = Mm.Info(Path) + src_$
  If LCase$(file.get_extension$(src$)) <> ".bas" Then Cat src$, ".bas"
  Local dst$ = BIN_DIR$ + Choice(dst_$ = "", file.get_name$(src_$), dst_$)
  If LCase$(file.get_extension$(dst$)) <> ".bas" Then Cat dst$, ".bas"

  Print "Installing '" src$ "' to '" dst$

  write_file(dst$, src$, "")
End Sub

Sub write_file(f$, program$, cmd_line$)
  backup(f$)

  Open f$ For Output As #1
  Local s$ = "Execute @Run @ + Chr$(34) + @"
  Cat s$, program$
  Cat s$, "@ + Chr$(34) + @, "
  If cmd_line$ <> "" Then Cat s$, cmd_line$ + " "
  Cat s$, "@ + Mm.CmdLine$")
  Print #1, str.replace$(s$, "@", Chr$(34))
  Close #1
End Sub

' Maintain up to 5 backups of each file.
Sub backup(f$)
  If Not file.exists%(f$) Then Exit Sub
  If file.is_directory%(f$) Then Error "Not a file: " + f$
  If file.exists%(f$ + ".5") Then Kill f$ + ".5"
  Local i%
  For i% = 4 To 1 Step -1
    If file.exists%(f$ + "." + Str$(i%)) Then
      Rename f$ + "." + Str$(i%) As f$ + "." + Str$(i% + 1)
    EndIf
  Next
  Rename f$ As f$ + ".1"
End Sub

Sub install_shell_commands()
  install_shell_command("backup")
  install_shell_command("cat")
  install_shell_command("cd")
  install_shell_command("cp")
  install_shell_command("help", "sphelp")
  install_shell_command("ls")
  install_shell_command("mkdir")
  install_shell_command("mv")
  install_shell_command("pwd")
  install_shell_command("rm")
  install_shell_command("touch")
  install_shell_command("rm")
  install_shell_command("version", "spversion")
End Sub

Sub install_shell_command(cmd$, dst_$)
  Local dst$ = BIN_DIR$ + Choice(dst_$ = "", cmd$, dst_$) + ".bas"

  Print "Installing shell command '" cmd$ "' to '" dst$

  write_file(dst$, Mm.Info(PATH) + SHELL_PROGRAM$, cmd$)
End Sub

