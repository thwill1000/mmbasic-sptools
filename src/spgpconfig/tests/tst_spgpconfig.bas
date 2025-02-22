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
#Include "../spgpconfig.inc"

add_test("test_num_changed_bits")
add_test("test_compute_mapping_analog")
add_test("test_compute_mapping_binary")
add_test("test_ui_to_c_data_gvn_buffalo")
add_test("test_ui_to_c_data_gvn_pihut")
add_test("test_write_c_struct_gvn_buffalo")
add_test("test_write_c_struct_gvn_pihut")
add_test("test_write_bas_file_gvn_buffalo")
add_test("test_write_bas_file_gvn_pihut")
add_test("test_translate_failure")

run_tests()

End

Sub setup_test()
  MkDir TMPDIR$
End Sub

Sub teardown_test()
End Sub

Sub test_num_changed_bits()
  assert_int_equals(0, spgpc.num_changed_bits%(&b00000000, &b00000000))
  assert_int_equals(1, spgpc.num_changed_bits%(&b00000000, &b00000001))
  assert_int_equals(2, spgpc.num_changed_bits%(&b00000000, &b00000101))
  assert_int_equals(3, spgpc.num_changed_bits%(&b00000000, &b00010101))
  assert_int_equals(4, spgpc.num_changed_bits%(&b00000000, &b00010111))
  assert_int_equals(5, spgpc.num_changed_bits%(&b11111111, &b10001001))
  assert_int_equals(6, spgpc.num_changed_bits%(&b11111111, &b00001001))
  assert_int_equals(7, spgpc.num_changed_bits%(&b11111111, &b00001000))
  assert_int_equals(8, spgpc.num_changed_bits%(&b11111111, &b00000000))

  assert_int_equals(sys.FAILURE, spgpc.num_changed_bits%(256, 0))
  assert_string_equals("Invalid 'b1' byte parameter: 256", sys.err$)
  assert_int_equals(sys.FAILURE, spgpc.num_changed_bits%(0, 256))
  assert_string_equals("Invalid 'b2' byte parameter: 256", sys.err$)
End Sub

Sub test_compute_mapping_analog()
  assert_int_equals(&h40, spgpc.compute_mapping_analog%(&h81, &h00))
  assert_int_equals(&hC0, spgpc.compute_mapping_analog%(&h81, &hFF))

  assert_int_equals(&h40, spgpc.compute_mapping_analog%(&h7F, &h00))
  assert_int_equals(&hC0, spgpc.compute_mapping_analog%(&h7F, &hFF))

  assert_int_equals(sys.FAILURE, spgpc.compute_mapping_analog%(&h81, &h81))
  assert_string_equals("Analog mapping could not be computed: &h81 => &h81", sys.err$)

  assert_int_equals(sys.FAILURE, spgpc.compute_mapping_analog%(&h7F, &h7F))
  assert_string_equals("Analog mapping could not be computed: &h7F => &h7F", sys.err$)

  assert_int_equals(sys.FAILURE, spgpc.compute_mapping_analog%(&h80, &h90))
  assert_string_equals("Analog mapping could not be computed: &h80 => &h90", sys.err$)
End Sub

Sub test_compute_mapping_binary()
  ' Single bits being set.
  assert_int_equals(0, spgpc.compute_mapping_binary%(&h00, &b00000001))
  assert_int_equals(1, spgpc.compute_mapping_binary%(&h00, &b00000010))
  assert_int_equals(2, spgpc.compute_mapping_binary%(&h00, &b00000100))
  assert_int_equals(3, spgpc.compute_mapping_binary%(&h00, &b00001000))
  assert_int_equals(4, spgpc.compute_mapping_binary%(&h00, &b00010000))
  assert_int_equals(5, spgpc.compute_mapping_binary%(&h00, &b00100000))
  assert_int_equals(6, spgpc.compute_mapping_binary%(&h00, &b01000000))
  assert_int_equals(7, spgpc.compute_mapping_binary%(&h00, &b10000000))
  assert_int_equals(4, spgpc.compute_mapping_binary%(&h0F, &b00011111))
  assert_int_equals(5, spgpc.compute_mapping_binary%(&h0F, &b00101111))
  assert_int_equals(6, spgpc.compute_mapping_binary%(&h0F, &b01001111))
  assert_int_equals(7, spgpc.compute_mapping_binary%(&h0F, &b10001111))

  ' Single bits being cleared.
  assert_int_equals(128, spgpc.compute_mapping_binary%(&hFF, &b11111110))
  assert_int_equals(129, spgpc.compute_mapping_binary%(&hFF, &b11111101))
  assert_int_equals(130, spgpc.compute_mapping_binary%(&hFF, &b11111011))
  assert_int_equals(131, spgpc.compute_mapping_binary%(&hFF, &b11110111))
  assert_int_equals(132, spgpc.compute_mapping_binary%(&hFF, &b11101111))
  assert_int_equals(133, spgpc.compute_mapping_binary%(&hFF, &b11011111))
  assert_int_equals(134, spgpc.compute_mapping_binary%(&hFF, &b10111111))
  assert_int_equals(135, spgpc.compute_mapping_binary%(&hFF, &b01111111))

  ' No bits changing.
  assert_int_equals(sys.FAILURE, spgpc.compute_mapping_binary%(&h0F, &h0F))
  assert_string_equals("Binary mapping could not be computed: &h0F => &h0F", sys.err$)

  ' Multiple bits changing.
  assert_int_equals(sys.FAILURE, spgpc.compute_mapping_binary%(&h00, &hFF))
  assert_string_equals("Binary mapping could not be computed: &h00 => &hFF", sys.err$)
