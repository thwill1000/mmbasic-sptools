' Code Copyright (c) 2022-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Musical compositions in MMBasic played via PWM or PLAY SOUND
'   - also encodes music as DATA statements for playing outside of this program.

Option Base 0
Option Default None
Option Explicit On

Option Break 4
On Key 3, on_exit

' 0 - use PLAY SOUND
' 1 - use PWM on 4 channels
' 2 - use PWM on 2 channels (PicoGAME LCD)
'!comment_if PICOGAME_LCD
Const PLAY_MODE% = 0
'!endif
'!uncomment_if PICOGAME_LCD
' Const PLAY_MODE% = 2
'!endif

If PLAY_MODE% = 1 Then
  SetPin GP2,PWM1A
  SetPin GP4,PWM2A
  SetPin GP6,PWM3A
  SetPin GP8,PWM4A
ElseIf PLAY_MODE% = 2 Then
  SetPin GP4,PWM2A
  SetPin GP6,PWM3A
EndIf

' Set true (1) to just process and not play the music data.
Const PROCESS_ONLY% = 0

Const FILENAME$ = "spmusic"
Const OUTPUT_DIR$ = "output"
Const SZ% = 256
' Const NUM_CHANNELS% = music.prompt_for_num_channels%()
' Const NUM_CHANNELS% = 1
Const NUM_CHANNELS% = 3
Const OCTAVE_SHIFT% = 0
Const MUSIC_TICK_DURATION% = 200
Const FX_TICK_DURATION% = 40

Dim channel1%(SZ%), channel2%(SZ%), channel3%(SZ%), channel4%(SZ%), music%(SZ% * 4)
Dim err$
Dim int_time!
Dim FREQUENCY!(127)
Dim music_ptr%

If InStr(MM.Device$, "PicoMite") Then Save FILENAME$ + ".bas"

music.init_globals()

If Not Mm.Info(Exists Dir OUTPUT_DIR$) Then MkDir OUTPUT_DIR$

' Music
music.run("autumn_festival", MUSIC_TICK_DURATION%)
music.run("black_white_rag", MUSIC_TICK_DURATION%)
music.run("entertainer", MUSIC_TICK_DURATION%)
music.run("mo_li_hua", MUSIC_TICK_DURATION%)
music.run("spring", MUSIC_TICK_DURATION%)

' Sound FX
music.run("attack", FX_TICK_DURATION%)
music.run("blart", FX_TICK_DURATION%)
music.run("die", FX_TICK_DURATION%)
music.run("flood", FX_TICK_DURATION%)
music.run("ready_steady_go", FX_TICK_DURATION%)
music.run("select", FX_TICK_DURATION%)
music.run("wipe", FX_TICK_DURATION%)

Print "Time in interrupt:" int_time!

on_exit()

' Interrupt routine to stop music and restore default Break Key.
Sub on_exit()
  music.term()
  Option Break 3
  End
End Sub

Sub music.term()
  Local channel%
  SetTick 0, 0, 1
  Select Case PLAY_MODE%
    Case 0
      Play Stop
    Case 1
      For channel% = 1 To 4 : Pwm channel%, Off : Next
    Case 2
      For channel% = 2 To 3 : Pwm channel%, Off : Next
  End Select
End Sub

Sub music.stop()
  Local channel%
  SetTick 0, 0, 1
  Select Case PLAY_MODE%
    Case 0
      For channel% = 1 To 4 : Play Sound channel%, B, O : Next
    Case 1
      For channel% = 1 To 4 : Pwm channel%, FREQUENCY!(0), 0 : Next
    Case 2
      For channel% = 2 To 3 : Pwm channel%, FREQUENCY!(0), 0 : Next
  End Select
End Sub

' Prompts user for number of channels to encode / play.
Function music.prompt_for_num_channels%()
  Local s$
  Do
    Line Input "How many channels (1-4)? ", s$
    Select Case Val(s$)
      Case 1 To 4 : Exit Do
    End Select
  Loop
  music.prompt_for_num_channels% = Val(s$)
End Function

' Initialises global variables.
Sub music.init_globals()
  Local i%
  ' FREQUENCY!(1) - C0   - 16.35 Hz
  For i% = 0 To 127
    FREQUENCY!(i%) = 440 * 2^((i% + 12 - 58) / 12.0)
  Next
End Sub

' Composes, processes, saves and plays the named tune.
Sub music.run(name$, tick_duration%)
  ? name$
  music.clear()
  Call "music.compose_" + name$
  music.process()
  music.write_data(name$)
  If Not PROCESS_ONLY% Then
    music.play(tick_duration%)
    Pause 2000
  EndIf
