' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>

Option Base 0
Option Default None
Option Explicit On

'!define NO_INCLUDE_GUARDS

#Include "../system.inc"

'!if defined PICOMITEVGA
  '!replace { Page Copy 1 To 0 , B } { FrameBuffer Copy F , N , B }
  '!replace { Page Write 1 } { FrameBuffer Write F }
  '!replace { Page Write 0 } { FrameBuffer Write N }
  '!replace { Mode 7 } { Mode 2 : FrameBuffer Create }
'!elif defined(PICOMITE) || defined(GAMEMITE)
  '!replace { Page Copy 1 To 0 , B } { FrameBuffer Copy F , N }
  '!replace { Page Write 1 } { FrameBuffer Write F }
  '!replace { Page Write 0 } { FrameBuffer Write N }
  '!replace { Mode 7 } { FrameBuffer Create }
'!endif

#Include "../ctrl.inc"
#Include "../sound.inc"
#Include "../string.inc"
#Include "../txtwm.inc"
#Include "../menu.inc"
#Include "../gamemite.inc"

If sys.is_device%("pm*") Then
  Dim CHANNELS$(3) Length 14
  CHANNELS$(0) = str.decode$("\x95    Both    \x94")
  CHANNELS$(1) = str.decode$("\x95    Mono    \x94")
  CHANNELS$(2) = str.decode$("\x95    Left    \x94")
  CHANNELS$(3) = str.decode$("\x95    Right   \x94")
  Dim CHANNEL_VALUES$(3) Length 1 = ("B", "M", "L", "R")
Else
  Dim CHANNELS$(2) Length 14
  CHANNELS$(0) = str.decode$("\x95    Both    \x94")
  CHANNELS$(1) = str.decode$("\x95    Left    \x94")
  CHANNELS$(2) = str.decode$("\x95    Right   \x94")
  Dim CHANNEL_VALUES$(2) Length 1 = ("B", "L", "R")
EndIf
Dim OCTAVES$(4) Length 14
OCTAVES$(0) = str.decode$("\x95   Default  \x94")
OCTAVES$(1) = str.decode$("\x95     +1     \x94")
OCTAVES$(2) = str.decode$("\x95     +2     \x94")
OCTAVES$(3) = str.decode$("\x95     -2     \x94")
OCTAVES$(4) = str.decode$("\x95     -1     \x94")
Dim OCTAVE_VALUES%(4) = (0, 1, 2, -2, -1)
Dim TYPES$(3) Length 14
TYPES$(0) = str.decode$("\x95    Sine    \x94")
TYPES$(1) = str.decode$("\x95   Square   \x94")
TYPES$(2) = str.decode$("\x95 Triangular \x94")
TYPES$(3) = str.decode$("\x95     Saw    \x94")
Dim TYPE_VALUES$(3) Length 1 = ("S", "Q", "T", "W")

Dim channel$ = "B"
Dim channel_idx% = 0
Dim type$ = "S"
Dim octave% = 0
Dim octave_idx% = 0
Dim type_idx% = 0

If sys.is_device%("mmb4l") Then Option CodePage CMM2
If sys.is_device%("mmb4w", "cmm2*") Then Option Console Serial
Mode 7
Page Write 1

main()
Error "Invalid state"

Sub main()
  '!dynamic_call ctrl.gamemite
  '!dynamic_call keys_cursor_ext
  Const ctrl$ = Choice(sys.is_device%("gamemite"), "ctrl.gamemite", "keys_cursor_ext")
  ctrl.init_keys()
  sys.override_break()
  Call ctrl$, ctrl.OPEN
  sound.init("fx_test_int", "music_test_int")
  menu.init(ctrl$, "menu_cb")
  update_menu_data("main_menu_data")
  menu.render(1)
  menu.main_loop()
End Sub

'!dynamic_call fx_test_int
Sub fx_test_int()
  If Not sound.fx_ptr% Then Exit Sub
  Local n% = Peek(Byte sound.fx_ptr%)
  If n% < 255 Then
    play_sound(4, n%, 25)
    Inc sound.fx_ptr%
  Else
    sound.fx_ptr% = 0
  EndIf