End Sub

Sub test_ui_to_c_data_gvn_buffalo()
  test_ui_to_c_data("gamepad_buffalo")
End Sub

Sub test_ui_to_c_data(label$)
  Local i%, actual_c_data%(17, 1), expected_c_data%(17, 1), ui_data(18, 7)
  read_test_data(label$, ui_data%(), expected_c_data%())

  assert_int_equals(sys.SUCCESS, spgpc.ui_to_c_data%(ui_data%(), actual_c_data%()))

  For i% = 0 To Bound(expected_c_data%(), 1)
    assert_hex_equals(expected_c_data%(i%, 0), actual_c_data%(i%, 0))
    assert_hex_equals(expected_c_data%(i%, 1), actual_c_data%(i%, 1))
  Next
End Sub

Sub test_ui_to_c_data_gvn_pihut()
  test_ui_to_c_data("gamepad_pihut")
End Sub

Sub read_test_data(label$, ui_data%(), c_data%())
  Local count%, i%, j%, name$

  Restore label$

  Read name$, ui_data%(0, 0) ' vid
  c_data%(0, 0) = ui_data%(0, 0)
  Read name$, ui_data%(1, 0) ' pid
  c_data%(1, 0) = ui_data%(1, 0)
  i% = 2
  Do
    Read name$
    If name$ = "" Then Exit Do
    Read count%
    If count% <> 8 Then Error "Invalid DATA, expected count <> 8: " + Str$(count%)
    For j% = 0 To count% - 1
      Read ui_data%(i%, j%)
    Next
    If i% <> 2 Then
      Read c_data%(spgpc.UI_2_C(i%), 0), c_data%(spgpc.UI_2_C(i%), 1)
    EndIf
    Inc i%
  Loop
End Sub

Sub test_write_c_struct_gvn_buffalo()
  Local expected$(6)
  expected$(0) = "{"
  expected$(1) = "  .vid=0x0583, .pid=0x2060, .b_R={0x02,0x05}, .b_START={0x02,0x07}, .b_HOME={0xFF,0x00}"
  expected$(2) = "  .b_SELECT={0x02,0x06}, .b_L={0x02,0x04}, .b_DOWN={0x01,0xC0}, .b_RIGHT={0x00,0xC0}"
  expected$(3) = "  .b_UP={0x01,0x40}, .b_LEFT={0x00,0x40}, .b_R2={0x03,0x05}, .b_X={0x02,0x02}"
  expected$(4) = "  .b_A={0x02,0x00}, .b_Y={0x02,0x03}, .b_B={0x02,0x01}, .b_L2={0x03,0x04}"
  expected$(5) = "  .b_TOUCH={0xFF,0x00}"
  expected$(6) = "}"

  test_write_c_struct("gamepad_buffalo", expected$())
End Sub

