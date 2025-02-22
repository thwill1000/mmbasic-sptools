' Copyright (c) 2025 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For PicoMiteUSB variants

Option Base 0
Option Explicit On
Option Default Integer

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
'#Include "../../common/sptools.inc"
'#Include "../input.inc"

add_test("test_num_changed_bits")
add_test("test_compute_mapping_analog")
add_test("test_compute_mapping_binary")
add_test("test_buffalo")
add_test("test_pihut")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Function num_changed_bits%(before%, after%)
  If before% < 0 Or before% > 255 Then Error "Invalid 'before' byte parameter: " + Str$(before%)
  If after% < 0 Or after% > 255 Then Error "Invalid 'after' byte parameter: " + Str$(after%)

  If before% >= &h7F And before% <= &h81 And after% >= &h7F And after% <= &h81 Then Exit Function

  Local i%, mask%
  For i% = 0 To 7
    mask% = 1 << i%
    Inc num_changed_bits%, (before% And mask%) <> (after% And mask%)
  Next
End Function

Function compute_mapping_analog%(up%, down%)
  If num_changed_bits%(up%, down%) = 0 Then
    compute_mapping_analog = &hFF
    Exit Function
  EndIf

  If down% < &h40 Then compute_mapping_analog% = &h40
  If down% > &hC0 Then compute_mapping_analog% = &hC0
End Function

Function compute_mapping_binary%(up%, down%)
  Select Case num_changed_bits%(up%, down%)
    Case 0
      compute_mapping_analog = &hFF
      Exit Function
    Case 1
      ' Expected, do nothing.
    Case Else
      Error "Too many bits changes for binary mapping: " + Bin$(up%, 8) + " => " + Bin$(down%, 8)
  End Select

  Local i%, mask%
  For i% = 0 To 7
    mask% = 1 << i%
    If (up% And mask%) <> (down% And mask%) Then
      compute_mapping_binary% = Choice(down% And mask%, i%, 128 + i%)
      Exit Function
    EndIf
  Next
End Function

Sub translate_record(button$, up%(), down%(), index%, value%)
  Local found%, i%
  For i% = 0 To 7
    Select Case num_changed_bits%(up%(i%), down%(i%))
      Case 0:
        Continue For
      Case 1:
        index% = i%
        If up%(i%) >= &h7F And up(i%) <= &h81 Then
          value% = compute_mapping_analog%(up%(i%), down%(i%))
        Else
          value% = compute_mapping_binary%(up%(i%), down%(i%))
        EndIf
        Inc found%
      Case Else
        index% = i%
        value% = compute_mapping_analog%(up%(i%), down%(i%))
        Inc found%
    End Select
  Next
  If found% = 1 Then Exit Sub

  Print
  Print "Translation for [" + button$ + "] failed:"
  Print "  Up:  ";
  For i% = 0 To 7
    Print " " + Hex$(up%(i%), 2);
  Next
  Print
  Print "  Down:";
  For i% = 0 To 7
    Print " " + Hex$(down%(i%), 2);
  Next
  Print
End Sub

Function format_chex$(value%, digits%)
  format_chex$ = "0x" + Hex$(value%, Choice(digits%, digits%, 2))
End Function

Function format_cmember$(name$, value%, digits%)
  format_cmember$ = "." + name$ + "=" + format_chex$(value%, digits%)
End Function

Function format_cmember_pair$(name$, value1%, value2%, digits%)
  format_cmember_pair$ = "." + name$ + "={" + format_chex$(value1%, digits%)
  Cat format_cmember_pair$, "," + format_chex$(value2%, digits%) + "}"
End Function

' ui_data%() should be 19 x 8 element 2D array.
'   (0)   VID     - value in (0, 0), elements (0, 1..7) ignored
'   (1)   PID     - value in (1, 0), elements (0, 1..7) ignored
'   (2)   None    - 8 byte values corresponding to the USB record when this button is down
'   (3)   D-Up    - ...
'   (4)   D-Down
'   (5)   D-Left
'   (6)   D-Right
'   (7)   A
'   (8)   B
'   (9)   X
'   (10)  Y
'   (11)  L1
'   (12)  L2
'   (13)  R1
'   (14)  R2
'   (15)  Select
'   (16)  Start
'   (17)  Home
'   (18)  Touch
' c_data%() should be (18 x 2) element 2D array.
'   (0)   VID     - value in (0, 0), element (0, 1) ignored
'   (1)   PID     - value in (1, 0), element (1, 1) ignored
'   (2)   R1      - index in (#, 0), code in (#, 1)
'   (3)   Start   - ...
'   (4)   Home
'   (5)   Select
'   (6)   L1
'   (7)   D-Down
'   (8)   D-Right
'   (9)   D-Up
'   (10)  D-Left
'   (12)  R2
'   (13)  X
'   (14)  A
'   (15)  Y
'   (16)  B
'   (17)  L2
'   (18)  Touch