End Sub

' Clears the tune data.
Sub music.clear()
  Local i%
  For i% = 1 To 4
    Execute "LongString Clear channel" + Str$(i%) + "%()"
  Next
  LongString Clear music%()
End Sub

' Parses comma separated list of notes.
'
' @param  channel_idx%  parsed notes is appended to data for this channel.
' @param  s$            comma separated list.
Sub music.parse(channel_idx%, s$)
  Local s_idx% = 1
  Local ch$ = ","
  Do While ch$ = ","
    If music.parse_note%(channel_idx%, s$, s_idx%) <> 0 Then
      Error err$ + " : s_idx = " + Str$(s_idx%)
    EndIf
    Inc s_idx%
    ch$ = Mid$(s$, s_idx%, 1)
    Inc s_idx%
  Loop
End Sub

' Parses single note.
'
' @param  channel_idx%  parsed notes is appended to data for this channel.
' @param  s$            note is parsed from this string ...
' @param  s_idx%        ... starting at this index. On exit this will
'                       contain the index of the last character parsed.
' @return               0 on success, -1 on error. Error message will
'                       be in the global err$ variable.
Function music.parse_note%(channel_idx%, s$, s_idx%)
  music.parse_note% = -1
  Local i%
  Local ch$ = Mid$(s$, s_idx%, 1)

  ' Parse duration.
  Local duration%
  Select Case ch$
    Case "q": duration% = 1
    Case "1", "2", "3", "4": duration% = 2 * Val(ch$)
    Case Else
      err$ = "Syntax error: expected duration"
      Exit Function
  End Select

  Inc s_idx%
  ch$ = Mid$(s$, s_idx%, 1)

  ' Parse note: 0 = Rest, 1 = C0, ...
  Local n%
  Select Case ch$
    Case "A" : n% = 10
    Case "B" : n% = 12
    Case "C" : n% = 1
    Case "D" : n% = 3
    Case "E" : n% = 5
    Case "F" : n% = 6
    Case "G" : n% = 8
    Case "-" : n% = 0
    Case Else
      err$ = "Syntax error: expected note"
      Exit Function
  End Select

  If n% = 0 Then
    For i% = 1 To duration%
      Execute "LongString Append channel" + Str$(channel_idx%) + "%(), Chr$(0)"
    Next
    music.parse_note% = 0
    Exit Function
  EndIf

  Inc s_idx%
  ch$ = Mid$(s$, s_idx%, 1)

  ' Parse b or #.
  Local off% = 0
  Select Case ch$
    Case "b" : off% = -1
    Case "#" : off% = 1
  End Select
  If off% <> 0 Then
    Inc n%, off%
    Inc s_idx%
    ch$ = Mid$(s$, s_idx%, 1)
  EndIf

  ' Parse octave.
  If Not Instr("012345678", ch$) Then
    err$ = "Syntax error: expected octave"
    Exit Function
  EndIf
  Inc n%, 12 * (OCTAVE_SHIFT% + Val(ch$))

  ' Write note into buffer.
  For i% = 1 To duration%
      Execute "LongString Append channel" + Str$(channel_idx%) + "%(), Chr$(n%)"
  Next

  music.parse_note% = 0
End Function

' Combines the individual channels into a single global music%() array.
Sub music.process()
  Local i%, j%

  ' Determine the maximum channel length.
  Local max_len% = 0
  For i% = 1 To NUM_CHANNELS%
    max_len% = Max(max_len%, Eval("LLen(channel" + Str$(i%) + "%())"))
  Next
  Inc max_len%, 1 ' Always pad with at least one rest.

  ' Pad each channel with rests until they are all the maximum length.
  For i% = 1 To NUM_CHANNELS%
    Do While Eval("LLen(channel" + Str$(i%) + "%())") < max_len%
      Execute "LongString Append channel" + Str$(i%) + "%(), Chr$(0)"
    Loop
  Next

  ' Pad each channel with &hFF until reach multiple of 8,
  ' always include at least one &hFF.
  Do
    Inc max_len%
    For i% = 1 To NUM_CHANNELS%
      Execute "LongString Append channel" + Str$(i%) + "%(), Chr$(&hFF)"
    Next
  Loop Until max_len% Mod 8 = 0

  ' Combine the channels into a single music buffer.
  For i% = 0 To max_len% - 1
    For j% = 1 To NUM_CHANNELS%
      Execute "LongString Append music%(), Chr$(LGetByte(channel" + Str$(j%) + "%(), i%))"
    Next
  Next
