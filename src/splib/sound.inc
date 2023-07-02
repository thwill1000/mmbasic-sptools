' Copyright (c) 2022-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.06

'!ifdef SOUND_USE_PWM
' Preprocessor flag SOUND_USE_PWM defined
'!endif

'!uncomment_if SOUND_USE_PWM
'SetPin GP4,PWM2A
'SetPin GP6,PWM3A
'!endif

Const sound.MAX_TRACK_LEN% = 1024
Const sound.NUM_MUSIC_CHANNELS% = 3

' These would be constants but MMBasic does not support constant arrays
Dim sound.F!(127)
Dim sound.NO_MUSIC%(1)  = (&h0000000000000000, &hFFFFFFFF00000000)
Dim sound.FX_NONE%(1)   = (&hFFFFFFFFFFFFFFFF, &hFFFFFFFFFFFFFFFF)
Dim sound.FX_BLART%(1)  = (&hFFFFFF0036373C3D, &hFFFFFFFFFFFFFFFF)
Dim sound.FX_SELECT%(1) = (&hFFFFFFFF0048443C, &hFFFFFFFFFFFFFFFF)
Dim sound.FX_DIE%(3)    = (&h4748494A4B4C4D4E, &h3F40414243444546, &h0038393A3B3C3D3E, &hFFFFFFFFFFFFFFFF)
Dim sound.FX_WIPE%(3)   = (&h3F3E3D3C3B3A3938, &h4746454443424140, &h004E4D4C4B4A4948, &hFFFFFFFFFFFFFFFF)
Dim sound.FX_READY_STEADY_GO%(12)

Dim sound.music_start_ptr%
Dim sound.music_ptr%
Dim sound.current_track%
Dim sound.num_tracks%
Dim sound.fx_enabled% = 1
Dim sound.fx_ptr% = Peek(VarAddr sound.FX_NONE%())

' Initialises sound engine.
Sub sound.init(track1$, track2$)
  Local i%

  ' sound.F!(0) - rest
  ' sound.F!(1) - C0   - 16.35 Hz
  For i% = 0 To 127
    sound.F!(i%) = 440 * 2^((i% - 58 + 12) / 12.0)
  Next

  Read Save
  Restore sound.ready_steady_go_data:
  For i% = 0 To 12
    Read sound.FX_READY_STEADY_GO%(i%)
  Next
  Read Restore

  If track1$ = "" Then
    sound.play_music(sound.NO_MUSIC%())
  Else
    sound.num_tracks% = 2
    Local tracks$(sound.num_tracks%) Length 32
    tracks$(1) = track1$
    tracks$(2) = Choice(track2$ = "", track1$, track2$)

    ' 2D array indexed (notes, tracks) because that is the way
    ' incrementing a pointer through the data naturally works.
    Dim sound.MUSIC%((sound.MAX_TRACK_LEN% \ 8) - 1, sound.num_tracks% - 1)

    Local count%, j%, num_channels%, track$
    For i% = 1 to sound.num_tracks%
      track$ = tracks$(i%)
      Restore track$
      Read count%, num_channels%
      If count% > sound.MAX_TRACK_LEN% Then
        Local err$ = "Track '" + track$ + "' is too long; "
        Error err$ + "expected " + Str$(sound.MAX_TRACK_LEN%) + " bytes but found " + Str$(count%)
      EndIf
      If num_channels% <> sound.NUM_MUSIC_CHANNELS% Then
        Local err$ = "Track '" + track$ + "' has wrong number of channels; "
        Error err$ + "expected " + Str$(sound.NUM_CHANNELS%) + ", but found " + Str$(num_channels%)
      EndIf
      For j% = 1 To count% \ 8
        Read sound.MUSIC%(j% - 1, i% - 1)
      Next j%
    Next

    sound.play_music(sound.MUSIC%())
  EndIf

  ' Music and sound effects are played on SetTick interrupts.
  sound.start_music()
  SetTick 40, sound.fx_int, 2
End Sub

' Terminates sound engine.
Sub sound.term()
'!uncomment_if SOUND_USE_PWM
  ' Pwm 2, Off
  ' Pwm 3, Off
'!endif
'!ifndef SOUND_USE_PWM
  Play Stop
'!endif
End Sub

