' Copyright (c) 2023-2024 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.provides("game")
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
Function game.file$(f$)
  If Mm.Info$(Device X) = "MMB4L" Then
    game.file$ = Mm.Info$(EnvVar "MMBASIC_GAMEPACK_HOME")
    If game.file$ = "" Then game.file$ = sys.HOME$() + "/mmbasic-gamepack"
    Cat game.file$, "/" + f$
    Exit Function
  EndIf

  If InStr("A:/B:/", UCase$(Left$(f$, 3))) Then
    game.file$ = f$
  Else
    Local f_$ = "A:/GameMite" + Choice(f$ = "", "", "/" + f$), x%
    x% = Mm.Info(Exists File f_$)
    If Not x% Then
      f_$ = "B" + Mid$(f_$, 2)
      On Error Skip ' Handle SD Card not present error.
      x% = Mm.Info(Exists File f_$)
    EndIf
    If Not x% Then f_$ = "A" + Mid$(f_$, 2)
    game.file$ = f_$
  EndIf
End Function

Sub game.end(break%)
  If InStr(Mm.Device$, "PicoMite") Then
    FrameBuffer Write N
    FrameBuffer Close
  Else
    Page Write 0
  EndIf
  Colour Rgb(White), Rgb(Black)
  Font 7
  Cls

  sys.restore_break()

  ' Use ON ERROR SKIP because we might not be using these libraries.
  On Error Skip : sound.term()
  On Error Skip : ctrl.term()

  SetTick 0,0,1 : SetTick 0,0,2 : SetTick 0,0,3 : SetTick 0,0,4
  Play Stop

  If break% Then
    Const f$ = "", msg$ = "Exited due to Ctrl-C"
  Else
    Const f$ = game.file$("menu.bas")
    Const x% = Mm.Info(Exists File f$)
    Const msg$ = Choice(x%, "Loading menu ...", "Menu program not found!")
  EndIf
  Text 160, 110, msg$, CM
  If Mm.Info$(Device X) = "MMB4L" Then Pause 2000

  ' TODO: twm.term() should subsume twm.free() and also do this.
  On Error Skip
  twm.enable_cursor(1)

  If Len(f$) Then Run f$ Else End
End Sub

Sub game.init_window(title$, version%, title_suffix$)
  If Mm.Info$(Device X) = "MMB4L" Then
    Local s$ = title$
    If version% Then Cat s$, ", v" + sys.format_version$(version%)
    Cat s$, title_suffix$
    Graphics Title 0, s$
    Graphics Interrupt 0, game.on_window_event
  EndIf
End Sub

Sub game.on_window_event(window_id%, event_id%)
  If event_id% = WINDOW_EVENT_CLOSE Then game.end(0)
End Sub