Const UI_NAMES = "D-Up D-Down D-Left D-Right A B X Y L1 L2 R1 R2 Select Start Home Touch"
Const C_NAMES = "R START HOME SELECT L DOWN RIGHT UP LEFT R2 X A Y B L2 TOUCH"
Dim UI_2_C(15) As Integer = (7, 5, 8, 6, 11, 13, 10, 12, 4, 14, 0, 9, 3, 1, 2, 15)

' Generates 'c_data' data from 'ui_data' data.
Sub usb_to_c_data(ui_data%(), c_data%())
  c_data%(0, 0) = ui_data%(0, 0)
  c_data%(1, 0) = ui_data%(1, 0)
  Local i% = 1
End Sub

' Print C-struct for gamepad suitable for inclusion in PicoMite source code.
Sub print_c_data(c_data%(), fnbr%)
  Local i% = 0, name$
  Print #fnbr%, "{"
  Print #fnbr%, "  ";
  Print #fnbr%, format_cmember$("vid", c_data%(0, 0), 4);
  Print #fnbr%, ", ";
  Print #fnbr%, format_cmember$("pid", c_data%(1, 0), 4);
  Print #fnbr%, ",";
  i% = 1
  Do
    name$ = Field$(C_NAMES, i%, " ")
    If name$ = "" Then Exit Do
    If i% Mod 4 Then
      Print #fnbr%, ", ";
    Else
      Print #fnbr%
      Print #fnbr%, "  ";
    EndIf
    Print #fnbr%, format_cmember_pair$("b_" + name$, c_data%(i% + 1, 0), c_data%(i% + 1, 1), 2);
    Inc i%
  Loop
  Print #fnbr%
  Print #fnbr%, "}"
End Sub

Sub test_num_changed_bits()
  assert_int_equals(0, num_changed_bits%(&b00000000, &b00000000))
  assert_int_equals(1, num_changed_bits%(&b00000000, &b00000001))
  assert_int_equals(2, num_changed_bits%(&b00000000, &b00000101))
  assert_int_equals(3, num_changed_bits%(&b00000000, &b00010101))
  assert_int_equals(4, num_changed_bits%(&b00000000, &b00010111))
  assert_int_equals(5, num_changed_bits%(&b11111111, &b10001001))
  assert_int_equals(6, num_changed_bits%(&b11111111, &b00001001))
  assert_int_equals(7, num_changed_bits%(&b11111111, &b00001000))
  assert_int_equals(8, num_changed_bits%(&b11111111, &b00000000))

  assert_no_error()
End Sub

Sub test_compute_mapping_analog()
  assert_int_equals(&hFF, compute_mapping_analog%(&h81, &h81))
  assert_int_equals(&h40, compute_mapping_analog%(&h81, &h00))
  assert_int_equals(&hC0, compute_mapping_analog%(&h81, &hFF))

  assert_int_equals(&hFF, compute_mapping_analog%(&h7F, &h7F))
  assert_int_equals(&h40, compute_mapping_analog%(&h7F, &h00))
  assert_int_equals(&hC0, compute_mapping_analog%(&h7F, &hFF))

  assert_no_error()
End Sub

Sub test_compute_mapping_binary()
  ' Single bits being set.
  assert_int_equals(0, compute_mapping_binary%(&h00, &b00000001))
  assert_int_equals(1, compute_mapping_binary%(&h00, &b00000010))
  assert_int_equals(2, compute_mapping_binary%(&h00, &b00000100))
  assert_int_equals(3, compute_mapping_binary%(&h00, &b00001000))
  assert_int_equals(4, compute_mapping_binary%(&h00, &b00010000))
  assert_int_equals(5, compute_mapping_binary%(&h00, &b00100000))
  assert_int_equals(6, compute_mapping_binary%(&h00, &b01000000))
  assert_int_equals(7, compute_mapping_binary%(&h00, &b10000000))
  assert_int_equals(4, compute_mapping_binary%(&h0F, &b00011111))
  assert_int_equals(5, compute_mapping_binary%(&h0F, &b00101111))
  assert_int_equals(6, compute_mapping_binary%(&h0F, &b01001111))
  assert_int_equals(7, compute_mapping_binary%(&h0F, &b10001111))

  ' Single bits being cleared.
  assert_int_equals(128, compute_mapping_binary%(&hFF, &b11111110))
  assert_int_equals(129, compute_mapping_binary%(&hFF, &b11111101))
  assert_int_equals(130, compute_mapping_binary%(&hFF, &b11111011))
  assert_int_equals(131, compute_mapping_binary%(&hFF, &b11110111))
  assert_int_equals(132, compute_mapping_binary%(&hFF, &b11101111))
  assert_int_equals(133, compute_mapping_binary%(&hFF, &b11011111))
  assert_int_equals(134, compute_mapping_binary%(&hFF, &b10111111))
  assert_int_equals(135, compute_mapping_binary%(&hFF, &b01111111))

  assert_no_error()