End Sub

' Writes music%() array into a file as DATA statements.
Sub music.write_data(name$)
  Local count% = 0, i%, p% = Peek(VarAddr music%()) + 8
  Open OUTPUT_DIR$ + "/" + name$ + ".inc" For Output As #1
  Print #1, name$ "_data:"
  Print #1, "Data " Format$(LLen(music%()), "%-6g") "' Number of bytes of music data."
  Print #1, "Data " Format$(NUM_CHANNELS%,"%-6g") "' Number of channels."
  For i% = 0 To LLen(music%()) - 1 Step 8
    Print #1, Choice(count% = 0, "Data ", ", ");
    Print #1, "&h" Hex$(Peek(Integer p%), 16);
    Inc p%, 8
    Inc count%
    If count% = 4 Then Print #1 : count% = 0
  Next
  Close #1
End Sub

' Plays the contents of the music%() array using interrupts.
Sub music.play(tick_duration%)
  music_ptr% = Peek(VarAddr music%()) + 8
  SetTick tick_duration%, music.play_interrupt, 1
  Do While music_ptr% <> 0 : Loop
  music.stop()
End Sub

' Interrupt routine playing a single half-beat (per channel) from the music%() array.
Sub music.play_interrupt()
  Local i%, n%, t! = Timer
  For i% = 1 To Choice(PLAY_MODE% = 2, 1,  NUM_CHANNELS%)
    n% = Peek(Byte music_ptr%)
    If n% = 255 Then
      'Print Str$(i%) ": Halted"
      music_ptr% = 0
      Exit For
    EndIf
    Select Case PLAY_MODE%
      Case 0
        Play Sound i%, B, T, FREQUENCY!(n%), (n% > 0) * 15
      Case 1
        Pwm i%, FREQUENCY!(n%), (n% > 0) * 5
      Case 2
        ' If the 1st channel is a rest then try the 2nd.
        If n% = 0 And NUM_CHANNELS% > 1 Then n% = Peek(Byte music_ptr% + 1)
        ' If the 2nd channel is also a rest then try the 3rd.
        If n% = 0 And NUM_CHANNELS% > 2 Then n% = Peek(Byte music_ptr% + 2)
        Pwm 2, FREQUENCY!(n%), (n% > 0) * 5
    End Select
    'Print Str$(i%) ": " Choice(n% = 0, "Rest", Str$(FREQUENCY!(n%)) + " hz")
    Inc music_ptr%, Choice(PLAY_MODE% = 2, NUM_CHANNELS%, 1)
  Next
  Inc int_time!, Timer - t!
End Sub

Sub music.compose_blart()
  music.parse(1, "qC5,qB4,qF#4,qF4")
End Sub

Sub music.compose_attack()
  music.parse(1, "qD#4,q-,qD4,q-,qC#4,q-,1C4,q-")
End Sub

Sub music.compose_flood()
  music.parse(1, "2C4,2C#4,2D4,2D#4,2E4,2F4,2F#4,2G4,2G#4,2A4,2Bb4,2B4,4C5")
End Sub

Sub music.compose_die()
  music.parse(1, "qF6,qE6,qEb6,qD6,qC#6,qC6,qB5,qA#5")
  music.parse(1, "qA5,qAb5,qG5,qF#5,qF5,qE5,qEb5,qD5")
  music.parse(1, "qC#5,qC5,qB4,qA#4,qA4,qAb4,qG4,q-")
End Sub

Sub music.compose_select()
  music.parse(1, "qB4,qG5,qB5,q-")
End Sub

Sub music.compose_ready_steady_go()
  music.parse(1, "4B4,4B4,4-,4-,4B4,4B4,4-,4-,4B5,4B5,4B5,2B5,2-")
End Sub

Sub music.compose_wipe()
  music.parse(1, "qG4,qAb4,qA4,qA#4,qB4,qC5,qC#5,qD5")
  music.parse(1, "qEb5,qE5,qF5,qF#5,qG5,qAb5,qA5,qA#5")
  music.parse(1, "qB5,qC6,qC#6,qD6,qEb6,qE6,qF6,q-")
End Sub

