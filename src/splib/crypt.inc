' Copyright (c) 2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

' Implementation of the Tiny Encryption Algorithm,
' specifically the XXTEA variant.

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("array")
sys.provides("crypt")
If sys.err$ <> "" Then Error sys.err$

' Calculates the MD5 hash of bytes held in a buffer.
'
' To calculate the MD5 hash of a string s$:
'   crypt.md5$(Peek(VarAddr s$) + 1, Len(s$))
'
' To calculate the MD5 hash of a long string ls%():
'   crypt.md5$(Peek(VarAddr ls%()) + 8, LLen(ls%()))
'
' @param  ad%    address of the buffer.
' @param  size%  number of bytes to process.
' @return        MD5 hash, 128-bit little-endian value formatted as hex.
Function crypt.md5$(ad%, size%)

  Local chunk%(array.new%(64))
  Local chunk_addr% = Peek(VarAddr chunk%())

  ' Storage for hash, each element treated as 32-bit unsigned integer.
  Local h%(array.new%(4))

  ' Storage for constants, each element treated as 32-bit unsigned integer.
  Local r%(array.new%(64))
  Local k%(array.new%(64))

  Local cur% = 0, num%

  Do
    ' Process chunks of 64 bytes / 512 bits at a time.
    num% = Min(size% - cur%, 64)
    Memory Set chunk_addr%, 0, 64
    Memory Copy ad% + cur%, chunk_addr%, num%

    If num% < 64 Then
      ' Append '1' bit to chunk%, the remainder will already be padded with zeros.
      Poke Byte chunk_addr% + num%, &h80

      If num% > 55 Then
        crypt.md5_chunk(chunk%(), h%(), r%(), k%())
        Memory Set chunk_addr%, 0, 64
      EndIf

      ' Last 64-bits of chunk% should be data length in bits as a 64-bit little-endian integer.
      Poke Integer chunk_addr% + 56, size% * 8
    EndIf

    crypt.md5_chunk(chunk%(), h%(), r%(), k%())

    Inc cur%, 64
  Loop While num% = 64

  Local i%
  Local h_addr% = Peek(VarAddr h%())
  For i% = 0 To 31
    ' Note we are only interested in the bottom 4-bytes of each Integer.
    If (i% Mod 8) < 4 Then Cat crypt.md5$, Hex$(Peek(Byte h_addr% + i%), 2)
  Next

  crypt.md5$ = LCase$(crypt.md5$)
End Function

