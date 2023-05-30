' Copyright (c) 2022-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!ifndef NO_INCLUDE_GUARDS
On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.provides("sound")
If sys.err$ <> "" Then Error sys.err$
'!endif

'!if !defined(SOUND_MONO) && !defined(SOUND_RAW)
  '!if defined(PGLCD1)
    '!define SOUND_RAW
  '!endif
'!endif

'!if defined(SOUND_MONO) && defined(SOUND_RAW)
  '!error "File 'sound.inc' was transpiled with more than one of SOUND_MONO and SOUND_RAW defined"
'!endif

'!info defined SOUND_MONO
'!info defined SOUND_RAW

'!uncomment_if SOUND_RAW
'SetPin GP4,PWM2A
'SetPin GP6,PWM3A
'!endif

Const sound.VERSION% = 900 ' 0.9.0

'Const sound.MAX_TRACK_LEN% = 1024
'Const sound.NUM_MUSIC_CHANNELS% = 3
Const sound.FX_FLAG% = &b01
Const sound.MUSIC_FLAG% = &b10

Dim sound.F!(127)
Dim sound.FX_BLART%(2)
Dim sound.FX_SELECT%(2)
Dim sound.FX_DIE%(4)
Dim sound.FX_WIPE%(4)
Dim sound.FX_READY_STEADY_GO%(13)

Dim sound.enabled%
Dim sound.fx_int$
Dim sound.fx_ptr%
Dim sound.fx_start_ptr%
Dim sound.music_done_cb$
Dim sound.music_int$
Dim sound.music_ptr%
Dim sound.music_start_ptr%

' Initialises sound engine.
Sub sound.init(fx_int$, music_int$)
  sound.fx_int$ = Choice(Len(fx_int$), fx_int$, "sound.fx_default_int")
  sound.music_int$ = Choice(Len(music_int$), music_int$, "sound.music_default_int")
  Local i%

  ' sound.F!(0) - rest
  ' sound.F!(1) - C0   - 16.35 Hz
'!uncomment_if PGLCD2
  ' Const offset% = 12
'!endif
'!if !defined(PGLCD2)
  Const offset% = 0
'!endif
  For i% = 0 To 127
    sound.F!(i%) = 440 * 2^((i% - 58 + offset%) / 12.0)
  Next

  sound.load_data("sound.blart_data", sound.FX_BLART%())
  sound.load_data("sound.select_data", sound.FX_SELECT%())
  sound.load_data("sound.die_data", sound.FX_DIE%())
  sound.load_data("sound.wipe_data", sound.FX_WIPE%())
  sound.load_data("sound.ready_steady_go_data", sound.FX_READY_STEADY_GO%())

  sound.start()
End Sub

' Starts the SetTick interrupts for music and fx.
Sub sound.start(flags%)
  Local start% = Choice(flags% = 0, sound.FX_FLAG% Or sound.MUSIC_FLAG%, flags%)
  start% = start% And (Inv sound.enabled%)
  If start% And sound.MUSIC_FLAG% Then
    Execute "SetTick 200, " + sound.music_int$ + ", 1"
    sound.enabled% = sound.enabled% Or sound.MUSIC_FLAG%
  EndIf
  If start% And sound.FX_FLAG% Then
    Execute "SetTick 40, " + sound.fx_int$ + ", 2"
    sound.enabled% = sound.enabled% Or sound.FX_FLAG%
  EndIf
End Sub

' Stops SetTick interrupts for music and fx and silences all channels.
Sub sound.stop(flags%)
  Local stop% = Choice(flags% = 0, sound.FX_FLAG% Or sound.MUSIC_FLAG%, flags%)
  stop% = stop% And sound.enabled%
  Local raw%
'!uncomment_if SOUND_RAW
'  raw% = 1
'!endif
  If stop% And sound.MUSIC_FLAG% Then
    SetTick 0, 0, 1
    If raw% Then
      Pwm 2, sound.F!(0), 0
    Else
      Play Sound 1, B, O
      Play Sound 2, B, O
      Play Sound 3, B, O
    EndIf
    sound.enabled% = sound.enabled% Xor sound.MUSIC_FLAG%
    sound.music_ptr% = 0
  EndIf

  If stop% And sound.FX_FLAG% Then
    SetTick 0, 0, 2
    If raw% Then
      Pwm 3, sound.F!(0), 0
    Else
      Play Sound 4, B, O
    EndIf
    sound.enabled% = sound.enabled% Xor sound.FX_FLAG%
    sound.fx_ptr% = 0
  EndIf
End Sub

Function sound.is_playing%(flags%)
  Select Case flags%
    Case 0
      sound.is_playing% = (sound.music_ptr% > 0) Or (sound.fx_ptr% > 0)
    Case sound.FX_FLAG%
      sound.is_playing% = sound.fx_ptr% > 0
    Case sound.MUSIC_FLAG%
      sound.is_playing% = sound.music_ptr% > 0
  End Select
End Function

' Terminates sound engine.
Sub sound.term()
  sound.stop()
'!ifndef SOUND_RAW
  Play Stop
'!endif
'!uncomment_if SOUND_RAW
  ' Pwm 2, Off
  ' Pwm 3, Off
'!endif
End Sub

