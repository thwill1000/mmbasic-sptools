' Copyright (c) 2020 Thomas Hugo Williams
' For Maximite BASIC v4.5C

' LED matrix display editor.

Library Load "matrix.lib"

Mode 2,3
Cls

matrix_init()
draw_screen()

Print @(300,45) "Cursor keys to move"
Print @(300,60) "Space Bar to set/unset LED"
Print @(300,75) "'C' to clear matrix"

SetTick 2, matrix_draw
On Key on_key

p = 0 : curs = White

Do
  If curs = White Then
    draw_led(p, 1, curs)
    curs = Red
  Else
    draw_led(p, matrix_get(p), curs)
    curs = White
  EndIf
  Pause 300
Loop

Sub draw_screen()
  Local p
  For p = 0 To 63
    draw_led(p, matrix_get(p), Red)
  Next p
End Sub

Sub draw_led(p, on, color)
  Local x, y
  x = (p Mod 8 + 1) * 40 * 0.833
  y = (p \ 8 + 1) * 40
  If on Then
    Circle(x, y), 16, color, 0.833, F
  Else
    Line (x - 16, y - 16) - (x + 16, y + 16), Black, BF
    Circle(x, y), 16, color, 0.833
  EndIf
End Sub

Sub on_key
  Local k, x

  k = KeyDown

  If k >= &h80 And k <= &h83 Then
    draw_led(p, matrix_get(p), Red)
    If k = &h80 And ((p \ 8) > 0)   Then p = p - 8
    If k = &h81 And ((p \ 8) < 7)   Then p = p + 8
    If k = &h82 And ((p Mod 8) > 0) Then p = p - 1
    If k = &h83 And ((p Mod 8) < 7) Then p = p + 1
    curs = White

  ElseIf k = 32 Then
    x = Not matrix_get(p)
    matrix_set(p, x)

  ElseIf k = 99 Then
    matrix_clear()
    draw_screen()

  EndIf

End Sub

