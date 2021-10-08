' Copyright (c) 2020-2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("file")
sys.provides("sptools")
If sys.err$ <> "" Then Error sys.err$

Const spt.INSTALL_DIR$ = spt.get_install_dir$()
Const spt.RESOURCES_DIR$ = spt.INSTALL_DIR$ + "/resources"

' Gets the 'sptools' installation directory.
Function spt.get_install_dir$()

  ' First try recursing up the directory structure from the running program
  ' until a file called 'sptools.root' is found.
  Local d$ = file.PROG_DIR$
  Do While d$ <> ""
    If file.exists%(d$ + "/sptools.root") Then Exit Do
    d$ = file.get_parent$(d$)
  Loop

  ' Otherwise try the default installation location.
  If d$ = "" Then d$ = "A:/sptools"

  If Not file.is_directory%(d$) Then Error "directory not found: " + d$

  spt.get_install_dir$ = d$
End Function

Sub spt.print_version(name$)
  Print name$ " (SP Tools) Version " + sys.VERSION$ + " for Colour Maximite 2, MMBasic 5.07.01"
  Print "Copyright (c) 2020-2021 Thomas Hugo Williams"
  Print "A Toy Plastic Trumpet Production for Sockpuppet Studios."
  Print "License MIT <https://opensource.org/licenses/MIT>"
  Print "This is free software: you are free to change and redistribute it."
  Print "There is NO WARRANTY, to the extent permitted by law."
End Sub
