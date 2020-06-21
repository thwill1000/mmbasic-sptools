' Copyright (c) 2020 Thomas Hugo Williams
' For Maximite BASIC v4.5C

' LED "Snake" game.

Library Load "matrix.lib"
Library Load "text.lib"

demo = 0
diff = 4

USE_M7219 = 1
UP = 1 : RIGHT = 2 : DOWN = 3 : LEFT = 4
SELECT = 10 : START = 20 : DEMO_CMD = 30

Mode 2, 3
Cls

Print "SNAKE - Tom Williams 2020"
Print "Cursor keys to move"
Print "S to START"
Print "D to SELECT difficulty"
Print "E to start DEMO"

text_init()

If USE_M7219 Then m7219_init(16, 16) Else matrix_init()

SNAKE_SZ = matrix_w * matrix_h
Dim snake(snake_sz - 1, 1)

If USE_M7219 Then SetTick 200, m7219_draw Else SetTick 2, matrix_draw

On Key on_key

main_loop()
End

Sub main_loop()
  Do
    matrix_clear()
    game_intro()
    game_init()
    SetTick 0, 0
    game_loop()
    SetTick 100, m7219_draw
    die()
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

  For i = 0 To SNAKE_SZ - 1
    snake(i, 0) = 0
    snake(i, 1) = 0
  Next i
  head = 1
  tail = 0
  snake(head, 0) = (matrix_w \ 2) - 1
  snake(head, 1) = (matrix_h \ 2) - 1
  matrix_set(snake(head, 0), snake(head, 1), 1)
  snake(tail, 0) = snake(head, 0)
  snake(tail, 1) = snake(head, 1) + 1
  matrix_set(snake(tail, 0), snake(tail, 1), 1)
  dir = UP
  pill_x = -1 : pill_y = -1
  score = 0
  cmd = 0
  place_pill()
End Sub

Sub game_loop()2
  Local x, y

  Do
    Pause (5 - diff) * 50

    If demo Then
      If cmd <> 0 Then Exit Sub
      demo_ai()
    ElseIf cmd <> 0 And cmd < 10 Then
      dir = cmd
    EndIf
    cmd = 0

    If will_die() Then Exit Sub
    x = snake(head, 0)
    y = snake(head, 1)
    snake_move(x, y)
    head = (head + 1) Mod SNAKE_SZ
    snake(head, 0) = x
    snake(head, 1) = y
    matrix_set(x, y, 1)

    If x = pill_x And y = pill_y Then
      score = score + 1
      pill_x = -5 : pill_y = -5
    Else
      matrix_set(snake(tail, 0), snake(tail, 1), 0)
      tail = (tail + 1) Mod SNAKE_SZ
    EndIf

    If pill_x = -1 Then place_pill()
    If pill_x < -1 Then pill_x = pill_x + 1

    m7219_draw()
  Loop

End Sub

Sub snake_move(x, y)
  If dir = UP Then
    y = y - 1
  ElseIf dir = DOWN Then
    y = y + 1
  ElseIf dir = LEFT Then
    x = x - 1
  ElseIf dir = RIGHT Then
    x = x + 1
  EndIf
End Sub

Sub demo_ai()
  Local x, y

  x = snake(head, 0)
  y = snake(head, 1)

  If pill_x > -1 Then
    If y = pill_y Then
      If x > pill_x Then dir = LEFT
      If x < pill_x Then dir = RIGHT
    ElseIf x = pill_x Then
      If y > pill_y Then dir = UP
      If y < pill_y Then dir = DOWN
    ElseIf pill_y < y Then
      dir = UP
    Else
      dir = DOWN
    EndIf
  EndIf

  If Not will_die() Then Exit Sub
  If (y > matrix_h \ 2) Then dir = UP Else dir = DOWN
  If Not will_die() Then Exit Sub
  If (x > matrix_w \ 2) Then dir = LEFT Else dir = RIGHT
  If Not will_die() Then Exit Sub
  If (y > matrix_h \ 2) Then dir = DOWN Else dir = UP
  If Not will_die() Then Exit Sub
  If (x > matrix_w \ 2) Then dir = RIGHT Else dir = LEFT
End Sub

Function will_die()
  Local x, y

  x = snake(head, 0)
  y = snake(head, 1)
  snake_move(x, y)

  If y < 0 Or y >= matrix_h Or x < 0 Or x >= matrix_w Then
    will_die = 1
  ElseIf matrix_get(x, y) And Not (x = pill_x And y = pill_y) Then
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
  pill_x = Int(Rnd() * matrix_w)
  pill_y = Int(Rnd() * matrix_h)
  If matrix_get(pill_x, pill_y) = 0 Then
    matrix_set(pill_x, pill_y, 1)
  Else
    pill_x = -1 : pill_y = -1
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
