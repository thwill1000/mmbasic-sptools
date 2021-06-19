' Copyright (c) 2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1")  > 0

#Include "../src/splib/system.inc"
#Include "../src/splib/array.inc"
#Include "../src/splib/list.inc"
#Include "../src/splib/string.inc"
#Include "../src/splib/file.inc"
#Include "../src/splib/vt100.inc"
#Include "../src/sptest/unittest.inc"

Const BASE% = Mm.Info(Option Base)
Const RESOURCE_DIR$ = file.PROG_DIR$ + "/resources/tst_math"

add_test("test_fft")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

' Test MATH FFT against a file of known values and results.
Sub test_fft()
  Const size% = 1024
  Local signal!(array.new%(size%))
  Local expected_mag!(array.new%(size%))
  Local i% = 0, s$
  Open RESOURCE_DIR$ + "/fft.csv" For Input As #1
  Do While Not Eof(#1)
    Line Input #1, s$
    s$ = str.trim$(s$)
    If Left$(s$, 1) = "#" Then Continue Do ' Ignore comment lines.
    signal!(BASE% + i%) = Val(Field$(s$, 2, ","))
    expected_mag!(BASE% + i%) = Val(Field$(s$, 4, ",")) * (64/2)
    Inc i%
  Loop
  Close #1

  assert_int_equals(size%, i%)

  Dim fft!(array.new%(2), array.new%(size%))
  Math FFT signal!(), fft!()

  Local actual!, x!, y!
  For i% = 0 To size% - 1
    x! = fft!(BASE%, BASE% + i%)
    y! = fft!(BASE% + 1, BASE% + i%)
    actual! = Sqr(x! * x! + y! * y!)
    assert_float_equals(expected_mag!(BASE% + i%), actual!, 1e-6)
  Next

End Sub

