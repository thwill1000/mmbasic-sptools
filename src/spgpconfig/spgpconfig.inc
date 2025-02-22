' Copyright (c) 2025 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For PicoMiteUSB variants

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip : Const sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.provides("spgpc")
If sys.err$ <> "" Then Error sys.err$
'!endif

' The code uses two 'structures'.
'
' ui_data%() which is a 19 x 8 element 2D array.
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
'   (12)  R1
'   (13)  L2
'   (14)  R2
'   (15)  Select
'   (16)  Start
'   (17)  Home
'   (18)  Touch
'
' c_data%() which is a (18 x 2) element 2D array.
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
'   (11)  R2
'   (12)  X
'   (13)  A
'   (14)  Y
'   (15)  B
'   (16)  L2
'   (17)  Touch

' Button names to use in the UI.
Const spgpc.UI_NAMES = "D-Up D-Down D-Left D-Right A B X Y L1 R1 L2 R2 Select Start Home Touch"

' Button names used in the MMBasic gamepad C-struct.
Const spgpc.C_NAMES = "R START HOME SELECT L DOWN RIGHT UP LEFT R2 X A Y B L2 TOUCH"

' Map from elements in the UI data to the C data.
Dim spgpc.UI_2_C(18) As Integer = (-1, -1, -1, 9, 7, 10, 8, 13, 15, 12, 14, 6, 2, 16, 11, 5, 3, 4, 17)

' Transforms 'ui_data' to 'c_data'.
'
' @param  ui_data%  Data in "UI" format.
' @param  c_data%   Data in "C" format.
' @return           sys.SUCCESS on success, otherwise sys.FAILURE and sets sys.err$.
Function spgpc.ui_to_c_data%(ui_data%(), c_data%())
  c_data%(0, 0) = ui_data%(0, 0)
  c_data%(1, 0) = ui_data%(1, 0)
  Local button$, i%, j%, up%(7), down%(7), index%, result%, value%
  For i% = 3 To 18
    For j% = 0 To 7
      up%(j%) = ui_data%(2, j%)
      down%(j%) = ui_data%(i%, j%)
    Next
    spgpc.ui_to_c_data% = spgpc.translate_record%( up%(), down%(), index%, value%)
    If spgpc.ui_to_c_data% <> sys.SUCCESS Then Exit Function
    c_data%(spgpc.UI_2_C(i%), 0) = index%
    c_data%(spgpc.UI_2_C(i%), 1) = value%
  Next
End Function

' Translates USB record for a button press into an (index%, value%) pair.
'
' @param  up%()    USB record (8 byte values) when button is up.
' @param  down%()  USB record (8 byte values) when button is down.
' @param  index%   Index into the record for which byte changes, 255 if none.
' @param  value%   0-7      Bit goes high when button pressed.
'                  128-135  Bit (+ 128) goes low when button pressed.
'                  64       Byte value goes < 64 when button pressed (for analog mapped button).
'                  192      Byte value goes > 192 when button pressed (for analog mapped button).
' @return          sys.SUCCESS on success, otherwise sys.FAILURE and sets sys.err$.
Function spgpc.translate_record%(up%(), down%(), index%, value%)
  Local found%, i%
  If down%(0) = -1 Then
    index% = 255
    value% = 0
    Exit Function
  EndIf
  For i% = 0 To 7
    Select Case spgpc.num_changed_bits%(up%(i%), down%(i%))
      Case 0
        Continue For
      Case 1
        index% = i%
        If up%(i%) >= &h7F And up%(i%) <= &h81 Then
          value% = spgpc.compute_mapping_analog%(up%(i%), down%(i%))
        Else
          value% = spgpc.compute_mapping_binary%(up%(i%), down%(i%))
        EndIf
        Inc found%
      Case Else
        index% = i%
        value% = spgpc.compute_mapping_analog%(up%(i%), down%(i%))
        Inc found%
    End Select
  Next
  If found% = 1 Then Exit Function

  spgpc.translate_record% = sys.FAILURE
  sys.err$ = "No translation found:"
  Cat sys.err$, " Up {"
  For i% = 0 To 7
    If i% Then Cat sys.err$, " "
    Cat sys.err$, Hex$(up%(i%), 2)
  Next
  Cat sys.err$, ", Down {"
  For i% = 0 To 7
    If i% Then Cat sys.err$, " "
    Cat sys.err$, Hex$(down%(i%), 2)
  Next
  Cat sys.err$, "}"
End Function

' Computes the mapping for an "analog" button.
'
' @param  up%    Byte value when button is up.
' @param  down%  Byte value when button is down.
' @return        &h40 if down% < &h40
'                &hC0 if down% > &hC0
'                sys.FAILURE and sets sys.err$ if mapping could not be computed.
Function spgpc.compute_mapping_analog%(up%, down%)
  If spgpc.num_changed_bits%(up%, down%) = 0 Then
    spgpc.compute_mapping_analog% = sys.FAILURE
  Else
    If down% < &h40 Then
      spgpc.compute_mapping_analog% = &h40
    ElseIf down% > &hC0 Then
      spgpc.compute_mapping_analog% = &hC0
    Else
      spgpc.compute_mapping_analog% = sys.FAILURE
    EndIf
  EndIf

  If spgpc.compute_mapping_analog% = sys.FAILURE Then
    sys.err$ = "Analog mapping could not be computed: &h" + Hex$(up%, 2) + " => &h" + Hex$(down%, 2)
  EndIf
