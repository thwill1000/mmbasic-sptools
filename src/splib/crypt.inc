' Copyright (c) 2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

' Implementation of the Tiny Encryption Algorithm,
' specifically the XXTEA variant.

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.provides("crypt")
If sys.err$ <> "" Then Error sys.err$

Function crypt.encrypt%(fd%, passwd$)
End Function

Function crypt.decrypt%(fd%, passwd$)
End Function

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
