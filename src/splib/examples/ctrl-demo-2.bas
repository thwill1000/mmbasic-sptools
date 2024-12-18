' Copyright (c) 2022-2024 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>

Option Base 0
Option Default None
Option Explicit On

'!dynamic_call keys_cursor_ext
'!if defined(PICOMITEVGA)
  '!replace { Option Simulate "Colour Maximite 2" } { Option Simulate "PicoMiteVGA" }
  '!dynamic_call nes_a
  '!replace { Page Copy 1 To 0 , B } { FrameBuffer Copy F , N , B }
  '!replace { Page Write 1 } { FrameBuffer Write F }
  '!replace { Page Write 0 } { FrameBuffer Write N }
  '!replace { Mode 7 } { Mode 2 : FrameBuffer Create }
'!elif defined(PICOMITE) || defined(GAMEMITE)
  '!replace { Option Simulate "Colour Maximite 2" } { Option Simulate "Game*Mite" }
  '!dynamic_call ctrl.gamemite
  '!replace { Page Copy 1 To 0 , B } { FrameBuffer Copy F , N }
  '!replace { Page Write 1 } { FrameBuffer Write F }
  '!replace { Page Write 0 } { FrameBuffer Write N }
  '!replace { Mode 7 } { FrameBuffer Create }
'!else
  '!dynamic_call wii_classic_3
'!endif

If Mm.Device$ = "MMB4L" Then
  Option Simulate "Colour Maximite 2"
  Option CodePage CMM2
EndIf

#Include "../system.inc"
#Include "../ctrl.inc"
#Include "../sound.inc"
#Include "../string.inc"
#Include "../txtwm.inc"
#Include "../menu.inc"
#Include "../game.inc"

'!dynamic_call game.on_break
sys.override_break("game.on_break")

Dim BUTTONS%(7) = (ctrl.A, ctrl.B, ctrl.UP, ctrl.DOWN, ctrl.LEFT, ctrl.RIGHT, ctrl.START, ctrl.SELECT)
Dim CTRL_DRIVERS$(1) = (ctrl.default_driver$(), "keys_cursor_ext")

'!if !defined(GAMEMITE)
If Mm.Device$ = "MMBasic for Windows" Then Option Console Serial
If InStr(Mm.Device$, "Colour Maximite 2") Then Option Console Serial
Mode 7
If Mm.Info$(Device X) = "MMB4L" Then
  Graphics Title 0, "MMBasic for Linux - Controller Test, v" + sys.format_version$(sys.VERSION)
EndIf
'!endif
Page Write 1

main()
Error "Invalid state"

Sub main()
  ctrl.init_keys()
  sound.init()
  Local ctrl_idx% = 0
  menu.init(CTRL_DRIVERS$(ctrl_idx%), "menu_cb")
  menu.load_data("main_menu_data")
  menu.selection% = ctrl_idx% + 2
  If ctrl.open_no_error%(menu.ctrl$) <> sys.SUCCESS Then
    menu.ctrl$ = "ctrl.no_controller"
    ' NOTE: Connection/disconnection whilst program is running is not responded to.
    menu.items$(2) = str.replace$(menu.items$(2), "               ", " (Disconnected)")
  EndIf

  menu.render(1)

  Local i%, key%, old%, t% = 0
  Do
    If ctrl.keydown%(Asc("1")) Then
      menu.select_item(2)
    ElseIf ctrl.keydown%(Asc("2")) Then
      menu.select_item(3)
    Else
      If Len(menu.ctrl$) Then Call menu.ctrl$, key% Else key% = 0
      Select Case key%
        Case ctrl.HOME
          on_quit()
          key% = 0
          t% = 0
        Case ctrl.A
          If t% = 0 Then t% = Timer + 2000
          If Timer >= t% Then on_quit()
        Case Else
          t% = 0
      End Select
      If key% = old% Then Pause 50 : Continue Do
      old% = key%
      For i% = Bound(BUTTONS%(), 0) To Bound(BUTTONS%(), 1)
        render_button(BUTTONS%(i%), key% And BUTTONS%(i%))
      Next
      Page Copy 1 To 0 , B
    EndIf
  Loop