End Function

' Compares two bytes and returns the number of changed bits.
'
' NOTE: Changes between the byte values 0x7F, 0x80 and 0x81 are ignored.
'
' @param  b1%  First byte value.
' @param  b2%  Second byte value.
' @return      Number of changed bits on success, otherwise sys.FAILURE and sets sys.err$.
Function spgpc.num_changed_bits%(b1%, b2%)
  If b1% < 0 Or b1% > 255 Then
    spgpc.num_changed_bits% = sys.FAILURE
    sys.err$ = "Invalid 'b1' byte parameter: " + Str$(b1%)
  ElseIf b2% < 0 Or b2% > 255 Then
    spgpc.num_changed_bits% = sys.FAILURE
    sys.err$ = "Invalid 'b2' byte parameter: " + Str$(b2%)
  EndIf
  If spgpc.num_changed_bits% = sys.FAILURE Then Exit Function

  If b1% >= &h7F And b1% <= &h81 And b2% >= &h7F And b2% <= &h81 Then Exit Function

  Local i%, mask%
  For i% = 0 To 7
    mask% = 1 << i%
    Inc spgpc.num_changed_bits%, (b1% And mask%) <> (b2% And mask%)
  Next
End Function

' Computes the mapping for a digital button.
'
' @param  up%    Byte value when button is up.
' @param  down%  Byte value when button is down.
' @return        -1 if no mapping/correlation (up% ~= down%).
'                Index (0..7) if one bit went high.
'                128 + Index (0..7) if one bit went low.
'                sys.FAILURE and sets sys.err$ if mapping could not be computed.
Function spgpc.compute_mapping_binary%(up%, down%)
  Select Case spgpc.num_changed_bits%(up%, down%)
    Case 1
      ' Expected, do nothing.
    Case Else
      spgpc.compute_mapping_binary% = sys.FAILURE
      sys.err$ = "Binary mapping could not be computed: &h" + Hex$(up%, 2) + " => &h" + Hex$(down%, 2)
      Exit Function
  End Select

  Local i%, mask%
  For i% = 0 To 7
    mask% = 1 << i%
    If (up% And mask%) <> (down% And mask%) Then
      spgpc.compute_mapping_binary% = Choice(down% And mask%, i%, 128 + i%)
      Exit Function
    EndIf
  Next
End Function

' Print C-struct for gamepad suitable for inclusion in PicoMite source code.
Sub spgpc.write_c_struct(c_data%(), fnbr%)
  Local i% = 0, name$
  Print #fnbr%, "{"
  Print #fnbr%, "  ";
  Print #fnbr%, spgpc.format_cmember$("vid", c_data%(0, 0), 4);
  Print #fnbr%, ", ";
  Print #fnbr%, spgpc.format_cmember$("pid", c_data%(1, 0), 4);
  i% = 1
  Do
    name$ = Field$(spgpc.C_NAMES, i%, " ")
    If name$ = "" Then Exit Do
    If i% Mod 4 Then
      Print #fnbr%, ", ";
    Else
      Print #fnbr%
      Print #fnbr%, "  ";
    EndIf
    Print #fnbr%, spgpc.format_cmember_pair$("b_" + name$, c_data%(i% + 1, 0), c_data%(i% + 1, 1), 2);
    Inc i%
  Loop
  Print #fnbr%
  Print #fnbr%, "}"
End Sub

' Format C struct member assignment for C.
Function spgpc.format_cmember$(name$, value%, num_digits%)
  spgpc.format_cmember$ = "." + name$ + "=" + spgpc.format_chex$(value%, num_digits%)
End Function

' Format hex number for C.
Function spgpc.format_chex$(value%, num_digits%)
  spgpc.format_chex$ = "0x" + Hex$(value%, Choice(num_digits%, num_digits%, 2))
End Function

' Format C struct member assignment for C value pair.
Function spgpc.format_cmember_pair$(name$, value1%, value2%, num_digits%)
  spgpc.format_cmember_pair$ = "." + name$ + "={" + spgpc.format_chex$(value1%, num_digits%)
  Cat spgpc.format_cmember_pair$, "," + spgpc.format_chex$(value2%, num_digits%) + "}"
End Function

' Print GAMEPAD CONFIGURE command.
Sub spgpc.write_bas_file(c_data%(), fnbr%)
  Print #fnbr%, "Gamepad Configure ";
  Print #fnbr%, "&h" + Hex$(c_data%(0, 0), 4) + ",";
  Print #fnbr%, "&h" + Hex$(c_data%(1, 0), 4);
  Local i%
  For i% = 2 To Bound(c_data%(), 1)
    Print #fnbr%, "," + Str$(c_data%(i%, 0)) + "," + Str$(c_data%(i%, 1));
  Next
  Print #fnbr%
End Sub

Sub spgpc.dump_ui_data(ui_data%())
  Local i%, j%
  For i% = 0 To Bound(ui_data%(), 1)
    For j% = 0 To Bound(ui_data%(), 2)
      Print Hex$(ui_data%(i%, j%), 2) + " ";
    Next
    Print
  Next
End Sub