End Sub

Sub play_sound(num%, note%, volume%)
  Local n% = note%
  If n% Then Inc n%, 12 * octave% : n% = Max(n%, 0) : n% = Min(n%, 254)
'!uncomment_if PICOMITE
  ' Play Sound num%, channel$, type$, sound.F!(n%), (n% > 0) * volume%
'!endif
'!if !defined(PICOMITE)
  Select Case channel$ + type$
    Case "BS" : Play Sound num%, B, S, sound.F!(n%), (n% > 0) * volume%
    Case "BQ" : Play Sound num%, B, Q, sound.F!(n%), (n% > 0) * volume%
    Case "BT" : Play Sound num%, B, T, sound.F!(n%), (n% > 0) * volume%
    Case "BW" : Play Sound num%, B, W, sound.F!(n%), (n% > 0) * volume%
    Case "MS" : Play Sound num%, M, S, sound.F!(n%), (n% > 0) * volume%
    Case "MQ" : Play Sound num%, M, Q, sound.F!(n%), (n% > 0) * volume%
    Case "MT" : Play Sound num%, M, T, sound.F!(n%), (n% > 0) * volume%
    Case "MW" : Play Sound num%, M, W, sound.F!(n%), (n% > 0) * volume%
    Case "LS" : Play Sound num%, L, S, sound.F!(n%), (n% > 0) * volume%
    Case "LQ" : Play Sound num%, L, Q, sound.F!(n%), (n% > 0) * volume%
    Case "LT" : Play Sound num%, L, T, sound.F!(n%), (n% > 0) * volume%
    Case "LW" : Play Sound num%, L, W, sound.F!(n%), (n% > 0) * volume%
    Case "RS" : Play Sound num%, R, S, sound.F!(n%), (n% > 0) * volume%
    Case "RQ" : Play Sound num%, R, Q, sound.F!(n%), (n% > 0) * volume%
    Case "RT" : Play Sound num%, R, T, sound.F!(n%), (n% > 0) * volume%
    Case "RW" : Play Sound num%, R, W, sound.F!(n%), (n% > 0) * volume%
    Case Else
      Error "Invalid state"
  End Select
'!endif
End Sub

'!dynamic_call music_test_int
Sub music_test_int()
  If Not sound.music_ptr% Then Exit Sub
  Local num% = Peek(Byte sound.music_start_ptr%)
  Local n% = Peek(Byte sound.music_ptr%)
  If n% < 255 Then
    play_sound(1, n%, 15)
    n% = Choice(num% > 1, Peek(Byte sound.music_ptr% + 1), 0)
    play_sound(2, n%, 15)
    n% = Choice(num% > 2, Peek(Byte sound.music_ptr% + 2), 0)
    play_sound(3, n%, 15)
    n% = Choice(num% > 3, Peek(Byte sound.music_ptr% + 3), 0)
    play_sound(4, n%, 15)
    Inc sound.music_ptr%, num%
  Else
    sound.music_ptr% = 0
    If Len(sound.music_done_cb$) Then Call sound.music_done_cb$
  EndIf
End Sub

'!dynamic_call menu_cb
Sub menu_cb(cb_data$)
  Select Case Field$(cb_data$, 1, "|")
    Case "render"
      on_render()
    Case "selection_changed"
      ' Do nothing.
    Case Else
      Error "Invalid state"
  End Select
End Sub

Sub on_render(cb_data$)
  Const s$ = "v" + sys.format_version$()
  twm.print_at(menu.width% - Len(s$) - 2, menu.height% - 2, s$)
End Sub

Sub cmd_menu(key%)
  Select Case key%
    Case ctrl.A, ctrl.SELECT
      menu.play_valid_fx(1)
      update_menu_data(Field$(menu.items$(menu.selection%), 3, "|"))
      menu.render()
    Case Else
      default_handler(key%)
  End Select
End Sub