' Spring - by Antonio Vivaldi - 4 channels.
Sub music.compose_spring()

  ' ---------- Line 1 ----------
  music.parse(1, "1-,1E5")
  music.parse(2, "1-,1B4")
  music.parse(3, "1E3,qE3,q-")
  music.parse(4, "1E4,qE4,q-")
  Local i%,j%
  For i% = 1 To 2
  music.parse(1, "qG#5,q-,qG#5,q-,1G#5,qF#5,qE5,2B5,qB5,q-,qB5,qA5")
  music.parse(1, "qG#5,q-,qG#5,q-,1G#5,qF#5,qE5,2B5,qB5,q-,qB5,qA5")
  music.parse(1, "1G#5,qA5,qB5,1A5,1G#5,1F#5,1D#5,1B4,1E5")

  music.parse(2, "qE5,q-,qE5,q-,1E5,1-,2G#5,qG#5,q-,qG#5,qF#5")
  music.parse(2, "qE5,q-,qE5,q-,1E5,1-,2G#5,qG#5,q-,qG#5,qF#5")
  music.parse(2, "1E5,qF#5,qG#5,1F#5,1E5,1D#5,3-")

  music.parse(3, "1E3,qE3,q-,1E3,qE3,q-,1E3,qE3,q-,1E3,qE3,q-")
  music.parse(3, "1E3,qE3,q-,1E3,qE3,q-,1E3,qE3,q-,1E3,qE3,q-")
  music.parse(3, "qE3,q-,qE3,q-,qA2,q-,qA#2,q-,2B2,1-,qE3,q-")

  music.parse(4, "1E4,qE4,q-,1E4,qE4,q-,1E4,qE4,q-,1E4,qE4,q-")
  music.parse(4, "1E4,qE4,q-,1E4,qE4,q-,1E4,qE4,q-,1E4,qE4,q-")
  music.parse(4, "qE4,q-,qE4,q-,qA3,q-,qA#3,q-,2B3,1-,qE4,q-")

  ' ---------- Line 2 ----------
  music.parse(1, "qG#5,q-,qG#5,q-,1G#5,qF#5,qE5,2B5,qB5,q-,qB5,qA5")
  music.parse(1, "qG#5,q-,qG#5,q-,1G#5,qF#5,qE5,2B5,qB5,q-,qB5,qA5")
  music.parse(1, "1G#5,qA5,qB5,1A5,1G#5,1F#5,1D#5,1B4,1E5")

  music.parse(2, "qE5,q-,qE5,q-,1E5,1-,2G#5,qG#5,q-,qG#5,qF#5")
  music.parse(2, "qE5,q-,qE5,q-,1E5,1-,2G#5,qG#5,q-,qG#5,qF#5")
  music.parse(2, "1E5,qF#5,qG#5,1F#5,1E5,1D#5,3-")

  music.parse(3, "1E3,qE3,q-,1E3,qE3,q-,1E3,qE3,q-,1E3,qE3,q-")
  music.parse(3, "1E3,qE3,q-,1E3,qE3,q-,1E3,qE3,q-,1E3,qE3,q-")
  music.parse(3, "1E3,qE3,q-,1E3,qE3,q-,1E3,1B3,2E3")

  music.parse(4, "1E4,qE4,q-,1E4,qE4,q-,1E4,qE4,q-,1E4,qE4,q-")
  music.parse(4, "1E4,qE4,q-,1E4,qE4,q-,1E4,qE4,q-,1E4,qE4,q-")
  music.parse(4, "1E4,qE4,q-,1E4,qE4,q-,1E4,1B4,2E4")

  For j% = 1 To 2
  music.parse(1, "1B5,qA5,qG#5,1A5,1B5,1C#6,2B5,1E5")
  music.parse(2, "1G#5,qF#5,qE5,1F#5,1G#5,1A5,2G#5,1-")
  music.parse(3, "1E3,qE3,q-,1E3,qE3,q-,1E3,1B3,1E3,qE3,q-")
  music.parse(4, "1E4,qE4,q-,1E4,qE4,q-,1E4,1B4,1E4,qE4,q-")

  ' ---------- Line 3 ----------
  music.parse(1, "1B5,qA5,qG#5,1A5,1B5,1C#6,2B5,1E5")
  music.parse(1, "1C#6,2B5,1A5,1G#5,qF#5,qE5,2F#5")
  If i% = 2 And j% = 2 Then
    music.parse(1, "2E5,2-")
  Else
    music.parse(1, "2E5,1-,1E5")
  EndIf  

  music.parse(2, "1G#5,qF#5,qE5,1F#5,1G#5,1A5,2G#5,1-")
  music.parse(2, "1A5,2G#5,1F#5,1E5,qD#5,qB4,2-")
  music.parse(2, "2B4,2-")

  music.parse(3, "1E3,qE3,q-,1E3,qE3,q-,1E3,1B3,1E3,qE3,q-")
  music.parse(3, "1E3,qE3,q-,1E3,1B2,1E3,1E2,1B3,1B2")
  music.parse(3, "3E3,qE3,q-")

  music.parse(4, "1E4,qE4,q-,1E4,qE4,q-,1E4,1B4,1E4,qE4,q-")
  music.parse(4, "1E4,qE4,q-,1E4,1B4,1E4,1E3,1B4,1B3")
  music.parse(4, "3E4,qE4,q-")
  Next j%
  Next i%
