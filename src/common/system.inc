' Copyright (c) 2020 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

Const sys.VERSION$ = "r1b3"
Const sys.NO_DATA$ = Chr$(&h7F)
Const sys.MAX_INCLUDES% = 20

Dim sys.err$
Dim sys.includes$(sys.MAX_INCLUDES%) Length 20

Sub sys.provides(f$)
  Local f_$ = LCase$(f$)
  Local i% = 1
  Do
    Select Case sys.includes$(i%)
      Case f_$ : sys.err$ = "file already included: " + f_$ + ".inc" : Exit Sub
      Case ""  : sys.includes$(i%) = f_$ : Exit Sub
    End Select
    Inc i%
    If i% > sys.MAX_INCLUDES% Then sys.err$ = "too many includes" : Exit Sub
  Loop
End Sub

Sub sys.requires(f1$, f2$, f3$, f4$, f5$, f6$, f7$, f8$, f9$, f10$)
  Local f$(10) Length 20
  f$(1) = f1$ : f$(2) = f2$ : f$(3) = f3$ : f$(4) = f4$ : f$(5) = f5$
  f$(6) = f6$ : f$(7) = f7$ : f$(8) = f8$ : f$(9) = f9$ : f$(10) = f10$

  Local i%, j%, ok%, fail%
  For i% = 1 To 10 : f$(i%) = LCase$(f$(i%)) : Next
  For i% = 1 To 10
    If f$(i%) <> "" Then
      ok% = 0
      For j% = 1 To sys.MAX_INCLUDES%
        Select Case sys.includes$(j%)
          Case f$(i%) : ok% = 1 : Exit For
          Case ""     : Exit For
        End Select
      Next j%
      If Not ok% Then
        If Not fail% Then
          sys.err$ = "required file(s) not included: " + f$(i%) + ".inc"
          fail% = 1
        Else
          Cat sys.err$, ", " + f$(i%) + ".inc"
        EndIf
      EndIf
    EndIf
  Next i%
End Sub

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
