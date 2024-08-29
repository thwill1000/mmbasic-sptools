' Copyright (c) 2022-2024 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>

Option Base 0
Option Default None
Option Explicit On

'!if defined(GAMEMITE)
' For GameMite running PicoMite MMBasic 5.07.07
'!elif defined(PICOMITE)
' For PicoGAME VGA 1.4 running PicoMiteVGA MMBasic 5.09
'!elif defined(CMM2)
' For CMM2 running MMBasic 5.07.02b6
'!endif

Const DEVICE$ = determine_device$()

#Include "../system.inc"
#Include "../bits.inc"
#Include "../string.inc"
#Include "../ctrl.inc"

If Mm.Device$ = "PicoMite" Then
  Const FONT_NUM = 7
ElseIf Mm.Device$ = "MMB4L" Then
  Const FONT_NUM = 1
Else
  Const FONT_NUM = 1
  Mode 1
EndIf

Font FONT_NUM

If Mm.Device$ = "MMB4L" Then
  Dim WIDTH%, HEIGHT%
  Console GetSize WIDTH%, HEIGHT%
  Console HideCursor
Else
  Const WIDTH% = Mm.Hres \ Mm.Info(FontWidth)
EndIf

Dim ctrl$ = "no_ctrl", err$

Option Break 4
On Key 3, on_break

read_controller_data()
show_menu()
main_loop()
end_program()

' On MMB4L this sets OPTION SIMULATE based on any --simulate="..." command line flag,
' on other devices/platforms is does nothing.
'
' @return Name to display for the current device/platform.
Function determine_device$()
  determine_device$ = Mm.Info(Device)
  If Mm.Info(Device) <> "MMB4L" Then Exit Function
  Local start% = InStr(Mm.CmdLine$, "--simulate=" + Chr$(34))
  If Not start% Then Exit Function
  Inc start%, 12
  Local end% = InStr(start%, Mm.CmdLine$, Chr$(34))
  If Not end% Then Exit Function
  Const simulate$ = Mid$(Mm.CmdLine$, start%, end% - start%)
  Option Simulate simulate$
  determine_device$ = "MMB4L (" + simulate$ + ")"
End Function

Sub on_break()
  Option Break 3
  end_program()
End Sub

Sub end_program()
  On Error Ignore
  Call ctrl$, ctrl.CLOSE
  On Error Abort
  ctrl.term_keys()
  If Mm.Device$ = "MMB4L" Then Console ShowCursor
  End
End SUb

Sub read_controller_data()
  Local i%, s1$, s2$
  restore_controller_data()
  Dim NUM_CTRL% = 0
  Do
    Read s1$, s2$
    If s1$ = "" Then Exit Do
    Inc NUM_CTRL%
  Loop

  Dim CTRL_DRIVERS$(NUM_CTRL%)
  Dim CTRL_DESCRIPTIONS$(NUM_CTRL%)
  Dim MAX_DRIVER_LEN% = 0
  restore_controller_data()
  For i% = 1 To NUM_CTRL%
    Read CTRL_DRIVERS$(i%), CTRL_DESCRIPTIONS$(i%)
    If Len(CTRL_DRIVERS$(i%)) > MAX_DRIVER_LEN%) Then
      MAX_DRIVER_LEN% = Len(CTRL_DRIVERS$(i%))
    EndIf
  Next
End Sub

Sub restore_controller_data()
  Select Case Mm.Device$
    Case "PicoMite", "PicoMiteVGA"
      If Mm.Info(Platform) = "Game*Mite" Then
        Restore controller_data_gamemite
      Else
        Restore controller_data_picomite
      EndIf
    Case "Colour Maximite 2", "Colour Maximite 2 G2"
      Restore controller_data_cmm2
    Case "MMB4L"
      Restore controller_data_mmb4l
    Case "MMBasic for Windows"
      Restore controller_data_mmb4w
    Case Else
      Error "Unsupported device: " + Mm.Device$
  End Select
End Sub

Sub show_menu()
  Cls
  print_at(0, 0, "MMBasic Controller Driver Test " + sys.format_version$())
  print_at(0, 1, "Running on " + DEVICE$ + " " + sys.format_firmware_version$())
  print_at(0, 3,  "Select driver using [A-Z]")
  print_at(0, 4,  "Then 'play' with controller to test response")
  Local i%
  For i% = 1 To NUM_CTRL%
    print_ctrl_option(i%, 0)
  Next
  print_at(2, i% + 5, "[Esc]  Quit")
End Sub

