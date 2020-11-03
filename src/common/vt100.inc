' Copyright (c) 2020 Thomas Hugo Williams

Function vt100$(s$)
  vt100$ = Chr$(27) + "[" + s$
End Function

Function vt100.colour$(c$)
  Select Case LCase$(c$)
    Case "red"     : vt100.colour$ = vt100$("31m")
    Case "green"   : vt100.colour$ = vt100$("32m")
    Case "yellow"  : vt100.colour$ = vt100$("33m")
    Case "blue"    : vt100.colour$ = vt100$("34m")
    Case "magenta" : vt100.colour$ = vt100$("35m")
    Case "cyan"    : vt100.colour$ = vt100$("36m")
    Case "white"   : vt100.colour$ = vt100$("37m")
    Case "reset"   : vt100.colour$ = vt100$("0m")
    Case Else      : "Unknown VT100 colour: " + c$
  End Select
End Function