Sub default_handler(key%)
  Local i%
  Select Case key%
    Case ctrl.B
      For i% = 0 To menu.item_count% - 1
        If Field$(menu.items$(i%), 1, "|") = "BACK" Then
          menu.selection% = i%
          cmd_menu(ctrl.SELECT)
          Exit Sub
        EndIf
      Next
      menu.play_invalid_fx(1)

    Case ctrl.START
      cmd_quit(ctrl.SELECT)

    Case Else
      menu.play_invalid_fx(1)
  End Select
End Sub

Sub update_menu_data(data_label$)
  menu.load_data(data_label$)
  Local idx% = -1
  Select Case data_label$
    Case "main_menu_data":  ' Do nothing
    Case "music_menu_data": idx% = 6
    Case "fx_menu_data":    idx% = 8
    Case Else: Error "Invalid state"
  End Select
  If idx% > -1 Then
    menu.items$(idx%)     = " CHANNEL: " + CHANNELS$(channel_idx%) + " |cmd_channel"
    menu.items$(idx% + 1) = " TYPE:    " + TYPES$(type_idx%) + " |cmd_type"
    menu.items$(idx% + 2) = " OCTAVE:  " + OCTAVES$(octave_idx%) + " |cmd_octave"
  EndIf
  If sys.is_device%("gamemite") Then
    menu.items$(Bound(menu.items$(), 1)) = str.decode$("Use \x92 \x93 and SELECT|")
  EndIf
End Sub

'!dynamic_call cmd_play_fx
Sub cmd_play_fx(key%)
  Select Case key%
    Case ctrl.A, ctrl.SELECT
      Const item$ = menu.items$(menu.selection%)
      Execute "sound.play_fx(sound.FX_" + Field$(item$, 3, "|") + "%())"
      Do While sound.is_playing%() : Loop ' Do not block within EXECUTE.
    Case Else
      default_handler(key%)
  End Select
End Sub

'!dynamic_call cmd_play_music
Sub cmd_play_music(key%)
  Select Case key%
    Case ctrl.A, ctrl.SELECT
      Local music%(255), track$ = Field$(menu.items$(menu.selection%), 3, "|")
      sound.load_data(track$ + "_music_data", music%())
      sound.play_music(music%())
      Do : Call menu.ctrl$, key% : Loop Until Not key%
      Do While (Not key%) And sound.is_playing%()
        Call menu.ctrl$, key%
        If Not key% Then keys_cursor(key%)
      Loop
      sound.enable(&h00)
      sound.enable(sound.FX_FLAG% Or sound.MUSIC_FLAG%)
    Case Else
      default_handler(key%)
  End Select
End Sub

'!dynamic_call cmd_play_wav
Sub cmd_play_wav(key%)
  Select Case key%
    Case ctrl.A, ctrl.SELECT
      Const filename$ = Field$(menu.items$(menu.selection%), 3, "|")
      Do While sound.is_playing%() : Loop
      sound.term()
      Dim wav_done%
      Play Wav filename$, wav_done_cb
      Do While Not wav_done% : Loop
      Erase wav_done%
      Play Stop
      sound.enable(sound.FX_FLAG% Or sound.MUSIC_FLAG%)
    Case Else
      default_handler(key%)
  End Select
End Sub

'!dynamic_call wav_done_cb
Sub wav_done_cb()
  wav_done% = 1
End Sub

'!dynamic_call cmd_channel
Sub cmd_channel(key%)
  Select Case key%
    Case ctrl.LEFT, ctrl.RIGHT
      menu.play_valid_fx(1)
      Inc channel_idx%, Choice(key% = ctrl.LEFT, -1, 1)
      If channel_idx% > Bound(CHANNELS$(), 1) Then channel_idx% = 0
      If channel_idx% < 0 Then channel_idx% = Bound(CHANNELS$(), 1)
      channel$ = CHANNEL_VALUES$(channel_idx%)
      menu.items$(menu.selection%) = " CHANNEL: " + CHANNELS$(channel_idx%) + " |cmd_channel"
      menu.render_item(menu.selection%)
      Page Copy 1 To 0 , B
    Case Else
      default_handler(key%)
  End Select
End Sub