End Sub

' The Entertainer - by Scott Joplin - 3 channels.
Sub music.compose_entertainer()
  ' ---------- Line 0 ----------

  music.parse(1, "qD4,qD#4")

  music.parse(2, "1-")

  music.parse(3, "1-")

  ' ---------- Line 1 ----------

  music.parse(1, "qE4,1C5,qE4,1C5,qE4,qC5")
  music.parse(1, "2C5,q-,qC5,qD5,qD#5")
  music.parse(1, "qE5,qC5,qD5,qE5,qE5,qB4,1D5")
  music.parse(1, "3C5,qD4,qD#4")

  music.parse(2, "1C4,1C3,1D#3,1E3")
  music.parse(2, "1F3,1G3,1A3,1B3")
  music.parse(2, "1C4,1E3,1F3,1G3")
  music.parse(2, "1C3,1G3,1C4,qC4,q-")

  music.parse(3, "4-")
  music.parse(3, "4-")
  music.parse(3, "4-")
  music.parse(3, "4-")

  ' ---------- Line 2 ----------

  music.parse(1, "qE4,1C5,qE4,1C5,qE4,qC5")
  music.parse(1, "3C5,qA4,qG4")
  music.parse(1, "qF#4,qA4,qC5,qE5,qE5,qD5,qC5,qA4")
  music.parse(1, "3D5,qD4,qD#4")

  music.parse(2, "1C4,1C3,1D#3,1E3")
  music.parse(2, "1F3,1G3,1A3,1C#3")
  music.parse(2, "1D3,1F#3,1A3,1D3")
  music.parse(2, "1G3,1F3,1E3,1D3")

  music.parse(3, "4-")
  music.parse(3, "4-")
  music.parse(3, "4-")
  music.parse(3, "4-")

  ' ---------- Line 3 ----------

  music.parse(1, "qE4,1C5,qE4,1C5,qE4,qC5")
  music.parse(1, "2C5,q-,qC5,qD5,qD#5")
  music.parse(1, "qE5,qC5,qD5,qE5,qE5,qB4,1D5")
  music.parse(1, "2C5,qC5,q-,qC5,qD5")

  music.parse(2, "1C3,1C4,1D#3,1E3")
  music.parse(2, "1F3,1G3,1A3,1B3")
  music.parse(2, "1C4,1E3,1F3,1G3")
  music.parse(2, "1C4,1G3,2C3")

  music.parse(3, "4-")
  music.parse(3, "4-")
  music.parse(3, "4-")
  music.parse(3, "4-")

  ' ---------- Line 4 ----------

  music.parse(1, "qE5,qC5,qD5,qE5,qE5,qC5,qD5,qC5")
  music.parse(1, "qE5,qC5,qD5,qE5,qE5,qC5,qD5,qC5")
  music.parse(1, "qE5,qC5,qD5,qE5,qE5,qB4,1D5")
  music.parse(1, "2C5,qC5,qE4,qF4,qF#4")

  music.parse(2, "qC5,q-,qC5,q-,qBb4,q-,qBb4,q-")
  music.parse(2, "qA4,q-,qA4,q-,qAb4,q-,qAb4,q-")
  music.parse(2, "qG4,q-,qG4,q-,1G4,1-")
  music.parse(2, "1-,1G3,qC4,q-,1-")

  music.parse(3, "qC4,q-,qC4,q-,qBb3,q-,qBb3,q-")
  music.parse(3, "qA3,q-,qA3,q-,qAb3,q-,qAb3,q-")
  music.parse(3, "qG3,q-,qG3,q-,1G3,1-")
  music.parse(3, "1-,1G2,qC3,q-,1-")

  ' ---------- Line 5 ----------

  music.parse(1, "1G4,qA4,qG4,qG4,qE4,qF4,qF#4")
  music.parse(1, "1G4,qA4,qG4,qG4,qE5,qC5,qG4")
  music.parse(1, "qA4,qB4,qC5,qD5,qE5,qD5,qC5,qD5")
  music.parse(1, "2G4,qG4,qE4,qF4,qF#4")

  music.parse(2, "1E4,qF4,qE4,qE4,q-,1-")
  music.parse(2, "1E4,qF4,qE4,qE4,q-,1-")
  music.parse(2, "4-")
  music.parse(2, "4-")

  music.parse(3, "1C4,1-,1G3,1-")
  music.parse(3, "1C4,1-,1G3,1-")
  music.parse(3, "2F3,2G3")
  music.parse(3, "1C3,1G3,1C4,1-")

  ' ---------- Line 6 ----------

  music.parse(1, "1G4,qA4,qG4,qG4,qE4,qF4,qF#4")
  music.parse(1, "1G4,qA4,qG4,qG4,qG4,qA4,qA#4")
  music.parse(1, "1B4,q-,1B4,qA4,qF#4,qD4")
  music.parse(1, "2G4,qG4,qE4,qF4,qF#4")

  music.parse(2, "1E4,qF4,qE4,qE4,q-,1-")
  music.parse(2, "1E4,qF4,qE4,qE4,q-,1-")
  music.parse(2, "4-")
  music.parse(2, "4-")

  music.parse(3, "1C4,1-,1G3,1-")
  music.parse(3, "1C4,1-,1G3,1C#4")
  music.parse(3, "2D4,2D3")
  music.parse(3, "qG3,q-,qG3,q-,1A3,1B3")

  ' ---------- Line 7 ----------

  music.parse(1, "1G4,qA4,qG4,qG4,qE4,qF4,qF#4")
  music.parse(1, "1G4,qA4,qG4,qG4,qE5,qC5,qG4")
  music.parse(1, "qA4,qB4,qC5,qD5,qE5,qD5,qC5,qD5")
  music.parse(1, "2C5,qC5,qG4,qF#4,qG4")

  music.parse(2, "1E4,qF4,qE4,qE4,q-,1-")
  music.parse(2, "1E4,qF4,qE4,qE4,q-,1-")
  music.parse(2, "4-")
  music.parse(2, "4-")

  music.parse(3, "1C4,1-,1G3,1-")
  music.parse(3, "1C4,1-,1G3,1-")
  music.parse(3, "2F3,2G3")
  music.parse(3, "1C3,1G3,1C4,1-")

  ' ---------- Line 8 ----------

  music.parse(1, "1C5,qA4,qC5,qC5,qA4,qC5,qA4")
  music.parse(1, "qG4,qC5,qE5,qG5,qG5,qE5,qC5,qG4")
  music.parse(1, "1A4,1C5,qE5,1D5,qD5")
  music.parse(1, "3C5,1-")

  music.parse(2, "qF4,q-,qF4,q-,qF#4,q-,qF#4,q-")
  music.parse(2, "qG4,q-,qG4,q-,qE4,q-,qE4,q-")
  music.parse(2, "qF4,q-,qF4,q-,qG4,q-,qG4,q-")
  music.parse(2, "1C5,1G4,1C4,1-")

  music.parse(3, "qF3,q-,qF3,q-,qF#3,q-,qF#3,q-")
  music.parse(3, "qG3,q-,qG3,q-,qE3,q-,qE3,q-")
  music.parse(3, "qF3,q-,qF3,q-,qG3,q-,qG3,q-")
  music.parse(3, "1C4,1G3,1C3,1-")
