' Copyright (c) 2020 Thomas Hugo Williams

' Formats a firmware version as a 5-digit number, e.g.
'   5.05.06 => 50506
'   5.04    => 50400
'
' @param version$  the firmware version to format.
'                  If empty then formats the current firmware version number.
Function sys.firmware_version%(version$)
  Local i%, s$, v$ = version$
  If v$ = "" Then v$ = Str$(Mm.Info$(Version))
  For i% = 1 To Len(v$)
    If InStr("0123456789", Mid$(v$, i%, 1)) > 0 Then s$ = s$ + Mid$(v$, i%, 1)
  Next
  Do While Len(s$) < 5 : s$ = s$ + "0" : Loop
  sys.firmware_version% = Val(s$)
End Function

' Generates a pseudo random integer between 1 and 'range%' inclusive.
'
' @param  range%  if > 0 then upper bound of generated number,
'                 if = 0 then reinitialises seed based on Timer value,
'                 if < 0 then sets seed to Abs(range%)
Function sys.pseudo%(range%)
  Static x% = Timer ' 7
  Static a% = 1103515245
  Static c% = 12345
  Static m% = 2^31

  If range% = 0 Then
    x% = Timer
  ElseIf range% < 0 Then
    x% = Abs(range%)
  Else
    x% = (a% * x% + c%) Mod m%
    sys.pseudo% = 1 + CInt((range% - 1) * (x% / m%))
  EndIf
End Function
