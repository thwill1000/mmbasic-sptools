' Copyright (c) 2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.provides("console")
If sys.err$ <> "" Then Error sys.err$

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