'!dynamic_call cmd_type
Sub cmd_type(key%)
  Select Case key%
    Case ctrl.LEFT, ctrl.RIGHT
      menu.play_valid_fx(1)
      Inc type_idx%, Choice(key% = ctrl.LEFT, -1, 1)
      If type_idx% > Bound(TYPES$(), 1) Then type_idx% = 0
      If type_idx% < 0 Then type_idx% = Bound(TYPES$(), 1)
      type$ = TYPE_VALUES$(type_idx%)
      menu.items$(menu.selection%) = " TYPE:    " + TYPES$(type_idx%) + " |cmd_type"
      menu.render_item(menu.selection%)
      Page Copy 1 To 0 , B
    Case Else
      default_handler(key%)
  End Select
End Sub

'!dynamic_call cmd_octave
Sub cmd_octave(key%)
  Select Case key%
    Case ctrl.LEFT, ctrl.RIGHT
      menu.play_valid_fx(1)
      Inc octave_idx%, Choice(key% = ctrl.LEFT, -1, 1)
      If octave_idx% > Bound(OCTAVES$(), 1) Then octave_idx% = 0
      If octave_idx% < 0 Then octave_idx% = Bound(OCTAVES$(), 1)
      octave% = OCTAVE_VALUES%(octave_idx%)
      menu.items$(menu.selection%) = " OCTAVE:  " + OCTAVES$(octave_idx%) + " |cmd_octave"
      menu.render_item(menu.selection%)
      Page Copy 1 To 0 , B
    Case Else
      default_handler(key%)
  End Select
End Sub

'!dynamic_call cmd_quit
Sub cmd_quit(key%)
  Select Case key%
    Case ctrl.A, ctrl.SELECT
      menu.play_valid_fx(1)
      Const msg$ = str.decode$("\nAre you sure you want to quit this program?")
      Select Case YES_NO_BTNS$(menu.msgbox%(msg$, YES_NO_BTNS$(), 1))
        Case "Yes"
          gamemite.end()
        Case "No"
          twm.switch(menu.win1%)
          twm.redraw()
          Page Copy 1 To 0 , B
        Case Else
          Error "Invalid state"
      End Select
    Case Else
      default_handler(key%)
  End Select
End Sub

main_menu_data:
Data "\x9F Sound Test \x9F|"
Data "|"
Data "  Play Music   |cmd_menu|music_menu_data"
Data " Play Sound FX |cmd_menu|fx_menu_data"
'Data "Play \qCantina Band\q|cmd_play_wav|CantinaBand3.wav"
Data "|"
Data " QUIT |cmd_quit"
Data "|", "|", "|", "|", "|", "|", "|", "|", "|"
Data "Use \x92 \x93 and SPACE to select|"
Data ""

music_menu_data:
Data "\x9F Play Music \x9F|"
Data "|"
Data "  The Entertainer  |cmd_play_music|entertainer"
Data " Black & White Rag |cmd_play_music|black_white_rag"
Data "  Spring (Vivaldi) |cmd_play_music|spring"
Data "|"
Data " CHANNEL: \x95    Both    \x94 |cmd_channel"
Data " TYPE:    \x95    Sine    \x94 |cmd_type"
Data " OCTAVE:  \x95   Default  \x94 |cmd_octave"
Data "|"
Data " BACK |cmd_menu|main_menu_data"
Data "|", "|", "|", "|"
Data "Use \x92 \x93 and SPACE to select|"
Data ""

fx_menu_data:
Data "\x9F Play Sound FX \x9F|"
Data "|"
Data " Blart  |cmd_play_fx|blart"
Data " Select |cmd_play_fx|select"
Data " Die    |cmd_play_fx|die"
Data " Wipe   |cmd_play_fx|wipe"
Data " Ready, Steady, Go! |cmd_play_fx|ready_steady_go"
Data "|"
Data " CHANNEL: \x95    Both    \x94 |cmd_channel"
Data " TYPE:    \x95    Sine    \x94 |cmd_type"
Data " OCTAVE:  \x95   Default  \x94 |cmd_octave"
Data "|"
Data " BACK |cmd_menu|main_menu_data"
Data "|", "|"
Data "Use \x92 \x93 and SPACE to select|"
Data ""

