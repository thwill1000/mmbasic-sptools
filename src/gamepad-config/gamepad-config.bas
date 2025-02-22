' Copyright (c) 2025 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For PicoMiteUSB variants

Option Base 0
Option Default None
Option Explicit On

Const VERSION = 101300 ' 1.1.0
Const BUTTONS = "None D-Up D-Down D-Left D-Right A B X Y L1 R1 Select Start Turbo Clear"
Dim channel% = 0, filename$ = "", test% = 0

process_args()

Open filename$ For Output As #1

If test% Then write("** TEST DATA **", 1)
write("USB channel: " + Str$(channel%), 1)
write("Out file   : " + filename$, 0)
write("VID        : " + read_usb_vid$(), 1)
write("PID        : " + read_usb_pid$(), 1)
write("", 0)

Dim b$, i% = 1, k$
Do
  b$ = Field$(BUTTONS, i%, " ")
  If b$ = "" Then Exit Do
  Do While Inkey$ <> "" : Loop
  If b$ = "None" Then
    write("Hold down NO BUTTONS then press [SPACE]", 0)
  Else
    write("Hold down [" + b$ + "] then press [SPACE], or press [S] to skip", 0)
  EndIf
  Do
    k$ = UCase$(Inkey$)
    Select Case k$
      Case " " : Exit Do
      Case "S" : If b$ <> "None" Then Exit Do
    End Select
  Loop
  write(str.rpad$(b$, 11) + ": " + Choice(k$ = "S", "Skipped", read_usb_raw_data$()), 1)
  Inc i%
Loop

Close #1
End

Sub process_args()
  Local arg$, i% = 1
  Do
    arg$ = Field$(Mm.CmdLine$, i%, " ")
    If arg$ = "" Then
      Exit Do
    ElseIf InStr(arg$, "-f=") = 1 Then
      filename$ = Mid$(arg$, Len("-f=") + 1)
    ElseIf InStr(arg$, "--file=") = 1 Then
      filename$ = Mid$(arg$, Len("--file=") + 1)
    ElseIf InStr(arg$, "-c=") = 1 Then
      channel% = Val(Mid$(arg$, Len("-c=") + 1))
      If Not channel% Then Error "Invalid channel: " + arg$
    ElseIf InStr(arg$, "--channel=") = 1 Then
      channel% = Val(Mid$(arg$, Len("--channel=") + 1))
      If Not channel% Then Error "Invalid channel: " + arg$
    ElseIf arg$ = "-t" Or arg$ = "--test" Then
      test% = 1
    Else
      Error "Unknown command line argument: " + arg$
    EndIf
    Inc i%
  Loop

  If channel% = 0 Then
    Do
      Line Input "Channel (1-4) ? ", arg$
      channel% = Val(arg$)
      If channel% > 0 And channel% < 5 Then  Exit Do
    Loop
  EndIf

  If filename$ = "" Then
    Line Input "Filename 'usb-query.out' ? ", filename$
    If filename$ = "" Then filename$ = "usb-query.out"
  EndIf
End Sub

Function read_usb_vid$()
  Const vid% = Choice(test%, Int(Rnd() * &hFFFF), Mm.Info(Usb Vid channel%))
  read_usb_vid$ = "0x" + Hex$(vid%, 4)
End Function

Function read_usb_pid$()
  Const pid% = Choice(test%, Int(Rnd() * &hFFFF), Mm.Info(Usb Pid channel%))
  read_usb_pid$ = "0x" + Hex$(pid%, 4)
End Function

Function read_usb_raw_data$()
  Local raw$, i%
  If test% Then
    For i% = 1 To Int(Rnd() * 16)
      Cat raw$, Chr$(Int(Rnd() * 256))
    Next
  Else
    raw$ = Device(Gamepad channel%, Raw)
  EndIf
  read_usb_raw_data$ = "(" + str.rpad$(Str$(Len(raw$)), 2) + " bytes)"
  For i% = 1 To Len(raw$)
    Cat read_usb_raw_data$, " " + Hex$(Asc(Mid$(raw$, i%, 1)), 2)
  Next
End Function

Sub write(s$, to_file%)
  Print s$
  If to_file% Then Print #1, s$
End Sub

Function str.rpad$(s$, x%)
  str.rpad$ = s$
  If Len(s$) < x% Then str.rpad$ = s$ + Space$(x% - Len(s$))
End Function