End Sub

' The Black & White Rag - by Winifred Atwell - 3 channels.
Sub music.compose_black_white_rag()
  music.parse(1, "1E5,qD#5,1E5,qC#5,1D5")
  music.parse(1, "qA#4,1B4,qF4,qG4,qE4,1D4")
  music.parse(1, "qD5,q-,qD5,q-,qD5,q-,qD5,q-")
  music.parse(1, "1D5,qD5,q-,1D5,1C#5")

  music.parse(2, "1A4,qD#4,1E4,qC#3,1D4")
  music.parse(2, "qA#3,1B3,qF3,qG3,qE3,1D3")
  music.parse(2, "1D4,1D4,1D3,1D4")
  music.parse(2, "1D3,1D3,1-,1-")

  music.parse(3, "4-")
  music.parse(3, "4-")
  music.parse(3, "4-")
  music.parse(3, "4-")

  Local i%
  For i% = 1 To 2
  music.parse(1, "qC5,qD5,qF5,qC5,qD5,qF5,qC5,qD5")
  music.parse(2, "1D3,1C4,1A2,1C4")
  music.parse(3, "1A1,1D3,1E1,1D3")

  music.parse(1, "qF5,qC5,qD5,1F5,qE5,qD5,qC5")
  music.parse(1, "qA#4,qB4,qE5,qA#4,qB4,qE5,qA#4,qB4")
  music.parse(1, "qE5,qA#4,qB4,1E5,qD5,qB4,qG4")
  music.parse(1, "1C5,qB4,1C5,qB4,1C5")
  music.parse(1, "1A4,qG#4,1A4,qG#4,1A4")

  music.parse(2, "1D3,1D#3,1E3,1F3")
  music.parse(2, "1G3,1B3,1D3,1B3")
  music.parse(2, "1G3,1G#3,1A3,1B3")
  music.parse(2, "1A3,1C4,1D3,1C4")
  music.parse(2, "1A3,1C4,1D3,1C4")

  music.parse(3, "1D2,1D#2,1E2,1F2")
  music.parse(3, "1G2,1D3,1G2,1D3")
  music.parse(3, "1G2,1G#2,1A2,1B2")
  music.parse(3, "1A2,1D3,1D2,1D3")
  music.parse(3, "1A2,1D3,1D2,1D3")

  music.parse(1, "4-")
  music.parse(1, "q-,qG4,qB4,qD5,q-,qG5,qB5,qD6")
  music.parse(1, "qC5,qD5,qF5,qC5,qD5,qF5,qC5,qD5")
  music.parse(1, "qF5,qC5,qD5,1F5,qE5,qD5,qC5")
  music.parse(1, "qA#4,qB4,qE5,qA#4,qB4,qE5,qA#4,qB4")

  music.parse(2, "q-,qG2,qB2,qD3,q-,qG3,qB3,qD4")
  music.parse(2, "4-")
  music.parse(2, "1D3,1C4,1A2,1C4")
  music.parse(2, "1D3,1D#3,1E3,1F3")
  music.parse(2, "1G3,1B3,1D3,1B3")

  music.parse(3, "4-")
  music.parse(3, "4-")
  music.parse(3, "1D2,1D3,1A1,1D3")
  music.parse(3, "1D2,1D#2,1E2,1F2")
  music.parse(3, "1G2,1D3,1D2,1D3")

  music.parse(1, "qE5,qA#4,qB4,1E5,qD5,qC5,qB4")
  music.parse(1, "qE5,qE4,qG#4,1E5,qD5,qC5,qB4")
  music.parse(1, "qA4,qG#4,qA4,1E5,qD5,qC5,qA4")
  music.parse(1, "qB4,qD4,qG4,1B4,qG4,1A4")
  music.parse(1, "2G4,1G5,1-")

  music.parse(2, "1G3,1G#3,1A3,1B3")
  music.parse(2, "1G#3,1D4,1E3,1D4")
  music.parse(2, "1A3,1C4,1E3,1C4")
  music.parse(2, "1D3,1B3,1D3,1F3")
  music.parse(2, "2D4,1D5,1-")

  music.parse(3, "1G2,1G#2,1A2,1B2")
  music.parse(3, "1G#2,1E3,1E2,1E3")
  music.parse(3, "1A2,1E3,1E2,1E3")
  music.parse(3, "1D2,1D3,1D2,1F2")
  music.parse(3, "2B3,1B4,1-")
  Next