End Sub

'!dynamic_call menu_cb
Sub menu_cb(cb_data$)
  Select Case Field$(cb_data$, 1, "|")
    Case "render"
      on_render(cb_data$)
    Case "selection_changed"
      on_selection_changed(cb_data$)
    Case Else
      Error "Invalid state"
  End Select
End Sub

Sub on_render(cb_data$)
  twm.box(5, 8, 30, 9)
  Local i%
  For i% = Bound(BUTTONS%(), 0) To Bound(BUTTONS%(), 1)
    render_button(BUTTONS%(i%))
  Next
  Const msg$ = "Hold " + Choice(menu.selection% = 3, "SPACE", "A") + " to QUIT"
  menu.items$(Bound(menu.items$(), 1)) = str.centre$(msg$, menu.width% - 4) + "|"
  menu.render_item(Bound(menu.items$(), 1))
  Local s$ = "v" + sys.format_version$()
  twm.print_at(menu.width% - Len(s$) - 2, menu.height% - 2, s$)
End Sub

Sub on_selection_changed(cb_data$)
  On Error Ignore
  Call menu.ctrl$, ctrl.CLOSE
  On Error Abort

  menu.ctrl$ = CTRL_DRIVERS$(menu.selection% - 2)

  On Error Ignore
  Call menu.ctrl$, ctrl.OPEN
  On Error Abort
  If Mm.ErrNo Then menu.ctrl$ = "ctrl.no_controller"

  on_render()
End Sub

Sub render_button(key%, active%)
  If active% Then twm.foreground(twm.RED%)
  Select Case key%
    Case ctrl.A
      twm.box1(30, 11, 3, 3)
      twm.print_at(31, 12, "A")
    Case ctrl.B
      twm.box1(26, 11, 3, 3)
      twm.print_at(27, 12, "B")
    Case ctrl.UP
      twm.box1(10, 9, 3, 3)
      twm.print_at(11, 10, Chr$(&h92))
    Case ctrl.DOWN
      twm.box1(10, 13, 3, 3)
      twm.print_at(11, 14, Chr$(&h93))
    Case ctrl.LEFT
      twm.box1(7, 11, 3, 3)
      twm.print_at(8, 12, Chr$(&h95))
    Case ctrl.RIGHT
      twm.box1(13, 11, 3, 3)
      twm.print_at(14, 12, Chr$(&h94))
    Case ctrl.START
      twm.print_at(23, 15, Chr$(223) + Chr$(223))
      twm.print_at(22, 14, "Start")
    Case ctrl.SELECT
      twm.print_at(17, 15, Chr$(223) + Chr$(223))
      twm.print_at(15, 14, "Select")
    Case Else
      Error "Invalid state"
  End Select
  If active% Then twm.foreground(twm.WHITE%)
End Sub

Sub on_quit()
  menu.play_valid_fx(1)
  Const msg$ = str.decode$("\nAre you sure you want to quit this program?")  
  Select Case YES_NO_BTNS$(menu.msgbox%(msg$, YES_NO_BTNS$(), 1))
    Case "Yes"
      game.end()
    Case "No"
      twm.switch(menu.win1%)
      twm.redraw()
      Page Copy 1 To 0 , B
    Case Else
      Error "Invalid state"
  End Select
End Sub

main_menu_data:
Data "\x9F Controller Test \x9F|"
Data "|"
Data " 1) Gamepad                       |menu.cmd_open|music_menu_data"
Data " 2) Keyboard: Cursor keys & Space |menu.cmd_open|music_menu_data"
Data "|", "|", "|", "|", "|", "|", "|", "|", "|", "|", "|", "|"
Data ""
