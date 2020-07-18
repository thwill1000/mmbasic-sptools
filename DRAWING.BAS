
Mode 4
Cls
home
color = 7

start:
box
border
c$ = Inkey$
If c$ = "1" Then
  color = 0
ElseIf c$ = "2" Then
  color = 1
ElseIf c$ = "3" Then
  color = 2
ElseIf c$ = "4" Then
  color = 3
ElseIf c$ = "5" Then
  color = 4
ElseIf c$ = "6" Then
  color = 5
ElseIf c$ = "7" Then
  color = 6
ElseIf c$ = "8" Then
  color = 7
ElseIf c$ = "a" And y > 0 Then
  box
  y = y - 5
ElseIf c$ = "z" And y < 216 Then
  box
  y = y + 5
ElseIf c$ = "n" And x > 0 Then
  box
  x = x - 5
ElseIf c$ = "m" And x < 240 Then
  box
  x = x + 5
ElseIf c$ = " " Then
  box
  x = 240 / 2
  y = 216 / 2
ElseIf c$ = "f" Then
  Cls
  home
EndIf
GoTo start

Sub home
  x = 240 / 2
  y = 216 / 2
End Sub

Sub box
  Line (x,y) - (x+5,y+5), color, bf
End Sub

Sub border
  Line (x,y) - (x+5,y+5), 7, b
End Sub