End Sub

Sub music.compose_mo_li_hua()
  music.parse(1, "1E4,qE4,q-,1E4,1G4,1A4,qC5,q-,qC5,q-,1A4,1G4,qG4,q-,1G4,1A4,4G4")
  music.parse(1, "1E4,qE4,q-,1E4,1G4,1A4,qC5,q-,qC5,q-,1A4,1G4,qG4,q-,1G4,1A4,3G4,qG4,q-")
  music.parse(1, "1G4,qG4,q-,1G4,qG4,q-,1G4,qG4,q-,1E4,1G4,1A4,qA4,q-,1A4,qA4,q-,4G4")
  music.parse(1, "2E4,1D4,1E4,2G4,1E4,1D4,1C4,qC4,q-,1C4,1D4,4C4")
  music.parse(1, "1E4,1D4,1C4,1E4,3D4,1E4,2G4,1A4,1C5,4G4")
  music.parse(1, "2D4,1E4,1G4,1D4,1E4,1C4,1A3,4G3,4-")
  music.parse(1, "2A3,2C4,3D4,1E4,1C4,1D4,1C4,1A3,4G3")

  music.parse(2, "1C3,1G3,1C4,1G3,1F3,1C4,1F4,1C4,1C3,1G3,1C4,1E4,1G3,1C4,1E4,1C4")
  music.parse(2, "1C3,1G3,1C4,1G3,1F3,1C4,1F4,1C4,1C3,1G3,1C4,1E4,1G3,1C4,1E4,1C4")
  music.parse(2, "1C3,1G3,1C4,1G3,1E3,1G3,1C4,1G3,1F3,1C4,1F4,1C4,1E3,1C4,1E4,1C4")
  music.parse(2, "1C3,1G3,1E3,1G3,1D3,1F3,1A3,1F3,1C3,1G3,1E3,1G3,1C3,1G3,1E3,1G3")
  music.parse(2, "1C3,1G3,1C4,1G3,1B3,1G3,1B3,1D4,1A2,1F3,1D3,1B3,1C3,1G3,1C4,1G3")
  music.parse(2, "1D3,1G3,1B3,1D4,1B3,1F3,1A3,1F3,1G3,1B3,1F3,1D3,1E3,1G3,1C4,1G3")
  music.parse(2, "1A2,1F3,1A3,1F3,1D3,1B3,1D4,1B3,1C4,2A3,1F3,4C3")