entertainer_music_data:

Data 792 ' Number of bytes of music data.
Data 3   ' Number of channels.
Data &h3135000034000033, &h3500253D00313D00, &h00283D00283D0025, &h2A3D00293D002935
Data &h3D002C3D002A3D00, &h002E3D002E00002C, &h314100304000303F, &h4100293F00313D00
Data &h002A3C002A410029, &h253D002C3F002C3F, &h3D002C3D00253D00, &h00313D00313D002C
Data &h3135000034003133, &h3500253D00313D00, &h00283D00283D0025, &h2A3D00293D002935
Data &h3D002C3D002A3D00, &h002E3D002E3D002C, &h273700263800263A, &h41002B3D00273A00
Data &h002E3F002E41002B, &h2C3F00273A00273D, &h3F002A3F002C3F00, &h00293F00293F002A
Data &h2535002734002733, &h3500313D00253D00, &h00283D00283D0031, &h2A3D00293D002935
Data &h3D002C3D002A3D00, &h002E3D002E00002C, &h314100304000303F, &h4100293F00313D00
Data &h002A3C002A410029, &h313D002C3F002C3F, &h3D002C3D00313D00, &h00250000253D002C
Data &h3D4100253F00253D, &h41313D3F00003D31, &h00003D2F3B410000, &h3A4100003D2F3B3F
Data &h412E3A3F00003D2E, &h00003D2D39410000, &h384100003D2D393F, &h412C383F00003D2C
Data &h2C383C2C38410000, &h003D00003F00003F, &h3D202C3D00003D00, &h00003525313D202C
Data &h3538000037000036, &h3800363A31353831, &h2C00352C35380035, &h3538000037000036
Data &h3800363A31353831, &h2C00412C35380035, &h003A00003800003D, &h3F2A003D2A003C2A
Data &h2C003F2C00412A00, &h00382C003F2C003D, &h382C003825003825, &h3100353100382C00
Data &h3538000037000036, &h3800363A31353831, &h2C00352C35380035, &h3538000037000036
Data &h3800363A31353831, &h2C00382C35380035, &h003C32003B32003A, &h3C33000033003C33
Data &h27003A27003C3300, &h0038270033270037, &h382C00380000382C, &h2E00352E00380000
Data &h3538300037300036, &h3800363A31353831, &h2C00352C35380035, &h3538000037000036
Data &h3800363A31353831, &h2C00412C35380035, &h003A00003800003D, &h3F2A003D2A003C2A
Data &h2C003F2C00412A00, &h003D2C003F2C003D, &h3D2C003D25003D25, &h31003831003D2C00
Data &h363D000038000037, &h3D2A363A00003D2A, &h00003A2B373D0000, &h383800003A2B373D
Data &h442C384100003D2C, &h0000412935440000, &h363A00003829353D, &h3D2A363D00003A2A
Data &h00003F2C38410000, &h3D3D00003F2C383F, &h3D2C383D313D3D31, &h25313D25313D2C38
Data &hFFFF000000000000, &hFFFFFFFFFFFFFFFF, &hFFFFFFFFFFFFFFFF

