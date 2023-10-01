' Copyright (c) 2021-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.provides("console")
If sys.err$ <> "" Then Error sys.err$
'!endif

Sub con.errorln(s$)
  Print s$
End Sub

Sub con.foreground(fg$)
  Select Case LCase$(fg$)
    Case "green"   : Print Chr$(27) + "[32m";
    Case "blue"    : Print Chr$(27) + "[34m";
    Case "magenta" : Print Chr$(27) + "[35m";
    Case "default" : Print Chr$(27) + "[0m";
    Case Else      : Error "unknown colour: " + fg$
  End Select
End Sub

Sub con.print(s$)
  Print s$;
End Sub

Sub con.println(s$)
  Print s$
End Sub

Function con.readln$()
  Line Input con.readln$
End Function
