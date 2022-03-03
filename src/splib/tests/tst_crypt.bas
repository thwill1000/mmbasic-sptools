' Copyright (c) 2021-2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.03

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../crypt.inc"

Const BASE% = Mm.Info(Option Base)

add_test("test_md5_fmt")
add_test("test_md5_given_string")
add_test("test_md5_given_long_string")
add_test("test_md5_file")
add_test("test_xxtea_block_encrypt")
add_test("test_xxtea_block_decrypt")
add_test("test_xxtea_file")
add_test("test_xxtea_file_iv_dependent")
add_test("test_xxtea_file_key_dependent")

run_tests(Choice(InStr(Mm.CmdLine$, "--base"), "", "--base=1"))

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_md5_fmt()
  Local md5%(array.new%(2))
  Const md5_addr% = Peek(VarAddr md5%())
  Restore data_test_md5_fmt
  Local i%, x%
  For i% = 0 To 15
    Read x%
    Poke Byte  md5_addr% + i%, x%
  Next

  assert_string_equals("0162ab891d5fff001a2fbc93d7f0f2ef", crypt.md5_fmt$(md5%()))
End Sub

data_test_md5_fmt:
Data &h01, &h62, &hAB, &h89, &h1D, &h5F, &hFF, &h00
Data &h1A, &h2F, &hBC, &h93, &hD7, &hF0, &hF2, &hEF