black_white_rag_music_data:
Data 888 ' Number of bytes of music data.
Data 3   ' Number of channels.
Data &h3440003A41003A41, &h3E00354100354100, &h00333F00333F0026, &h303C00303C002F3B
Data &h35002C38002A3600, &h0027330027330029, &h333F00330000333F, &h0000273F00330000
Data &h00330000333F0027, &h273F00273F00273F, &h3F00003F00270000, &h00003E00003E0000
Data &h314216273F16273D, &h4211223F27313D27, &h27313F27313D1122, &h283F1B273D1B2742
Data &h411D29421C28421C, &h1E2A3D1E2A3F1D29, &h3041202C3C202C3B, &h4120273C27303B27
Data &h27303C27303B2027, &h2D3C202C3B202C41, &h3F222E41212D4121, &h24303824303C222E
Data &h313C222E3D222E3D, &h3C1B273D27313D27, &h27313D27313D1B27, &h3139222E3A222E3A
Data &h391B273A27313A27, &h27313A27313A1B27, &h2400002000000000, &h0000000000270000
Data &h003300003000002C, &h003C000038000000, &h4400000000003F00, &h00004B0000480000
Data &h31421B273F1B273D, &h4216223F27313D27, &h27313F27313D1622, &h283F1B273D1B2742
Data &h411D29421C28421C, &h1E2A3D1E2A3F1D29, &h3041202C3C202C3B, &h411B273C27303B27
Data &h27303C27303B1B27, &h2D3C202C3B202C41, &h3F222E41212D4121, &h24303C24303D222E
Data &h3339212D35212D41, &h3F1D294129334129, &h29333C29333D1D29, &h313A222E39222E3A
Data &h3F1D294129314129, &h29313A29313D1D29, &h30381B27331B273C, &h381B273C27303C27
Data &h1E2A3A1E2A3A1B27, &h3338303338303338, &h443C3F4430333830, &h0000000000003C3F
Data &h314216273F16273D, &h4211223F27313D27, &h27313F27313D1122, &h283F1B273D1B2742
Data &h411D29421C28421C, &h1E2A3D1E2A3F1D29, &h3041202C3C202C3B, &h4120273C27303B27
Data &h27303C27303B2027, &h2D3C202C3B202C41, &h3F222E41212D4121, &h24303824303C222E
Data &h313C222E3D222E3D, &h3C1B273D27313D27, &h27313D27313D1B27, &h3139222E3A222E3A
Data &h391B273A27313A27, &h27313A27313A1B27, &h2400002000000000, &h0000000000270000
Data &h003300003000002C, &h003C000038000000, &h4400000000003F00, &h00004B0000480000
Data &h31421B273F1B273D, &h4216223F27313D27, &h27313F27313D1622, &h283F1B273D1B2742
Data &h411D29421C28421C, &h1E2A3D1E2A3F1D29, &h3041202C3C202C3B, &h411B273C27303B27
Data &h27303C27303B1B27, &h2D3C202C3B202C41, &h3F222E41212D4121, &h24303C24303D222E
Data &h3339212D35212D41, &h3F1D294129334129, &h29333C29333D1D29, &h313A222E39222E3A
Data &h3F1D294129314129, &h29313A29313D1D29, &h30381B27331B273C, &h381B273C27303C27
Data &h1E2A3A1E2A3A1B27, &h3338303338303338, &h443C3F4430333830, &h0000000000003C3F
Data &hFFFFFFFFFFFFFFFF, &hFFFFFFFFFFFFFFFF, &hFFFFFFFFFFFFFFFF

