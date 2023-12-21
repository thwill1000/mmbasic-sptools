' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.provides("gamemite")
If sys.err$ <> "" Then Error sys.err$
'!endif

' Finds a Game*Mite file.
'
' @param  f$  filename/path to find.
' @return     if f$ is not empty:
'               - f$ if it is an absolute path,
'               - otherwise "A:/GameMite/" + f$ if it exists,
'               - otherwise "B:/GameMite/" + f$ if it exists,
'               - if neither exists then "A:/GameMite/" + f$.
'             if f$ is empty:
'               - "A:/GameMite" if it exists,
'               - otherwise "B:/GameMite" if it exists,
'               - if neither exists then "A:/GameMite".
Function gamemite.file$(f$)
  If InStr("A:/B:/", UCase$(Left$(f$, 3))) Then
    gamemite.file$ = f$
  Else
    Local f_$ = "A:/GameMite" + Choice(f$ = "", "", "/" + f$), x%
    x% = Mm.Info(Exists File f_$)
    If Not x% Then
      f_$ = "B" + Mid$(f_$, 2)
      On Error Skip ' Handle SD Card not present error.
      x% = Mm.Info(Exists File f_$)
    EndIf
    If Not x% Then f_$ = "A" + Mid$(f_$, 2)
    gamemite.file$ = f_$
  EndIf
End Function

Sub gamemite.end(break%)
  FrameBuffer Write N
  Colour Rgb(White), Rgb(Black)
  Cls

  sys.restore_break()

  On Error Skip : sound.term()
  On Error Skip : ctrl.term()

  ' TODO: twm.term() should subsume twm.free() and also do this.
  On Error Skip
  twm.enable_cursor(1)

  If break% Then
    Const f$ = "", msg$ = "Exited due to Ctrl-C"
  Else
    Const f$ = gamemite.file$("menu.bas")
    Const x% = Mm.Info(Exists File f$)
    Const msg$ = Choice(x%, "Loading menu ...", "Menu program not found!")
  EndIf
  Text 160, 110, msg$, CM
  If Len(f$) Then Run f$ Else End
End Sub
