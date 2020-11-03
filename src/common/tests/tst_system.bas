:' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../error.inc"
#Include "../file.inc"
#Include "../list.inc"
#Include "../set.inc"
#Include "../system.inc"
#Include "../../sptest/unittest.inc"

add_test("test_firmware_version")
add_test("test_pseudo")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Function test_firmware_version()
  assert_equals(50605, sys.firmware_version%("5.06.05"))
  assert_equals(50600, sys.firmware_version%("5.06"))
'  assert_equals(50506, sys.firmware_version%())
  assert_equals(12345678, sys.firmware_version%("12.34.5.678"))
End Function

Function test_pseudo()
  Local x% = sys.pseudo%(-7) ' seed the random number generator.

  ' Assert that first 10 generated values are as expected.
  Local i%
  Local expected%(9) = (6,4,4,7,10,2,10,10,3,4)
  For i% = 0 To 9
    assert_equals(expected%(i%), sys.pseudo%(10))
  Next

  ' Assert that calling the function 1000 times generates each number 1..10 at least once.
  Local count%(10)
  For i% = 1 To 1000
    x% = sys.pseudo%(10)
    count%(x%) = count%(x%) + 1
  Next

  assert_equals(0, count%(0))
  For i% = 1 To 10
    assert_equals(1, count%(i%) > 0)
  Next
End Function
