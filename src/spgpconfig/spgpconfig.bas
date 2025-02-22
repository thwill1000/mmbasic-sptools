' Copyright (c) 2025 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For PicoMiteUSB variants

Option Base 0
Option Default None
Option Explicit On

'!define NO_INCLUDE_GUARDS

#Include "../splib/system.inc"
#Include "../splib/ctrl.inc"
#Include "../splib/string.inc"
#Include "spgpconfig.inc"

Const VERSION = 101300 ' 1.1.0
Const BUTTONS = "None " + spgpc.UI_NAMES
Dim channel% = 0, filename$ = "", s$, test% = 0
Dim ui_data%(18, 7)

Print "USB Gamepad configuration tool for PicoMite{VGA}USB, v" + sys.format_version$(VERSION)

process_args()

Open filename$ For Output As #1

If test% Then
  If Mm.Device$ <> "MMB4L" Then Error "Test mode only suppored on MMB4L Currently"
  Const TEST_DATA = "gamepad_pihut" ' "gamepad_buffalo"
  s$ = "Testing using '" + TEST_DATA + "' data"
  println("", 1)
  println(String$(Len(s$), "*"), 1)
  println(s$, 1)
  println(String$(Len(s$), "*"), 1)
  println("", 1)
  Device Gamepad Open 1
Else
  Do While Inkey$ <> "" : Loop
  Print "Remove any attached gamepad and press [SPACE]"
  Do While Inkey$ <> " " : Loop
  Gamepad Monitor Silent
  Do While Inkey$ <> "" : Loop
  Print "Attach gamepad and press [SPACE]"
  Do While Inkey$ <> " " : Loop
EndIf

println("USB channel: " + Str$(channel%), 1)
println("Out file   : " + filename$, 0)
ui_data%(0, 0) = read_usb_vid%()
println("VID        : &h" + Hex$(ui_data%(0, 0), 4), 1)
ui_data%(1, 0) = read_usb_pid%()
println("PID        : &h" + Hex$(ui_data%(1, 0), 4), 1)
println("", 0)

Dim b$, i% = 1, j%, k$, raw$
Do
  b$ = Field$(BUTTONS, i%, " ")
  If b$ = "" Then Exit Do
  Do While Inkey$ <> "" : Loop
  If b$ = "None" Then
    println("Hold down NO BUTTONS then press [SPACE]", 0)
  Else
    println("Hold down [" + b$ + "] then press [SPACE], or press [S] to skip", 0)
  EndIf
  Do
    k$ = UCase$(Inkey$)
    Select Case k$
      Case " "
        raw$ = read_usb_raw$()
        If raw$ = "" Then
          println("    Invalid ... try again", 0)
        Else
          Exit Do
        EndIf
      Case "S"
        If b$ = "None" Then Continue Do
        raw$ = ""
        Exit Do
    End Select
  Loop

  If raw$ = "" Then
    For j% = 1 To 8
      ui_data%(i% + 1, j% - 1) = -1
    Next
  Else
    For j% = 1 To Len(raw$)
      ui_data%(i% + 1, j% - 1) = Asc(Mid$(raw$, j%, 1))
    Next
  EndIf

  Print "    ";
  println(str.rpad$(b$, 11) + ": " + Choice(k$ = "S", "Skipped", raw_to_string$(raw$)), 1)
  Inc i%
Loop

Dim c_data%(17, 1)
If spgpc.ui_to_c_data%(ui_data%(), c_data%()) <> sys.SUCCESS Then
  Error sys.err$
EndIf

println("", 1)
spgpc.write_bas_file(c_data%(), 0)
spgpc.write_bas_file(c_data%(), 1)

println("", 1)
spgpc.write_c_struct(c_data%(), 0)
spgpc.write_c_struct(c_data%(), 1)

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

  If filename$ = "" Then
    Line Input "Filename ? (spgamepad-config.out) ", filename$
    filename$ = Choice(filename$ = "", "spgamepad-config.out", filename$)
  EndIf

  If channel% = 0 Then
    Do
      Line Input "Channel 1-4 ? (3) ", arg$
      channel% = Choice(arg$ = "", 3, Val(arg$))
      If channel% > 0 And channel% < 5 Then  Exit Do
    Loop
  EndIf
End Sub

Function read_usb_vid%()
  If test% Then
    Local s$
    Restore TEST_DATA
    Read s$, read_usb_vid%
  Else
    read_usb_vid% = Mm.Info(Usb Vid channel%)
  EndIf
End Function

Function read_usb_pid%()
  If test% Then
    Local s$
    Restore TEST_DATA
    Read s$, read_usb_pid% ' Skip VID entry
    Read s$, read_usb_pid%
  Else
    read_usb_pid% = Mm.Info(Usb Pid channel%)
  EndIf
End Function

