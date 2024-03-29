' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("file")
sys.provides("sptools")
If sys.err$ <> "" Then Error sys.err$
'!endif

' Gets the 'sptools' installation directory.
Function spt.get_install_dir$()

  ' First try recursing up the directory structure from the running program
  ' until a file called 'sptools.root' is found.
  Local d$ = file.get_parent$(Mm.Info$(Current))
  Do While d$ <> ""
    If file.exists%(d$ + "/sptools.root") Then Exit Do
    d$ = file.get_parent$(d$)
  Loop

  ' Otherwise try the default installation location.
  If d$ = "" Then d$ = "A:/sptools"

  If Not file.is_directory%(d$) Then Error "directory not found: " + d$

  spt.get_install_dir$ = d$
End Function

Sub spt.print_version(name$, year%, platform$, println$)
  If Not year% Then year% = 2020
  If platform$ = "" Then platform$ = "MMBasic 5.07"
  If println$ = "" Then println$ = "spt.println"
  Call println$, name$ + " (SP Tools) Version " + sys.format_version$() + " for " + platform$
  Call println$, "Copyright (c) " + Str$(year%) + "-2023 Thomas Hugo Williams"
  Call println$, "A Toy Plastic Trumpet Production for Sockpuppet Studios."
  Call println$, "License MIT <https://opensource.org/licenses/MIT>"
  Call println$, "This is free software: you are free to change and redistribute it."
  Call println$, "There is NO WARRANTY, to the extent permitted by law."
End Sub

Sub spt.println(s$)
  Print s$
End Sub