End Sub

Sub music.compose_autumn_festival()
  Local i%
  For i% = 1 To 2
    music.parse(1, "1C#5,1B4,2A4,1-,1E5,1D5,1C#5,2B4,2-,1A4,1G4,2F#4,1-,1E4,1F#4,1G4,2F#4,2A4,1C#5,1B4,2A4,1-,1E5,1D5,1C#5,2B4,2-,1C#5,1D5,2E5,2F#5,1D5,1C#5,2B4,2-")
    music.parse(2, "2-,2F#4,2-,2-,2G4,2-,3-,3-,3-,3-,2-,2F#4,2-,2-,2G4,2-,2-,2A4,2-,3-,3-")
    music.parse(3, "3F#3,3F#3,3G3,3G3,3A3,3A3,3B3,3B3,3F#3,3F#3,3G3,3G3,3A3,3A3,3B3,3B3")
  Next

  music.parse(1, "1C#5,1B4,1A4,1B4,1C#5,1A4,1E5,1D5,1C#5,1D5,2E5,1F#5,1E5,1D5,1F#5,1A5,1G5,1F#5,1E5,1D5,1E5,1C#5,qC#5,q-,1C#5,1B4,1A4,1B4,1C#5,1A4,1E5,1D5,1C#5,1D5,2E5,1F#5,1E5,1D5,1F#5,1A5,1G5,1F#5,1E5,1D5,1E5,1C#5,1D5")
  music.parse(2, "3-,3-,3-,3-,3-,3-,3-,3-,3-,3-,3-,3-,3-,3-,3-,3-")
  music.parse(3, "2F#3,1F#4,qF#4,q-,2F#4,2G3,1G4,qG4,q-,2G4,2A3,1A4,qA4,q-,2A4,2B3,4B4,2F#3,1F#4,qF#4,q-,2F#4,2G3,1G4,qG4,q-,2G4,2A3,1A4,qA4,q-,2A4,2B3,4B4")

  music.parse(1, "1E5,2-,3-,1E5,2-,3-,3-,3-,3-,3-,3-,3-,3-,3-,2-,1Ab3,qAb3,q-,2Ab3,2-,1Ab3,qAb3,q-,2Ab3,3D3,3D3,3D3,3D3")
  music.parse(2, "qC5,q-,1C5,1E5,1G5,1B5,1G5,qC5,q-,1C5,1E5,1G5,1B5,1G5,1E5,1C5")
  music.parse(2, "1E5,1G5,1B5,1G5,1E5,1C5,1E5,1G5,1B5,1G5,1D5,1C5,1D5,1G5,1D5")
  music.parse(2, "1C5,1D5,1C5,1D5,1G5,1D5,1C5,1D5,1C5,1D5,1G5,1D5,1C5,1D5,1C5")
  music.parse(2, "1D5,1G5,1D5,1C5,1D5,1C5,1D5,1G5,1D5,1C5,1D5,1C5,1D5,1G5,1D5")
  music.parse(2, "1C5,1-,1B2,1D3,1G3,1B3,1D4,1G4,1A4,1B4,1D5,1G5,1A5,2B5")
  music.parse(3, "2C4,2G4,2C5,2C4,2G4,2C5,2A3,2E4,2A4,2A3,2E4,2A4,2Bb3,1Bb4,qBb4,q-,2Bb4,2Bb3,1Bb4,qBb4,q-,2Bb4,2Ab2,1Eb3,qEb3,q-,2Eb3,2Ab2,1Eb3,qEb3,q-,2Eb3,3G2,3G2,3G2,3G2,3G2,3G2,3G2,3G2,3G2")
End Sub
