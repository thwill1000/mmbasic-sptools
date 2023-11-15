' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.provides("gamemite")
If sys.err$ <> "" Then Error sys.err$
'!endif

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
    Local f$ = "", msg$ = "Exited due to Ctrl-C"
  Else
    Local f$ = "A:/GameMite/menu.bas", x% = Mm.Info(Exists File f$)
    If Not x% Then
      On Error Skip
      x% = Mm.Info(Exists File "B:/GameMite/menu.bas")
      If Mm.ErrNo Then x% = 0
      If x% Then f$ = "B:/GameMite/menu.bas"
    EndIf
    Local msg$ = Choice(x%, "Loading menu ...", "Menu program not found!")
  EndIf
  Text 160, 110, msg$, CM
  If Len(f$) Then Run f$ Else End
End Sub
