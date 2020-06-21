' Copyright (c) 2020 Thomas Hugo Williams
' For Maximite BASIC v4.5C

' LED "Snake" game.

Library Load "matrix.lib"
Library Load "text.lib"

Dim snake(63)
demo = 0
diff = 1

UP = -8 : RIGHT = 1 : DOWN = 8 : LEFT = -1
SELECT = 10 : START = 20 : DEMO_CMD = 30

Mode 2, 3
Cls

Print "SNAKE - Tom Williams 2020"
Print "Cursor keys to move"
Print "S to START"
Print "D to SELECT difficulty"
Print "E to start DEMO"

text_init()

USE_M7219 = 1

If USE_M7219 Then
  m7219_init(8, 32)
  SetTick 100, m7219_draw
Else
  matrix_init()
  SetTick 2, matrix_draw
EndIf

On Key on_key

main_loop()
End

Sub main_loop()
  Do
    matrix_clear()
    game_intro()
    game_init()
    game_loop()
  Loop
End Sub

Sub game_intro()
  Local s$

  s$ = "SNAKE-Tom Williams 2020-SELECT to increase difficulty"

  Do
    If cmd = SELECT Then
      diff = 1 + diff Mod 4
      text_scroll(Str$(diff))
    Else
      text_scroll(s$)
      If cmd = 0 Then cmd = DEMO_CMD
    EndIf
  Loop Until cmd <> 0 And cmd <> SELECT
  demo = (cmd = DEMO_CMD)
End Sub

Sub game_init()
  Local i

  For i = 0 To 63: snake(i) = 0 : Next i
  snake(0) = 35
  head = 0
  tail = 0
  dir = UP
  pill = 0
  score = 0
  cmd = 0
  matrix_set(snake(head) Mod 8, snake(head) \ 8, 1)
  place_pill()
End Sub

Sub game_loop()
  Local p

  Do
    Pause (5 - diff) * 50

    If demo Then
      If cmd <> 0 Then Exit Sub
      demo_ai()
    ElseIf cmd <> 0 And cmd < 10 Then
      dir = cmd
    EndIf
    cmd = 0

    If will_die() Then die() : Exit Sub

    p = snake(head) + dir
    head = (head + 1) Mod 64
    snake(head) = p
    matrix_set(p Mod 8, p \ 8, 1)

    If p <> pill Then
      matrix_set(snake(tail) Mod 8, snake(tail) \ 8, 0)
      tail = (tail + 1) Mod 64
    Else
      score = score + 1
      pill = -5
    EndIf

    If pill = -1 Then place_pill()
    If pill < -1 Then pill = pill + 1
  Loop

End Sub

Sub demo_ai()
  Local c, p, r

  p = snake(head)
  c = p Mod 8
  r = p \ 8

  If r = pill \ 8 Then
    If pill < p Then dir = LEFT
    If pill > p Then dir = RIGHT
  ElseIf c = pill Mod 8 Then
    If pill < p Then dir = UP
    If pill > p Then dir = DOWN
  ElseIf pill < p Then
    dir = UP
  Else
    dir = down
  EndIf

  If will_die() Then If (r > 3) Then dir = UP Else dir = DOWN
  If will_die() Then If (c > 3) Then dir = LEFT Else dir = RIGHT
  If will_die() Then If (r > 3) Then dir = DOWN Else dir = UP
  If will_die() Then If (c > 3) Then dir = RIGHT Else dir = LEFT

End Sub

Function will_die()
  Local p

  p = snake(head)

  If dir = UP And p < 8 Then
     will_die = 1
  ElseIf dir = DOWN And p > 55 Then
     will_die = 1
  ElseIf dir = LEFT And p Mod 8 = 0 Then
     will_die = 1
  ElseIf dir = RIGHT And p Mod 8 = 7 Then
     will_die = 1
  ElseIf matrix_get((p + dir) Mod 8, (p + dir) \ 8) And (p + dir) <> pill Then
     will_die = 1
  EndIf

End Function

Sub die()
  Local i, j
  For i = 1 To 4
    matrix_fill()
    Pause 300
    matrix_clear()
    Pause 300
  Next i
  text_scroll("GAME OVER Score:" + Str$(score))
End Sub

Sub place_pill()
  pill = Int(Rnd() * 64)
  If matrix_get(pill Mod 8, pill \ 8) = 0 Then
    matrix_set(pill Mod 8, pill \ 8, 1)
  Else
    pill = -1
  EndIf
End Sub

Sub on_key()
  Local k

  k = KeyDown

  If k = &h64 Then
    cmd = SELECT
  ElseIf k = &h65 Then
    cmd = DEMO_CMD
  ElseIf k = &h73 Then
    cmd = START
  ElseIf k = &h80 Then
    cmd = UP
  ElseIf k = &h81 Then
    cmd = DOWN
  ElseIf k = &h82 Then
    cmd = LEFT
  ElseIf k = &h83 Then
    cmd = RIGHT
  EndIf
End Sub