Sub test_md5_given_string()
  Local filename$, size%, md5_decrypted$, md5_encrypted$
  Local md5%(array.new%(2)), s$

  ' Without full-stop
  s$ = "The quick brown fox jumps over the lazy dog"
  assert_true(crypt.md5%(Peek(VarAddr s$) + 1, Len(s$), md5%()))
  assert_string_equals("9e107d9d372bb6826bd81d3542a419d6", crypt.md5_fmt$(md5%()))

  ' With full-stop
  s$ = "The quick brown fox jumps over the lazy dog."
  assert_true(crypt.md5%(Peek(VarAddr s$) + 1, Len(s$), md5%()))
  assert_string_equals("e4d909c290d0fb1ca068ffaddf22cbd0", crypt.md5_fmt$(md5%()))

  Restore data_test_md5
  Do
    restore_data_test_md5(filename$)
    Read filename$, size%, md5_decrypted$, md5_encrypted$
    If filename$ = "END" Then Exit Do
    If size% > 255 Then Continue Do
    Open file.PROG_DIR$ + "/resources/tst_crypt/" + filename$ For Input As #1
    s$ = Input$(255, #1)
    Close #1
    assert_int_equals(size%, Len(s$))
    assert_true(crypt.md5%(Peek(VarAddr s$) + 1, Len(s$), md5%()))
    assert_string_equals(md5_decrypted$, crypt.md5_fmt$(md5%()))
  Loop
End Sub

' Restores the global DATA pointer to a given entry in the 'data_test_md5' DATA.
' Needed on platforms that do not yet implement READ SAVE and READ RESTORE
' because crypt.md5%() and friends also manipulate the global DATA pointer.
Sub restore_data_test_md5(filename$)
  If Mm.Device$ <> "MMBasic For Windows" Then
    Restore data_test_md5
    If filename$ = "" Then Exit Sub
    Local s$, size%, enc$, dec$
    Do
      Read s$, size%, enc$, dec$
      If s$ = filename$ Then Exit Do
    Loop
  EndIf
End Sub

Sub test_md5_given_long_string()
  Local filename$, size%, md5_decrypted$, md5_encrypted$
  Local i%, ls%(100), md5%(array.new%(2)), s$

  Restore data_test_md5
  Do
    restore_data_test_md5(filename$)
    Read filename$, size%, md5_decrypted$, md5_encrypted$
    If filename$ = "END" Then Exit Do
    LongString Clear ls%()
    Open file.PROG_DIR$ + "/resources/tst_crypt/" + filename$ For Input As #1
    Do
      s$ = Input$(255, #1)
      LongString Append ls%(), s$
    Loop Until s$ = ""
    Close #1
    assert_int_equals(size%, LLen(ls%()))
    assert_true(crypt.md5%(Peek(VarAddr ls%()) + 8, LLen(ls%()), md5%()))
    assert_string_equals(md5_decrypted$, crypt.md5_fmt$(md5%()))
  Loop
End Sub

Sub test_md5_file()
  Local i%, filename$, size%, md5_decrypted$, md5_encrypted$, md5%(array.new%(2))

  Restore data_test_md5
  Do
    restore_data_test_md5(filename$)
    Read filename$, size%, md5_decrypted$, md5_encrypted$
    If filename$ = "END" Then Exit Do
    Open file.PROG_DIR$ + "/resources/tst_crypt/" + filename$ For Input As #1
    assert_true(crypt.md5_file%(1, md5%()))
    Close #1
    assert_string_equals(md5_decrypted$, crypt.md5_fmt$(md5%()))
  Loop
End Sub

data_test_md5:
' Filename, file size, expected unencrypted MD5, expected encrypted MD5
' Note that the encrypted MD5 is initialisation vector specific.
Data "empty.txt",            0,"d41d8cd98f00b204e9800998ecf8427e","232eeef90183d7ddfeb22aa80c6efa5e"
Data "lorem_ipsum_54.txt",  54,"e51638c24dbb103f460b70df14939bc5","4d03aaeafd08fb71a8a8a0f8cbaeded2"
Data "lorem_ipsum_55.txt",  55,"fc10a08df7fafa3871166646609e1c95","38d360aa333133aa39f032416f270a4f"
Data "lorem_ipsum_56.txt",  56,"572be236390dc0bca92bb5c5999d2290","7a738c8a534947512156a566bac3ecf1"
Data "lorem_ipsum_63.txt",  63,"5213818ec87e04c44d75b00f79b23110","b9af130d16deb6fbc8d0abdd0807c8e1"
Data "lorem_ipsum_64.txt",  64,"5819ecacdd8551d108e4fe83be10200e","ad924354452e9d78e1fa487360bbe80f"
Data "lorem_ipsum_65.txt",  65,"d66eea968b0c65fbb800bc5abb35cb4e","14956694aa4432aed9c07f3c3b774bae"
Data "lorem_ipsum_255.txt",255,"123b001fc08115b683545c1c4140cc82","fc3e7b587986efc2f83079802e56716d"
Data "lorem_ipsum.txt",    446,"f90b84824e80384c67922ce9c932ac55","0ffd2be13672cd59da9c06c50d2231a2"
Data "END", 0, ""

Sub test_xxtea_block_encrypt()
  Local v%(array.new%(10)) ' 80 bytes
  Local v_addr% = Peek(VarAddr v%())
  Local k%(array.new%(2))  ' 16 bytes = 128 bits
  Local expected%, i%

  Restore decrypted_values
  read_values(v%(), 20)

  assert_true(crypt.xxtea_block%("encrypt", v%(), k%()))

  Restore encrypted_values
  For i% = 0 To 19
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

Sub test_xxtea_block_decrypt()
  Local v%(array.new%(10)) ' 80 bytes
  Local v_addr% = Peek(VarAddr v%())
  Local k%(array.new%(2))  ' 16 bytes = 128 bits
  Local expected%, i%

  Restore encrypted_values
  read_values(v%(), 20)

  assert_true(crypt.xxtea_block%("decrypt", v%(), k%()))

  Restore decrypted_values
  For i% = 0 To 19
    Read expected%
    assert_int_equals(expected%, Peek(Word v_addr% + 4 * i%))
  Next
End Sub

Sub test_xxtea_file()
  Local filename$, size%, md5_decrypted$, md5_encrypted$
  Local original_file$, encrypted_file$, decrypted_file$
  Local k%(array.new%(2)) = (17470987, -89397865243)
  Local iv%(array.new%(2)) = (-478912, 123456789)
  Local md5%(array.new%(2))

  Restore data_test_md5
  Do
    restore_data_test_md5(filename$)
    Read filename$, size%, md5_decrypted$, md5_encrypted$
    If filename$ = "END" Then Exit Do
    original_file$ = file.PROG_DIR$ + "/resources/tst_crypt/" + filename$
    encrypted_file$ = file.PROG_DIR$ + "/tmp/" + filename$ + ".encrypted"
    decrypted_file$ = file.PROG_DIR$ + "/tmp/" + filename$ + ".decrypted"

    ' Encrypt file.
    Open original_file$ For Input As #1
    Open encrypted_file$ For Output As #2
    assert_true(crypt.xxtea_file%("encrypt", 1, 2, k%(), iv%()))
    Close #1
    Close #2

    ' Check MD5 hash of encrypted file.
    Open encrypted_file$ For Input As #1
    assert_true(crypt.md5_file%(1, md5%()))
    Close #1
    assert_string_equals(md5_encrypted$, crypt.md5_fmt$(md5%()))

    ' Decrypt file.
    Open encrypted_file$ For Input As #1
    Open decrypted_file$ For Output As #2
    assert_true(crypt.xxtea_file%("decrypt", 1, 2, k%(), iv%()))
    Close #1
    Close #2

    ' Check MD5 hash of decrypted file.
    Open decrypted_file$ For Input As #1
    assert_true(crypt.md5_file%(1, md5%()))
    Close #1
    assert_string_equals(md5_decrypted$, crypt.md5_fmt$(md5%()))
  Loop

  ' Test that k%() and iv%() haven't changed, they should be constants.
  assert_int_equals(17470987,     k%(BASE%))
  assert_int_equals(-89397865243, k%(BASE% + 1))
  assert_int_equals(-478912,      iv%(BASE%))
  assert_int_equals(123456789,    iv%(BASE% + 1))
End Sub

Sub test_xxtea_file_iv_dependent()
  Const filename$ = "lorem_ipsum.txt"
  Const original_file$ = file.PROG_DIR$ + "/resources/tst_crypt/" + filename$
  Const encrypted_file$ = file.PROG_DIR$ + "/tmp/" + filename$ + ".iv.encrypted"
  Const decrypted_file$ = file.PROG_DIR$ + "/tmp/" + filename$ + ".iv.decrypted"
  Local k%(array.new%(2)) = (17470987, -89397865243)
  Local md5%(array.new%(2))

  ' Different initialisation vector to 'test_xxtea_file'.
  Local iv%(array.new%(2)) = (36, -29)
  Local iv_addr% = Peek(VarAddr iv%())

  ' Encrypt file.
  Open original_file$ For Input As #1
  Open encrypted_file$ For Output As #2
  assert_true(crypt.xxtea_file%("encrypt", 1, 2, k%(), iv%()))
  Close #1
  Close #2

  ' Check encrypted file begins with initialisation vector.
  Open encrypted_file$ For Input As #1
  Local s$ = Input$(16, #1)
  Close #1
  Local s_addr% = Peek(VarAddr s$)
  Local i%
  For i% = 0 To 15
    assert_hex_equals(Peek(Byte iv_addr% + i%), Peek(Byte s_addr% + i% + 1))
  Next

  ' Check MD5 hash of encrypted file - different to value in 'test_xxtea_file'.
  Open encrypted_file$ For Input As #1
  assert_true(crypt.md5_file%(1, md5%()))
  Close #1
  assert_string_equals("ffd561e01b16d72c3a927bb653a4c5a6", crypt.md5_fmt$(md5%()))

  ' Decrypt file.
  Open encrypted_file$ For Input As #1
  Open decrypted_file$ For Output As #2
  assert_true(crypt.xxtea_file%("decrypt", 1, 2, k%(), iv%()))
  Close #1
  Close #2

  ' Check MD5 hash of decrypted file.
  Open decrypted_file$ For Input As #1
  assert_true(crypt.md5_file%(1, md5%()))
  Close #1
  assert_string_equals("f90b84824e80384c67922ce9c932ac55", crypt.md5_fmt$(md5%()))
End Sub

Sub test_xxtea_file_key_dependent()
  Const filename$ = "lorem_ipsum.txt"
  Const original_file$ = file.PROG_DIR$ + "/resources/tst_crypt/" + filename$
  Const encrypted_file$ = file.PROG_DIR$ + "/tmp/" + filename$ + ".key.encrypted"
  Const decrypted_file$ = file.PROG_DIR$ + "/tmp/" + filename$ + ".key.decrypted"
  Local iv%(array.new%(2)) = (-478912, 123456789)
  Local md5%(array.new%(2))

  ' Different 128-bit key to 'test_xxtea_file'.
  Local k%(array.new%(2)) = (123, 456)

  ' Encrypt file.
  Open original_file$ For Input As #1
  Open encrypted_file$ For Output As #2
  assert_true(crypt.xxtea_file%("encrypt", 1, 2, k%(), iv%()))
  Close #1
  Close #2

  ' Check MD5 hash of encrypted file - different to value in 'test_xxtea_file'.
  Open encrypted_file$ For Input As #1
  assert_true(crypt.md5_file%(1, md5%()))
  Close #1
  assert_string_equals("0e0ff51ca83d22f51f30ada8e81d46bb", crypt.md5_fmt$(md5%()))

  ' Decrypt file.
  Open encrypted_file$ For Input As #1
  Open decrypted_file$ For Output As #2
  assert_true(crypt.xxtea_file%("decrypt", 1, 2, k%(), iv%()))
  Close #1
  Close #2

  ' Check MD5 hash of decrypted file.
  Open decrypted_file$ For Input As #1
  assert_true(crypt.md5_file%(1, md5%()))
  Close #1
  assert_string_equals("f90b84824e80384c67922ce9c932ac55", crypt.md5_fmt$(md5%()))
End Sub