Sub test_write_c_struct(label$, expected$())
  Local c_data%(17, 1), ui_data(18, 7)
  read_test_data(label$, ui_data%(), c_data%())
  Const filename$ = TMPDIR$ + file.SEPARATOR + "test_write_c_struct_gvn_" + label$ + ".c"

  Open filename$ For Output As #1
  spgpc.write_c_struct(c_data%(), 1)
  Close #1

  Open filename$ For Input As #1
  Local i%, s$
  For i% = 0 To Bound(expected$(), 1)
    Line Input #1, s$
    assert_string_equals(expected$(i%), s$)
  Next
  assert_true(Eof(#1))
  Close #1
End Sub

Sub test_write_c_struct_gvn_pihut()
  Local expected$(6)
  expected$(0) = "{"
  expected$(1) = "  .vid=0x0079, .pid=0x0011, .b_R={0x06,0x01}, .b_START={0x06,0x05}, .b_HOME={0xFF,0x00}"
  expected$(2) = "  .b_SELECT={0x06,0x04}, .b_L={0x06,0x00}, .b_DOWN={0x04,0xC0}, .b_RIGHT={0x03,0xC0}"
  expected$(3) = "  .b_UP={0x04,0x40}, .b_LEFT={0x03,0x40}, .b_R2={0xFF,0x00}, .b_X={0x05,0x04}"
  expected$(4) = "  .b_A={0x05,0x05}, .b_Y={0x05,0x07}, .b_B={0x05,0x06}, .b_L2={0xFF,0x00}"
  expected$(5) = "  .b_TOUCH={0xFF,0x00}"
  expected$(6) = "}"

  test_write_c_struct("gamepad_pihut", expected$())
End Sub

Sub test_write_bas_file_gvn_buffalo()
  Const expected$ = "Gamepad Configure &h0583,&h2060,2,5,2,7,255,0,2,6,2,4,1,192,0,192,1,64,0,64,3,5,2,2,2,0,2,3,2,1,3,4,255,0"

  test_write_bas_file("gamepad_buffalo", expected$)
End Sub

Sub test_write_bas_file(label$, expected$)
  Local c_data%(17, 1), ui_data(18, 7)
  read_test_data(label$, ui_data%(), c_data%())
  Const filename$ = TMPDIR$ + file.SEPARATOR + "test_write_bas_file_gvn_" + label$ + ".bas"

  Open filename$ For Output As #1
  spgpc.write_bas_file(c_data%(), 1)
  Close #1

  Open filename$ For Input As #1
  Local s$
  Line Input #1, s$
  assert_string_equals(expected$, s$)
  assert_true(Eof(#1))
  Close #1
End Sub

Sub test_write_bas_file_gvn_pihut()
  Const expected$ = "Gamepad Configure &h0079,&h0011,6,1,6,5,255,0,6,4,6,0,4,192,3,192,4,64,3,64,255,0,5,4,5,5,5,7,5,6,255,0,255,0"

  test_write_bas_file("gamepad_pihut", expected$)
End Sub

Sub test_translate_failure()
  Dim index%, value%
  Dim up%(7) = ( &h00, &h00, &h00, &h00, &h00, &h00, &h00, &h00 )
  Dim down%(7) = ( &h00, &h00, &h00, &h00, &h00, &h00, &h00, &h00 )

  assert_int_equals(sys.FAILURE, spgpc.translate_record%(up%(), down%(), index%, value%))
  assert_string_equals("No translation found: Up {00 00 00 00 00 00 00 00, Down {00 00 00 00 00 00 00 00}", sys.err$)
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
Data "R1",      8, &h81, &h7F, &h20, &h00, &h00, &h00, &h00, &h00, 2, 5
Data "L2",      8, &h81, &h80, &h00, &h10, &h00, &h00, &h00, &h00, 3, 4 ' Turbo/Auto
Data "R2",      8, &h81, &h80, &h00, &h20, &h00, &h00, &h00, &h00, 3, 5 ' Clear
Data "Select",  8, &h80, &h80, &h40, &h00, &h00, &h00, &h00, &h00, 2, 6
Data "Start",   8, &h81, &h80, &h80, &h00, &h00, &h00, &h00, &h00, 2, 7
Data "Home",    8, -1, -1, -1, -1, -1, -1, -1, -1, 255, 0
Data "Touch",   8, -1, -1, -1, -1, -1, -1, -1, -1, 255, 0
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
Data "R1",      8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h02, &h00, 6, 1
Data "L2",      8, -1, -1, -1, -1, -1, -1, -1, -1, 255, 0
Data "R2",      8, -1, -1, -1, -1, -1, -1, -1, -1, 255, 0
Data "Select",  8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h10, &h00, 6, 4
Data "Start",   8, &h01, &h7F, &h7F, &h7F, &h7F, &h0F, &h20, &h00, 6, 5
Data "Home",    8, -1, -1, -1, -1, -1, -1, -1, -1, 255, 0
Data "Touch",   8, -1, -1, -1, -1, -1, -1, -1, -1, 255, 0
Data ""