Function read_usb_raw$()
  If Not test% Then
    read_usb_raw$ = Device(Gamepad channel%, Raw)
    Exit Function
  EndIf

  Restore TEST_DATA
  Local i%, j%, s$, x%, index%, num_bytes%
  Do
    x% = Device(Gamepad 1, B)
    Select Case x%
      Case 0:           index% = 0
      Case ctrl.R:      index% = 10
      Case ctrl.START:  index% = 14
      Case ctrl.HOME:   index% = 15
      Case ctrl.SELECT: index% = 13
      Case ctrl.L:      index% = 9
      Case ctrl.DOWN:   index% = 2
      Case ctrl.RIGHT:  index% = 4
      Case ctrl.UP:     index% = 1
      Case ctrl.LEFT:   index% = 3
      Case ctrl.ZR:     index% = 12
      Case ctrl.X:      index% = 7
      Case ctrl.A:      index% = 5
      Case ctrl.Y:      index% = 8
      Case ctrl.B:      index% = 6
      Case ctrl.ZL:     index% = 11
      ' TODO: ctrl.TOUCH currently unsupported
      Case Else
        Exit Function ' Invalid button press
    End Select
    Read s$, x% ' Skip VID
    Read s$, x% ' Skip PID
    For i% = 0 To index%
      read_usb_raw$ = ""
      Read s$, num_bytes%
      For j% = 1 To num_bytes%
        Read x%
        If x% = -1 Then x% = &hFF
        Cat read_usb_raw$, Chr$(x%)
      Next
    Next
    Exit Do
  Loop
End Function

Function raw_to_string$(raw$)
  Local i%
  raw_to_string$ = "(" + Str$(Len(raw$)) + " bytes)"
  For i% = 1 To Len(raw$)
    Cat raw_to_string$, " " + Hex$(Asc(Mid$(raw$, i%, 1)), 2)
  Next
End Function

Sub println(s$, to_file%)
  Print s$
  If to_file% Then Print #1, s$
End Sub

gamepad_buffalo:
Data "VID",     &h0583
Data "PID" ,    &h2060
Data "None",    8, &h81, &h7F, &h00, &h00, &h00, &h00, &h00, &h00
Data "D-Up",    8, &h81, &h00, &h00, &h00, &h00, &h00, &h00, &h00
Data "D-Down",  8, &h80, &hFF, &h00, &h00, &h00, &h00, &h00, &h00
Data "D-Left",  8, &h00, &h80, &h00, &h00, &h00, &h00, &h00, &h00
Data "D-Right", 8, &hFF, &h80, &h00, &h00, &h00, &h00, &h00, &h00
Data "A",       8, &h81, &h80, &h01, &h00, &h00, &h00, &h00, &h00
Data "B",       8, &h81, &h80, &h02, &h00, &h00, &h00, &h00, &h00
Data "X",       8, &h81, &h7F, &h04, &h00, &h00, &h00, &h00, &h00
Data "Y",       8, &h81, &h80, &h08, &h00, &h00, &h00, &h00, &h00
Data "L1",      8, &h80, &h80, &h10, &h00, &h00, &h00, &h00, &h00
Data "R1",      8, &h81, &h7F, &h20, &h00, &h00, &h00, &h00, &h00
Data "L2",      8, &h81, &h80, &h00, &h10, &h00, &h00, &h00, &h00
Data "R2",      8, &h81, &h80, &h00, &h20, &h00, &h00, &h00, &h00
Data "Select",  8, &h80, &h80, &h40, &h00, &h00, &h00, &h00, &h00
Data "Start",   8, &h81, &h80, &h80, &h00, &h00, &h00, &h00, &h00
Data "Home",    8, -1, -1, -1, -1, -1, -1, -1, -1
Data "Touch",   8, -1, -1, -1, -1, -1, -1, -1, -1
Data ""

gamepad_pihut:
Data "VID",     &h0079
Data "PID",     &h0011
Data "None",    8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h00, &h00
Data "D-Up",    8, &h01, &h7F, &h7F, &h7F, &h00, &h0F, &h00, &h00
Data "D-Down",  8, &h01, &h7F, &h7F, &h7F, &hFF, &h0F, &h00, &h00
Data "D-Left",  8, &h01, &h7F, &h7F, &h00, &h7F, &h0F, &h00, &h00
Data "D-Right", 8, &h01, &h7F, &h7F, &hFF, &h7F, &h0F, &h00, &h00
Data "A",       8, &h01, &h7F, &h7F, &h7F, &h7F, &h2F, &h00, &h00
Data "B",       8, &h01, &h7F, &h7F, &h7F, &h7F, &h4F, &h00, &h00
Data "X",       8, &h01, &h7F, &h7F, &h7F, &h7F, &h1F, &h00, &h00
Data "Y",       8, &h01, &h7F, &h7F, &h7F, &h7F, &h8F, &h00, &h00
Data "L1",      8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h01, &h00
Data "R1",      8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h02, &h00
Data "L2",      8, -1, -1, -1, -1, -1, -1, -1, -1
Data "R2",      8, -1, -1, -1, -1, -1, -1, -1, -1
Data "Select",  8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h10, &h00
Data "Start",   8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h20, &h00
Data "Home",    8, -1, -1, -1, -1, -1, -1, -1, -1
Data "Touch",   8, -1, -1, -1, -1, -1, -1, -1, -1
Data ""
