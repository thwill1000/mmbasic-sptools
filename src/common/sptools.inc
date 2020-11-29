' Copyright (c) 2020 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("file")
sys.provides("sptools")
If sys.err$ <> "" Then Error sys.err$

' TODO: dynamically determine installation directory.
Const SPT_INSTALL_DIR$ = "/sptools"
Const SPT_RESOURCES_DIR$ = SPT_INSTALL_DIR$ + "/resources"
Const SPT_VERSION$ = "(SP Tools) Release " + sys.VERSION$ + " for Colour Maximite 2, MMBasic 5.06"

Sub spt.version(name$)
  Print name$ " " SPT_VERSION$
  Print "Copyright (c) 2020 Thomas Hugo Williams"
  Print "A Toy Plastic Trumpet Production for Sockpuppet Studios."
  Print "License MIT <https://opensource.org/licenses/MIT>"
  Print "This is free software: you are free to change and redistribute it."
  Print "There is NO WARRANTY, to the extent permitted by law."
  Print
  Print "Written by Thomas Hugo Williams."
End Sub