' Calculates the MD5 hash of a file.
'
' @param  fd%    file-descriptor for a file Open For Input.
' @return        MD5 hash, 128-bit little-endian value formatted as hex.
Function crypt.md5_file$(fd%)

  Local chunk%(array.new%(64))
  Local chunk_addr% = Peek(VarAddr chunk%())

  ' Storage for hash, each element treated as 32-bit unsigned integer.
  Local h%(array.new%(4))

  ' Storage for constants, each element treated as 32-bit unsigned integer.
  Local r%(array.new%(64))
  Local k%(array.new%(64))

  Local s$, num%, size%

  Do
    s$ = Input$(64, #fd%)
    num% = Len(s$)
    Inc size%, num%
    Memory Set chunk_addr%, 0, 64
    Memory Copy Peek(VarAddr s$) + 1, chunk_addr%, num%

    If num% < 64 Then
      ' Append '1' bit to chunk%, the remainder will already be padded with zeros.
      Poke Byte chunk_addr% + num%, &h80

      If num% > 55 Then
        crypt.md5_chunk(chunk%(), h%(), r%(), k%())
        Memory Set chunk_addr%, 0, 64
      EndIf

      ' Last 64-bits of chunk% should be file length in bits as a 64-bit little-endian integer.
      Poke Integer chunk_addr% + 56, size% * 8
    EndIf

    crypt.md5_chunk(chunk%(), h%(), r%(), k%())
  Loop While num% = 64

  ' Format the hash as a string.
  Local i%
  Local h_addr% = Peek(VarAddr h%())
  For i% = 0 To 31
    ' Note we are only interested in the bottom 4-bytes of each Integer.
    If (i% Mod 8) < 4 Then Cat crypt.md5_file$, Hex$(Peek(Byte h_addr% + i%), 2)
  Next

  crypt.md5_file$ = LCase$(crypt.md5_file$)
End Function

' @param  chunk%()  512-bit chunk to process (64 elements).
' @param  h%()      hash-values (4 elements).
' @param  r%()      per-round shift amounts (64 elements).
' @param  k%()      binary integer part of the sines of integers (Radians) as constants (64 elements).
Sub crypt.md5_chunk(chunk%(), h%(), r%(), k%())
  Const BASE% = Mm.Info(Option Base)

  ' Note that all variables should be treated as unsigned 32-bit integers
  ' and wrap modulo 2^32 when calculating.

  ' Initialise hash and constants if this is the first call.
  If r%(BASE%) = 0 Then
    Local data_addr% = Peek(CFunAddr crypt.md5_data)
    Memory Copy data_addr%,       Peek(VarAddr h%()), 64
    Memory Copy data_addr% + 32,  Peek(VarAddr r%()), 512
    Memory Copy data_addr% + 544, Peek(VarAddr k%()), 512
  EndIf

  ' Split chunk into 16 x 32-bit words.
  Local chunk_addr% = Peek(VarAddr chunk%())
  Local i%, w%(array.new%(16))
  For i% = 0 To 15
     w%(i% + BASE%) = Peek(Word chunk_addr% + 4 * i%)
  Next

  ' Main loop.
  Local a% = h%(base%), b% = h%(base% + 1), c% = h%(base% + 2), d% = h%(base% + 3), f%, g%, tmp%
  For i% = 0 To 63
    Select Case i%
      Case 0 To 15
        f% = d% Xor (b% And (c% Xor d%))
        g% = i%
      Case 16 To 31
        f% = c% Xor (d% And (b% Xor c%))
        g% = (5 * i% + 1) Mod 16
      Case 32 To 47
        f% = b% Xor c% Xor d%
        g% = (3 * i% + 5) Mod 16
      Case Else:
        f% = c% Xor (b% Or (d% Xor &hFFFFFFFF))
        g% = (7 * i%) Mod 16
    End Select

    tmp% = d%
    d% = c%
    c% = b%
    b% = (a% + f%) And &hFFFFFFFF
    b% = (b% + k%(i% + base%)) And &hFFFFFFFF
    b% = (b% + w%(g% + base%)) And &hFFFFFFFF
    b% = (b% << r%(i% + base%)) Or (b% >> (32 - r%(i% + base%)))
    b% = (b% + c%) And &hFFFFFFFF
    a% = tmp%

  Next

  ' Add this chunk's hash to the result.
  h%(base%)     = (h%(base%)     + a%) And &hFFFFFFFF
  h%(base% + 1) = (h%(base% + 1) + b%) And &hFFFFFFFF
  h%(base% + 2) = (h%(base% + 2) + c%) And &hFFFFFFFF
  h%(base% + 3) = (h%(base% + 3) + d%) And &hFFFFFFFF

End Sub

' Not a real CSUB, this provides data for initialising constant arrays in crypt.md5().
CSub crypt.md5_data()
  00000000

  ' 4 x 8 byte values to initialise hash 'h'
  67452301 00000000 EFCDAB89 00000000 98BADCFE 00000000 10325476 00000000

  ' 64 x 8 byte values for 'r'
  00000007 00000000 0000000C 00000000 00000011 00000000 00000016 00000000
  00000007 00000000 0000000C 00000000 00000011 00000000 00000016 00000000
  00000007 00000000 0000000C 00000000 00000011 00000000 00000016 00000000
  00000007 00000000 0000000C 00000000 00000011 00000000 00000016 00000000
  00000005 00000000 00000009 00000000 0000000E 00000000 00000014 00000000
  00000005 00000000 00000009 00000000 0000000E 00000000 00000014 00000000
  00000005 00000000 00000009 00000000 0000000E 00000000 00000014 00000000
  00000005 00000000 00000009 00000000 0000000E 00000000 00000014 00000000
  00000004 00000000 0000000B 00000000 00000010 00000000 00000017 00000000
  00000004 00000000 0000000B 00000000 00000010 00000000 00000017 00000000
  00000004 00000000 0000000B 00000000 00000010 00000000 00000017 00000000
  00000004 00000000 0000000B 00000000 00000010 00000000 00000017 00000000
  00000006 00000000 0000000A 00000000 0000000F 00000000 00000015 00000000
  00000006 00000000 0000000A 00000000 0000000F 00000000 00000015 00000000
  00000006 00000000 0000000A 00000000 0000000F 00000000 00000015 00000000
  00000006 00000000 0000000A 00000000 0000000F 00000000 00000015 00000000

  ' 64 x 8 byte values for 'k'
  D76AA478 00000000 E8C7B756 00000000 242070DB 00000000 C1BDCEEE 00000000
  F57C0FAF 00000000 4787C62A 00000000 A8304613 00000000 FD469501 00000000
  698098D8 00000000 8B44F7AF 00000000 FFFF5BB1 00000000 895CD7BE 00000000
  6B901122 00000000 FD987193 00000000 A679438E 00000000 49B40821 00000000
  F61E2562 00000000 C040B340 00000000 265E5A51 00000000 E9B6C7AA 00000000
  D62F105D 00000000 02441453 00000000 D8A1E681 00000000 E7D3FBC8 00000000
  21E1CDE6 00000000 C33707D6 00000000 F4D50D87 00000000 455A14ED 00000000
  A9E3E905 00000000 FCEFA3F8 00000000 676F02D9 00000000 8D2A4C8A 00000000
  FFFA3942 00000000 8771F681 00000000 6D9D6122 00000000 FDE5380C 00000000
  A4BEEA44 00000000 4BDECFA9 00000000 F6BB4B60 00000000 BEBFBC70 00000000
  289B7EC6 00000000 EAA127FA 00000000 D4EF3085 00000000 04881D05 00000000
  D9D4D039 00000000 E6DB99E5 00000000 1FA27CF8 00000000 C4AC5665 00000000
  F4292244 00000000 432AFF97 00000000 AB9423A7 00000000 FC93A039 00000000
  655B59C3 00000000 8F0CCC92 00000000 FFEFF47D 00000000 85845DD1 00000000
  6FA87E4F 00000000 FE2CE6E0 00000000 A3014314 00000000 4E0811A1 00000000
  F7537E82 00000000 BD3AF235 00000000 2AD7D2BB 00000000 EB86D391 00000000
End CSub

' @param  v%()  data to be interpreted as n% x 32-bit words
' @param  n%    length of data, in 32-bit words
' @param  k%()  128-bit key (16-bytes)
Function crypt.xxtea_encrypt%(v%(), n%, k%())
  Const DELTA% = &h9e3779b9 ' 4-bytes
  Const v_addr% = Peek(VarAddr v%())
  Const k_addr% = Peek(VarAddr k%())
  Local rounds% = 6 + 52 \ n%
  Local sum% = 0
  Local y% = 0
  Local z% = Peek(Word v_addr% + 4 * (n% - 1))
  Local e%, p%

  Do
    sum% = (sum% + DELTA%) And &hFFFFFFFF
    e% = (sum% >> 2) And 3
    For p% = 0 To n% - 2
      y% = Peek(Word v_addr% + 4 * (p% + 1))
      z% = (Peek(Word v_addr% + 4 * p%) + crypt.mx%(y%, z%, sum%, k_addr%, p%, e%)) And &hFFFFFFFF
      Poke Word v_addr% + 4 * p%, z%
    Next
    y% = Peek(Word v_addr%)
    z% = (Peek(Word v_addr% + 4 * (n% - 1)) + crypt.mx%(y%, z%, sum%, k_addr%, p%, e%)) And &hFFFFFFFF
    Poke Word v_addr% + 4 * (n% - 1), z%
    Inc rounds%, -1
  Loop While rounds%

  crypt.xxtea_encrypt% = 1
End Function

Function crypt.mx%(y%, z%, sum%, k_addr%, p%, e%)
  Local lhs% = (z% >> 5) Xor ((y% << 2) And &hFFFFFFFF)
  Inc lhs%, (y% >> 3) Xor ((z% << 4) And &hFFFFFFFF)
  Local rhs% = (sum% Xor y%) + (Peek(Word k_addr% + 4 * ((p% And 3) Xor e%)) Xor z%)
  crypt.mx% = (lhs% And &hFFFFFFFF) Xor (rhs% And &hFFFFFFFF)

'  Print Hex$(y%, 8) " ";
'  Print Hex$(z%, 8) " ";
'  Print Hex$((z% >> 5) Xor ((y% << 2) And &hFFFFFFFF), 8) " ";
'  Print Hex$((y% >> 3) Xor ((z% << 4) And &hFFFFFFFF), 8) " ";
'  Print Hex$(sum% Xor y%, 8) " ";
'  Print Hex$(Peek(Word k_addr% + 4 * ((p% And 3) Xor e%)) Xor z%, 8) " ";
'  Print Hex$(crypt.mx%, 8)
End Function

Function crypt.xxtea_decrypt%(v%(), n%, k%())
  Const DELTA% = &h9e3779b9 ' 4-bytes
  Const v_addr% = Peek(VarAddr v%())
  Const k_addr% = Peek(VarAddr k%())
  Local rounds% = 6 + 52 \ n%
  Local sum% = rounds% * DELTA%
  Local y% = Peek(Word v_addr%)
  Local z% = 0
  Local e%, p%

  Do
    e% = (sum% >> 2) And 3
    For p% = n% - 1 To 1 Step -1
      z% = Peek(Word v_addr% + 4 * (p% - 1))
      y% = (Peek(Word v_addr% + 4 * p%) - crypt.mx%(y%, z%, sum%, k_addr%, p%, e%)) And &hFFFFFFFF
      Poke Word v_addr% + 4 * p%, y%
    Next
    z% = Peek(Word v_addr% + 4 * (n% - 1))
    y% = (Peek(Word v_addr%) - crypt.mx%(y%, z%, sum%, k_addr%, p%, e%)) And &hFFFFFFFF
    Poke Word v_addr%, y%
    sum% = (sum% - DELTA%) And &hFFFFFFFF
    Inc rounds%, -1
  Loop While rounds%

  crypt.xxtea_decrypt% = 1
End Function