Sub main_loop()
  Local bits%, current%, i%, s$

  ctrl.init_keys(Mm.Info$(Device X) = "MMB4L")

  Do
    If ctrl.keydown%(27) Then Exit Do ' Escape pressed.

    For i% = 1 To NUM_CTRL%
      If ctrl.keydown%(i% + Asc("a") - 1) Then ' Selection made.
        print_ctrl_option(current%, 0)
        On Error Ignore
        Call ctrl$, ctrl.CLOSE
        err$ = Choice(Mm.ErrNo = 0, "", Mm.ErrMsg$)
        On Error Abort
        current% = Choice(is_valid%(i%), i%, 0)
        print_ctrl_option(current%, 1)
        ctrl$ = Choice(current% = 0, "no_ctrl", CTRL_DRIVERS$(i%))
        On Error Ignore
        Call ctrl$, ctrl.OPEN
        err$ = Choice(Mm.ErrNo = 0, "", Mm.ErrMsg$)
        On Error Abort
        Do While ctrl.keydown%(i% + Asc("a") - 1) : Pause 5 : Loop ' Wait for key to be released.
        Exit For
      EndIf
    Next

    If err$ = "" Then
      Call ctrl$, bits%
      s$ = str.rpad$("Currently reading: " + ctrl.bits_to_string$(bits%), WIDTH%)
    Else
      s$ = str.rpad$(str.trim$(Mid$(err$, InStr(err$, ":") + 1)), WIDTH%)
    EndIf
    print_at(0, 8 + NUM_CTRL%, s$)

    ' Compensate for Inkey$ not being the ideal way to read the keyboard.
    If Not InStr(Mm.Device$, "Colour Maximite 2") And InStr(ctrl$, "keys") Then Pause 100
  Loop
End Sub

Sub no_ctrl(x%)
  x% = 0
End Sub

Function is_valid%(idx%)
  is_valid% = idx% >= 1 And idx% <= NUM_CTRL%
End Function

' Prints text on the VGA screen at the given column and row.
'
' @param col%      the column, from 0.
' @param row%      the row, from 0.
' @param s$        the text.
' @param inverse%  print black on white instead of white on black.
Sub print_at(col%, row%, s$, inverse%)
  If Mm.Device$ = "MMB4L" Then
' TODO: Why does Print @ not work as expected in MMB4L
'    Print @(col%, row%), s$
    Console SetCursor col%, row%
    Console Inverse inverse%
    Print s$
    Console Inverse 0
  Else
    Local x% = col% * Mm.Info(FontWidth)
    Local y% = row% * Mm.Info(FontHeight) * 1.5
    Local fg% = Choice(inverse%, Rgb(Black), Rgb(White))
    Local bg% = Choice(inverse%, Rgb(White), Rgb(Black))
    Text x%, y%, s$, LT, FONT_NUM, 1, fg%, bg%
  EndIf
End Sub

Sub print_ctrl_option(idx%, selected%)
  If Not is_valid%(idx%) Then Exit Sub
  Local s$ = str.rpad$("[" + Chr$(Asc("A") + idx% - 1) + "] ", 7)
  Cat s$, str.rpad$(str.quote$(CTRL_DRIVERS$(idx%)), MAX_DRIVER_LEN% + 4)
  Cat s$, CTRL_DESCRIPTIONS$(idx%)
  print_at(2, idx% + 5, s$, selected%)
End Sub

controller_data_gamemite:

Data "keys_cursor", "Keyboard: Cursor keys & Space"
Data "ctrl.gamemite", "GameMite gamepad"
Data "", ""

controller_data_picomite:

Data "keys_cursor", "Keyboard: Cursor keys & Space"
Data "atari_a",     "Port A: Atari VCS joystick"
Data "atari_b",     "Port B: Atari VCS joystick (2.0 PCB only)"
Data "nes_a",       "Port A: NES gamepad"
Data "nes_b",       "Port B: NES gamepad"
Data "snes_a",      "Port A: SNES gamepad"
Data "snes_b",      "Port B: SNES gamepad"
Data "wii_classic_pm", "Wii Classic Controller"
Data "wii_nunchuk_pm", "Wii Nunchuk Controller"
Data "", ""

controller_data_cmm2:

Data "keys_cursor",   "Keyboard: Cursor keys & Space"
Data "atari_dx",      "CMM2 DX Atari VCS joystick"
Data "nes_dx",        "CMM2 DX NES gamepad (attached to Atari port with adapter)"
Data "snes_dx",       "CMM2 DX SNES gamepad (attached to Atari port with adapter)"
Data "wii_any_1",     "Wii Nunchuk or Classic Controller (I2C1)"
Data "wii_any_2",     "Wii Nunchuk or Classic Controller (I2C2)"
Data "wii_any_3",     "Wii Nunchuk or Classic Controller (I2C3)"
Data "wii_classic_1", "Wii Classic Controller (I2C1)"
Data "wii_classic_2", "Wii Classic Controller (I2C2)"
Data "wii_classic_3", "Wii Classic Controller (I2C3)"
Data "wii_nunchuk_1", "Wii Nunchuk Controller (I2C1)"
Data "wii_nunchuk_2", "Wii Nunchuk Controller (I2C2)"
Data "wii_nunchuk_3", "Wii Nunchuk Controller (I2C3)"
Data "", ""

controller_data_mmb4l:

Data "keys_cursor", "Keyboard: Cursor keys & Space"
Data "mmb4l_gamepad_1", "USB Gamepad 1"
Data "mmb4l_gamepad_2", "USB Gamepad 2"
Data "mmb4l_gamepad_3", "USB Gamepad 3"
Data "mmb4l_gamepad_4", "USB Gamepad 4"
Data "", ""

controller_data_mmb4w:

Data "keys_cursor", "Keyboard: Cursor keys & Space"
Data "", ""