spring_music_data:
Data 1696  ' Number of bytes of music data.
Data 4     ' Number of channels.
Data &h3529000035290000, &h00003C4135293C41, &h3529000035294145, &h0000000035294145
Data &h3529414535294145, &h0000004135290043, &h3529454835294548, &h0000454835294548
Data &h3529000035294548, &h0000434635294548, &h3529000035294145, &h0000000035294145
Data &h3529414535294145, &h0000004135290043, &h3529454835294548, &h0000454835294548
Data &h3529000035294548, &h0000434635294548, &h0000414535294145, &h0000454835294346
Data &h000043462E224346, &h000041452F234145, &h3024404330244043, &h3024004030240040
Data &h0000003C0000003C, &h0000004135290041, &h3529000035294145, &h0000000035294145
Data &h3529414535294145, &h0000004135290043, &h3529454835294548, &h0000454835294548
Data &h3529000035294548, &h0000434635294548, &h3529000035294145, &h0000000035294145
Data &h3529414535294145, &h0000004135290043, &h3529454835294548, &h0000454835294548
Data &h3529000035294548, &h0000434635294548, &h3529414535294145, &h0000454835294346
Data &h3529434635294346, &h0000414535294145, &h3529404335294043, &h3C3000403C300040
Data &h3529003C3529003C, &h3529004135290041, &h3529454835294548, &h0000414535294346
Data &h3529434635294346, &h0000454835294548, &h3529464A3529464A, &h3C3045483C304548
Data &h3529454835294548, &h0000004135290041, &h3529454835294548, &h0000414535294346
Data &h3529434635294346, &h0000454835294548, &h3529464A3529464A, &h3C3045483C304548
Data &h3529454835294548, &h0000004135290041, &h3529464A3529464A, &h0000454835294548
Data &h3529454835294548, &h3C2443463C244346, &h3529414535294145, &h291D3C41291D4043
Data &h3C3000433C300043, &h3024004330240043, &h35293C4135293C41, &h35293C4135293C41
Data &h3529000035290000, &h0000004135290041, &h3529454835294548, &h0000414535294346
Data &h3529434635294346, &h0000454835294548, &h3529464A3529464A, &h3C3045483C304548
Data &h3529454835294548, &h0000004135290041, &h3529454835294548, &h0000414535294346
Data &h3529434635294346, &h0000454835294548, &h3529464A3529464A, &h3C3045483C304548
Data &h3529454835294548, &h0000004135290041, &h3529464A3529464A, &h0000454835294548
Data &h3529454835294548, &h3C2443463C244346, &h3529414535294145, &h291D3C41291D4043
Data &h3C3000433C300043, &h3024004330240043, &h35293C4135293C41, &h35293C4135293C41
Data &h3529000035290000, &h0000004135290041, &h3529000035294145, &h0000000035294145
Data &h3529414535294145, &h0000004135290043, &h3529454835294548, &h0000454835294548
Data &h3529000035294548, &h0000434635294548, &h3529000035294145, &h0000000035294145
Data &h3529414535294145, &h0000004135290043, &h3529454835294548, &h0000454835294548
Data &h3529000035294548, &h0000434635294548, &h0000414535294145, &h0000454835294346
Data &h000043462E224346, &h000041452F234145, &h3024404330244043, &h3024004030240040
Data &h0000003C0000003C, &h0000004135290041, &h3529000035294145, &h0000000035294145
Data &h3529414535294145, &h0000004135290043, &h3529454835294548, &h0000454835294548
Data &h3529000035294548, &h0000434635294548, &h3529000035294145, &h0000000035294145
Data &h3529414535294145, &h0000004135290043, &h3529454835294548, &h0000454835294548
Data &h3529000035294548, &h0000434635294548, &h3529414535294145, &h0000454835294346
Data &h3529434635294346, &h0000414535294145, &h3529404335294043, &h3C3000403C300040
Data &h3529003C3529003C, &h3529004135290041, &h3529454835294548, &h0000414535294346
Data &h3529434635294346, &h0000454835294548, &h3529464A3529464A, &h3C3045483C304548
Data &h3529454835294548, &h0000004135290041, &h3529454835294548, &h0000414535294346
Data &h3529434635294346, &h0000454835294548, &h3529464A3529464A, &h3C3045483C304548
Data &h3529454835294548, &h0000004135290041, &h3529464A3529464A, &h0000454835294548
Data &h3529454835294548, &h3C2443463C244346, &h3529414535294145, &h291D3C41291D4043
Data &h3C3000433C300043, &h3024004330240043, &h35293C4135293C41, &h35293C4135293C41
Data &h3529000035290000, &h0000004135290041, &h3529454835294548, &h0000414535294346
Data &h3529434635294346, &h0000454835294548, &h3529464A3529464A, &h3C3045483C304548
Data &h3529454835294548, &h0000004135290041, &h3529454835294548, &h0000414535294346
Data &h3529434635294346, &h0000454835294548, &h3529464A3529464A, &h3C3045483C304548
Data &h3529454835294548, &h0000004135290041, &h3529464A3529464A, &h0000454835294548
Data &h3529454835294548, &h3C2443463C244346, &h3529414535294145, &h291D3C41291D4043
Data &h3C3000433C300043, &h3024004330240043, &h35293C4135293C41, &h35293C4135293C41
Data &h3529000035290000, &h0000000035290000, &hFFFFFFFFFFFFFFFF, &hFFFFFFFFFFFFFFFF
