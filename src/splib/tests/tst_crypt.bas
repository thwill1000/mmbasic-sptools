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

Const BASE% = Mm.Info(Option Base)

add_test("test_md5_given_string")
add_test("test_md5_given_long_string")
add_test("test_md5_file")
add_test("test_xxtea_encrypt")
add_test("test_xxtea_decrypt")

run_tests(Choice(InStr(Mm.CmdLine$, "--base"), "", "--base=1"))

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_md5_given_string()
  Local actual$, expected$, filename$, i%, s$, size%

  ' Without full-stop
  s$ = "The quick brown fox jumps over the lazy dog"
  actual$ = crypt.md5$(Peek(VarAddr s$) + 1, Len(s$))
  assert_string_equals("9e107d9d372bb6826bd81d3542a419d6", actual$)

  ' With full-stop
  s$ = "The quick brown fox jumps over the lazy dog."
  actual$ = crypt.md5$(Peek(VarAddr s$) + 1, Len(s$))
  assert_string_equals("e4d909c290d0fb1ca068ffaddf22cbd0", actual$)

  Restore md5_data
  Do
    Read filename$, size%, expected$
    If filename$ = "END" Then Exit Do
    If size% > 255 Then Continue Do
    Open fil.PROG_DIR$ + "/resources/tst_crypt/" + filename$ For Input As #1
    s$ = Input$(255, #1)
    Close #1
    assert_int_equals(size%, Len(s$))
    actual$ = crypt.md5$(Peek(VarAddr s$) + 1, Len(s$))
    assert_string_equals(expected$, actual$)
  Loop
End Sub

Sub test_md5_given_long_string()
  Local actual$, expected$, filename$, i%, ls%(100), s$, size%

  Restore md5_data
  Do
    Read filename$, size%, expected$
    If filename$ = "END" Then Exit Do
    LongString Clear ls%()
    Open fil.PROG_DIR$ + "/resources/tst_crypt/" + filename$ For Input As #1
    Do
      s$ = Input$(255, #1)
      LongString Append ls%(), s$
    Loop Until s$ = ""
    Close #1
    assert_int_equals(size%, LLen(ls%()))
    actual$ = crypt.md5$(Peek(VarAddr ls%()) + 8, LLen(ls%()))
    If expected$ <> actual$ Then Print filename$
    assert_string_equals(expected$, actual$)
  Loop
End Sub

Sub test_md5_file()
  Local i%, filename$, size%, expected$, actual$

  Restore md5_data
  Do
    Read filename$, size%, expected$
    If filename$ = "END" Then Exit Do
    Open fil.PROG_DIR$ + "/resources/tst_crypt/" + filename$ For Input As #1
    actual$ = crypt.md5_file$(1)
    Close #1
    assert_string_equals(expected$, actual$)
  Loop
End Sub

md5_data:
Data "empty.txt",             0, "d41d8cd98f00b204e9800998ecf8427e"
Data "lorem_ipsum_54.txt",   54, "e51638c24dbb103f460b70df14939bc5"
Data "lorem_ipsum_55.txt",   55, "fc10a08df7fafa3871166646609e1c95"
Data "lorem_ipsum_56.txt",   56, "572be236390dc0bca92bb5c5999d2290"
Data "lorem_ipsum_63.txt",   63, "5213818ec87e04c44d75b00f79b23110"
Data "lorem_ipsum_64.txt",   64, "5819ecacdd8551d108e4fe83be10200e"
Data "lorem_ipsum_65.txt",   65, "d66eea968b0c65fbb800bc5abb35cb4e"
Data "lorem_ipsum_255.txt", 255, "123b001fc08115b683545c1c4140cc82"
Data "lorem_ipsum.txt",     446, "f90b84824e80384c67922ce9c932ac55"
Data "END", 0, ""

Sub test_xxtea_encrypt()
  Local v%(array.new%(10)) ' 80 bytes
  Local v_addr% = Peek(VarAddr v%())
  Local n% = 20            ' 20 x 32-bit unsigned integers
  Local k%(array.new%(2))  ' 16 bytes = 128 bits
  Local expected%, i%

  Restore decrypted_values
  read_values(v%(), n%)

  ' dump_values(v%(), n%)
  assert_int_equals(1, crypt.xxtea_encrypt%(v%(), n%, k%()))
  ' dump_values(v%(), n%())

  Restore encrypted_values
  For i% = 0 To n% - 1
    Read expected%
    assert_int_equals(expected%, Peek(Word v_addr% + 4 * i%))
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
  Local expected%, i%

  Restore encrypted_values
  read_values(v%(), n%)

  ' dump_values(v%(), n%)
  assert_int_equals(1, crypt.xxtea_decrypt%(v%(), n%, k%()))
  ' dump_values(v%(), n%)

  Restore decrypted_values
  For i% = 0 To n% - 1
    Read expected%
    assert_int_equals(expected%, Peek(Word v_addr% + 4 * i%))
  Next
End Sub