' Loads music/fx from DATA statements into notes%() array.
Sub sound.load_data(data_label$, notes%())
  Local i%, num_notes%, num_channels%
  Read Save
  Restore data_label$
  Read num_notes%, num_channels%
  Const max_notes% = 8 * (Bound(notes%(), 1) - Bound(notes%(), 0))
  If num_notes% > max_notes% Then
    Local err$ = "Too much DATA; "
    Error err$ + "expected " + Str$(max_notes%) + " bytes but found " + Str$(num_notes%)
  EndIf
  notes%(0) = num_channels% + 256 * num_notes%
  ' If num_notes% > sound.MAX_TRACK_LEN% Then
  '   Local err$ = "Data '" + data_label$ + "' is too long; "
  '   Error err$ + "expected " + Str$(sound.MAX_TRACK_LEN%) + " bytes but found " + Str$(num_notes%)
  ' EndIf
  ' If num_channels% <> sound.NUM_MUSIC_CHANNELS% Then
  '   Local err$ = "Data '" + data_label$ + "' has wrong number of channels; "
  '   Error err$ + "expected " + Str$(sound.NUM_CHANNELS%) + ", but found " + Str$(num_channels%)
  ' EndIf
  For i% = 1 To num_notes% \ 8 : Read notes%(i%) : Next
  Read Restore
End Sub

' Plays a music score.
Sub sound.play_music(music%(), done_cb$)
  If Not (sound.enabled% And sound.MUSIC_FLAG%) Then Error "Music interrupt not enabled"
  sound.music_start_ptr% = Peek(VarAddr music%())
  sound.music_ptr% = sound.music_start_ptr% + 8
  sound.music_done_cb$ = done_cb$
End Sub

' Interrupt routine to play next note of music using PLAY SOUND with B, S options.
Sub sound.music_default_int()
  If Not sound.music_ptr% Then Exit Sub
  Local n% = Peek(Byte sound.music_ptr%)
  If n% < 255 Then
    Play Sound 1, B, S, sound.F!(n%), (n% > 0) * 15
    n% = Peek(Byte sound.music_ptr% + 1)
    Play Sound 2, B, S, sound.F!(n%), (n% > 0) * 15
    n% = Peek(Byte sound.music_ptr% + 2)
    Play Sound 3, B, S, sound.F!(n%), (n% > 0) * 15
    Inc sound.music_ptr%, 3
    Exit Sub
  EndIf
  sound.music_ptr% = 0
  If Len(sound.music_done_cb$) Then Call sound.music_done_cb$
End Sub

' Interrupt routine to play next note of music using raw PWM.
Sub sound.music_raw_int()
  If Not sound.music_ptr% Then Exit Sub
  Local n% = Peek(Byte sound.music_ptr%)
  If n% < 255 Then
    If Not n% Then n% = Peek(Byte sound.music_ptr% + 1)
    If Not n% Then n% = Peek(Byte sound.music_ptr% + 2)
    Pwm 2, sound.F!(n%), (n% > 0) * 2
    Inc sound.music_ptr%, 3
    Exit Sub
  EndIf
  sound.music_ptr% = 0
  If Len(sound.music_done_cb$) Then Call sound.music_done_cb$
End Sub

' Plays a new sound effect.
Sub sound.play_fx(fx%(), wait_%)
  If Not (sound.enabled% And sound.FX_FLAG%) Then Error "Sound FX interrupt not enabled"
  If wait_% Then Do While sound.fx_ptr% : Loop
  sound.fx_start_ptr% = Peek(VarAddr fx%())
  sound.fx_ptr% = sound.fx_start_ptr% + 8

  ' Wait for first note of new sound effect to play.
  Do While sound.fx_ptr% = sound.fx_start_ptr% + 8 : Loop
End Sub

' Interrupt routine to play next note of sound fx using PLAY SOUND with B, S options.
Sub sound.fx_default_int()
  If Not sound.fx_ptr% Then Exit Sub
  Local n% = Peek(Byte sound.fx_ptr%)
  If n% < 255 Then
    Play Sound 4, B, S, sound.F!(n%), (n% > 0) * 25
    Inc sound.fx_ptr%
    Exit Sub
  EndIf
  sound.fx_ptr% = 0
End Sub

' Interrupt routine to play next note of sound fx using raw PWM.
Sub sound.fx_raw_int()
  If Not sound.fx_ptr% Then Exit Sub
  Local n% = Peek(Byte sound.fx_ptr%)
  If n% < 255 Then
    Pwm 3, sound.F!(n%), (n% > 0) * 5
    Inc sound.fx_ptr%
    Exit Sub
  EndIf
  sound.fx_ptr% = 0
End Sub

sound.blart_data:
Data 16 ' Number of bytes of music data.
Data 1  ' Number of channels.
Data &hFFFFFF0036373C3D, &hFFFFFFFFFFFFFFFF

sound.select_data:
Data 16 ' Number of bytes of music data.
Data 1  ' Number of channels.
Data &hFFFFFFFF0048443C, &hFFFFFFFFFFFFFFFF

sound.die_data:
Data 32 ' Number of bytes of music data.
Data 1  ' Number of channels.
Data &h4748494A4B4C4D4E, &h3F40414243444546, &h0038393A3B3C3D3E, &hFFFFFFFFFFFFFFFF

sound.wipe_data:
Data 32 ' Number of bytes of music data.
Data 1  ' Number of channels.
Data &h3F3E3D3C3B3A3938, &h4746454443424140, &h004E4D4C4B4A4948, &hFFFFFFFFFFFFFFFF

sound.ready_steady_go_data:
Data 104 ' Number of bytes of music data.
Data 1   ' Number of channels.
Data &h3C3C3C3C3C3C3C3C, &h3C3C3C3C3C3C3C3C, &h0000000000000000, &h0000000000000000
Data &h3C3C3C3C3C3C3C3C, &h3C3C3C3C3C3C3C3C, &h0000000000000000, &h0000000000000000
Data &h4848484848484848, &h4848484848484848, &h4848484848484848, &h0000000048484848
Data &hFFFFFFFFFFFFFFFF