End Sub

Sub test_buffalo()
  test_gamepad("gamepad_buffalo")
End Sub

Sub test_gamepad(label$)
  Local c_data%(17, 1)

  Local count%, down%(7), expected_index%, expected_value%, name$, s$, pid%, up%(7), vid%
  Local index%, value%
  Restore label$
  Read name$, vid%
  Read name$, pid%
  Read name$, count%, up%(0), up%(1), up%(2), up%(3), up%(4), up%(5), up%(6), up%(7)
  If count% <> 8 Then Error "Invalid DATA: count <> 8"
  Do
    Read name$
    If name$ = "" Then Exit Do
    Read count%
    If count% = 0 Then Continue Do
    If count% <> 8 Then Error "Invalid DATA: count <> 8"
    Read down%(0), down%(1), down%(2), down%(3), down%(4), down%(5), down%(6), down%(7)

    Read expected_index%, expected_value%

    index% = 0
    value% = 0
    translate_record(name$, up%(), down%(), index%, value%)
    assert_int_equals(expected_index%, index%)
    assert_int_equals(expected_value%, value%)
  Loop

  Print
  print_c_data(c_data%())
End Sub

Sub test_pihut()
  test_gamepad("gamepad_pihut")
End Sub

gamepad_buffalo:
Data "VID",     &h0583
Data "PID" ,    &h2060
Data "None",    8, &h81, &h7F, &h00, &h00, &h00, &h00, &h00, &h00
Data "D-Up",    8, &h81, &h00, &h00, &h00, &h00, &h00, &h00, &h00, 1, 64 
Data "D-Down",  8, &h80, &hFF, &h00, &h00, &h00, &h00, &h00, &h00, 1, 192
Data "D-Left",  8, &h00, &h80, &h00, &h00, &h00, &h00, &h00, &h00, 0, 64
Data "D-Right", 8, &hFF, &h80, &h00, &h00, &h00, &h00, &h00, &h00, 0, 192
Data "A",       8, &h81, &h80, &h01, &h00, &h00, &h00, &h00, &h00, 2, 0
Data "B",       8, &h81, &h80, &h02, &h00, &h00, &h00, &h00, &h00, 2, 1
Data "X",       8, &h81, &h7F, &h04, &h00, &h00, &h00, &h00, &h00, 2, 2
Data "Y",       8, &h81, &h80, &h08, &h00, &h00, &h00, &h00, &h00, 2, 3
Data "L1",      8, &h80, &h80, &h10, &h00, &h00, &h00, &h00, &h00, 2, 4
Data "L2",      8, &h81, &h80, &h00, &h10, &h00, &h00, &h00, &h00, 3, 4 ' Turbo/Auto
Data "R1",      8, &h81, &h7F, &h20, &h00, &h00, &h00, &h00, &h00, 2, 5
Data "R2",      8, &h81, &h80, &h00, &h20, &h00, &h00, &h00, &h00, 3, 5 ' Clear
Data "Select",  8, &h80, &h80, &h40, &h00, &h00, &h00, &h00, &h00, 2, 6
Data "Start",   8, &h81, &h80, &h80, &h00, &h00, &h00, &h00, &h00, 2, 7
Data "Home",    0
Data "Touch",   0
Data ""

gamepad_pihut:
Data "VID",     &h0079
Data "PID",     &h0011
Data "None",    8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h00, &h00
Data "D-Up",    8, &h01, &h7F, &h7F, &h7F, &h00, &h0F, &h00, &h00, 4, 64
Data "D-Down",  8, &h01, &h7F, &h7F, &h7F, &hFF, &h0F, &h00, &h00, 4, 192
Data "D-Left",  8, &h01, &h7F, &h7F, &h00, &h7F, &h0F, &h00, &h00, 3, 64
Data "D-Right", 8, &h01, &h7F, &h7F, &hFF, &h7F, &h0F, &h00, &h00, 3, 192
Data "A",       8, &h01, &h7F, &h7F, &h7F, &h7F, &h2F, &h00, &h00, 5, 5
Data "B",       8, &h01, &h7F, &h7F, &h7F, &h7F, &h4F, &h00, &h00, 5, 6
Data "X",       8, &h01, &h7F, &h7F, &h7F, &h7F, &h1F, &h00, &h00, 5, 4
Data "Y",       8, &h01, &h7F, &h7F, &h7F, &h7F, &h8F, &h00, &h00, 5, 7
Data "L1",      8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h01, &h00, 6, 0
Data "L2",      0
Data "R1",      8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h02, &h00, 6, 1
Data "R2",      0
Data "Select",  8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h10, &h00, 6, 4
Data "Start",   8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h20, &h00, 6, 5
Data "Home",    0
Data "Touch",   0
Data ""