' Enables/disables sound fx.
Sub sound.enable_fx(z%)
  sound.fx_enabled% = z%
End Sub

' Gets the current music and sound fx enabled state.
'
' @return  if bit 0 is set then sound fx are enabled,
'          if bit 1 is set then music is enabled.
Function sound.get_state%()
  sound.get_state% = sound.fx_enabled%
  Inc sound.get_state%, (sound.music_start_ptr% = Peek(VarAddr sound.MUSIC%())) * 2
End Function

' Plays a music score.
Sub sound.play_music(music%())
  sound.music_start_ptr% = Peek(VarAddr music%())
  sound.music_ptr% = sound.music_start_ptr%
  sound.current_track% = 1
End Sub

' Starts music playing interrupt.
Sub sound.start_music()
  SetTick 200, sound.music_int, 1
End Sub

' Stops music playing interrupt.
Sub sound.stop_music()
  SetTick 0, 0, 1
'!uncomment_if SOUND_USE_PWM
  ' Pwm 2, sound.F!(0), 0
'!endif
'!ifndef SOUND_USE_PWM
  Play Sound 1, M, O
  Play Sound 2, M, O
  Play Sound 3, M, O
'!endif
End Sub

' Called from interrupt to play next note of music.
Sub sound.music_int()
  Local n% = Peek(Byte sound.music_ptr%)
  If n% < 255 Then
'!uncomment_if SOUND_USE_PWM
  ' If n% = 0 Then n% = Peek(Byte sound.music_ptr% + 1)
  ' If n% = 0 Then n% = Peek(Byte sound.music_ptr% + 2)
  ' Pwm 2, sound.F!(n%), (n% > 0) * 2
'!endif
'!ifndef SOUND_USE_PWM
    Play Sound 1, B, T, sound.F!(n%), (n% > 0) * 15
    n% = Peek(Byte sound.music_ptr% + 1)
    Play Sound 2, B, T, sound.F!(n%), (n% > 0) * 15
    n% = Peek(Byte sound.music_ptr% + 2)
    Play Sound 3, B, T, sound.F!(n%), (n% > 0) * 15
'!endif
    Inc sound.music_ptr%, 3
    Exit Sub
  EndIf

  If sound.music_start_ptr% = Peek(VarAddr sound.NO_MUSIC%()) Then
    sound.music_ptr% = sound.music_start_ptr%
  Else
    Inc sound.current_track%
    If sound.current_track% > sound.num_tracks% Then sound.current_track% = 1
    sound.music_ptr% = sound.music_start_ptr% + (sound.current_track% - 1) * sound.MAX_TRACK_LEN%
  EndIf
End Sub

' Plays a new sound effect.
Sub sound.play_fx(fx%(), wait_%)
  If Not sound.fx_enabled% Then Exit Sub
  If wait_% Then sound.wait_for_fx()
  sound.fx_ptr% = Peek(VarAddr fx%())

  ' Wait for first note of new sound effect to play.
  Do While sound.fx_ptr% = Peek(VarAddr fx%()) : Loop
End Sub

' Waits for current sound effect to end.
Sub sound.wait_for_fx()
  If Not sound.fx_enabled% Then Exit Sub
  Do While Peek(Byte sound.fx_ptr%) <> &hFF : Loop
End Sub

' Called from interrupt to play next note of current sound effect.
Sub sound.fx_int()
  Local n% = Peek(Byte sound.fx_ptr%)
  If n% = 255 Then Exit Sub
'!uncomment_if SOUND_USE_PWM
  ' Pwm 3, sound.F!(n%), (n% > 0) * 5
'!endif
'!ifndef SOUND_USE_PWM
  Play Sound 4, B, T, sound.F!(n%), (n% > 0) * 25
'!endif
  Inc sound.fx_ptr%
End Sub

sound.ready_steady_go_data:
Data &h3C3C3C3C3C3C3C3C, &h3C3C3C3C3C3C3C3C, &h0000000000000000, &h0000000000000000
Data &h3C3C3C3C3C3C3C3C, &h3C3C3C3C3C3C3C3C, &h0000000000000000, &h0000000000000000
Data &h4848484848484848, &h4848484848484848, &h4848484848484848, &h0000000048484848
Data &hFFFFFFFFFFFFFFFF
