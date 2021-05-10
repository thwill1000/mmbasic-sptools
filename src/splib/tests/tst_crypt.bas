' Copyright (c) 2021 Thomas Hugo Williams

Option Explicit On
Option Default None
Option Base Choice(InStr(Mm.CmdLine$, "--base=1"), 1, 0)

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../crypt.inc"

add_test("test_xxtea_encrypt")
add_test("test_xxtea_decrypt")

run_tests(Choice(InStr(Mm.CmdLine$, "--base"), "", "--base=1"))

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_xxtea_encrypt()
  Local v%(array.new%(10)) ' 80 bytes
  Local v_addr% = Peek(VarAddr v%())
  Local n% = 20            ' 20 x 32-bit unsigned integers
  Local k%(array.new%(2))  ' 16 bytes = 128 bits
  Local i%, x%

  Restore decrypted_values
  read_values(v%(), n%)

  ' dump_values(v%(), n%)
  assert_int_equals(1, crypt.xxtea_encrypt%(v%(), n%, k%()))
  ' dump_values(v%(), n%())

  Restore encrypted_values
  For i% = 0 To n% - 1
    Read x%
    assert_int_equals(Peek(Word v_addr% + 4 * i%), x%)
  Next
End Sub

Sub read_values(v%(), n%)
  Local v_addr% = Peek(VarAddr v%())
  Local i%, x%
  For i% = 0 To n% - 1
    Read x%
    Poke Word v_addr% + 4 * i%, x%
  Next
End Sub

Sub dump_values(v%(), n%)
  Local v_addr% = Peek(VarAddr v%())
  Local i%
  For i% = 0 To n% - 1
    If i% Mod 8 = 0 Then Print
    Print Hex$(Peek(Word v_addr% + 4 * i%), 8) " ";
  Next
End Sub

decrypted_values:
Data &h00000001, &h00000002, &h00000003, &h00000004, &h00000005, &h00000006, &h00000007, &h00000008
Data &h00000009, &h0000000A, &h0000000B, &h0000000C, &h0000000D, &h0000000E, &h0000000F, &h00000010
Data &h00000011, &h00000012, &h00000013, &h00000014

encrypted_values:
Data &hca16bebe, &hcdc347cb, &h82d7e1c8, &h41ee03b7, &hd749f024, &h96f1570c, &h49f804fa, &h7c0b7b66
Data &h870e0d11, &he5f70f70, &h993e801f, &h520da815, &h7f9f98b2, &h71e3c3c9, &h3cc28a6a, &h6e90cea6
Data &hc605cb14, &he797460a, &h52da71da, &h0b831cd3

Sub test_xxtea_decrypt()
  Local v%(array.new%(10)) ' 80 bytes
  Local v_addr% = Peek(VarAddr v%())
  Local n% = 20            ' 20 x 32-bit unsigned integers
  Local k%(array.new%(2))  ' 16 bytes = 128 bits
  Local i%, x%

  Restore encrypted_values
  read_values(v%(), n%)

  ' dump_values(v%(), n%)
  assert_int_equals(1, crypt.xxtea_decrypt%(v%(), n%, k%()))
  ' dump_values(v%(), n%)

  Restore decrypted_values
  For i% = 0 To n% - 1
    Read x%
    assert_int_equals(Peek(Word v_addr% + 4 * i%), x%)
  Next
End Sub
