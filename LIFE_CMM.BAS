' John Conway's Game of Life for Micromite MMBasic with TeraTerm
' Bill McKinley

Mode 3

GRAPHICS = 1 ' Set = 0 for Terminal mode, = 1 for Graphics

' NOTE: If you make the matrix too small the Glider demo will cause an error
' and the matrix will not overwrite some of the text on the screen
' Make it too big and it will not fit on the screen
' A ratio of 2 of x to 1 of y gives a better looking display
MatX = 40   ' Matrix horizontal size
MatY = 25   ' Matrix vertical size
RandL = 0.3 ' For the randomizing of life less than =< RandL means there is life
            ' Make it high and you get a lot of cells but they die quickly
PT = 000    ' Pause time in mS between display updates

If GRAPHICS Then DIAM = 480 / MatX : MatY = 35

' Zero based matrix has one more cell all round than is displayed
Dim CurM(MatX+1, MatY+1) ' The current matrix of life
Dim NewM(MatX+1, MatY+1) ' The next generation of life

ChkScr      ' Print intro
SetupTimer  ' Randomize by waiting for a keypress
ClrScr      ' Clear the screen (matrix area)
InitM       ' Initialize the random matrix (or demo)

Do          ' Program loop
  NextGen     ' Calculate the next generation
  NextGen2    ' Calculate the next generation
  'UpdateM     ' Update the matrix with the new generation
  Pause PT
Loop Until Inkey$ <> "" ' loop forever or until a keypres

Sub ChkScr ' Print intro
  ClrScr
  Print "   CONWAY'S GAME OF LIFE"
  Print
  Print "   Press a key to start"
  Print "   and another to stop"
  Print "   G for a glider demo"
End Sub

Sub SetupTimer ' Wait for a key press to start timer
  Do
    B$ = Inkey$
  Loop Until B$ <> ""
  Randomize Timer
End Sub

Sub ClrScr 'Clear the screen area
  If Not GRAPHICS Then Print Chr$(27) "[2J" Chr$(27) "[H" Else Cls
End Sub

Sub InitM ' Initialise the matrix of life
  If B$ = "g" Or b$ = "G" Then  'Set thr glider and target
    CurM(4, 7) = 1
    CurM(5, 7) = 1
    CurM(6, 7) = 1
    CurM(6, 6) = 1
    CurM(5, 5) = 1
    CurM(15, 15) = 1
    CurM(15, 16) = 1
    CurM(16, 15) = 1
    CurM(16, 16) = 1
  Else
    For y = 1 To MatY
      For x = 1 To MatX
        If Rnd() <= RandL Then
          CurM(x, y) = 1
        Else
          CurM(x, y) = 0
        EndIf
      Next x
      Print
    Next y
  EndIf
End Sub

Sub NextGen ' Breed the next generation into a new matrix
  If Not GRAPHICS Then Print Chr$(27) "[H"
  For y = 1 To MatY
    b = 0
    c = CurM(1, y - 1) + CurM(1, y) + CurM(1, y + 1)
    s$ = Space$(MatX)
    For x = 1 To MatX
      d = CurM(x + 1, y - 1) + CurM(x + 1, y) + CurM(x + 1, y + 1)
      adj = b + c + d
      If CurM(x, y) Then
        Poke Var s$, x, &h4f
        birth = NewM(x, y) = 0
        NewM(x, y) = (adj = 3) Or (adj = 4)
        If GRAPHICS Then
          If birth Then draw_cell(x, y, Yellow) Else draw_cell(x, y, Green)
        EndIf
      Else
        dying = adj <> 3 And NewM(x, y) = 1
        NewM(x, y) = (adj = 3)
        If GRAPHICS Then
          If dying Then draw_cell(x, y, Red) Else draw_cell(x, y, Black)
        EndIf
      EndIf
      b = c
      c = d
    Next x
    If Not GRAPHICS Then Print s$
  Next y
End Sub

Sub draw_cell(x, y, col)
  Circle((x - 0.5) * DIAM, (y - 0.5) * DIAM), DIAM/2 - 2, col, F
End Sub

Sub NextGen2 ' Breed the next generation into a new matrix
  If Not GRAPHICS Then Print Chr$(27) "[H"
  For y = 1 To MatY
    b = 0
    c = NewM(1, y - 1) + NewM(1, y) + NewM(1, y + 1)
    s$ = Space$(MatX)
    For x = 1 To MatX
      d = NewM(x + 1, y - 1) + NewM(x + 1, y) + NewM(x + 1, y + 1)
      adj = b + c + d
      If NewM(x, y) Then
        Poke Var s$, x, &h4f
        birth = CurM(x, y) = 0
        CurM(x, y) = (adj = 3) Or (adj = 4)
        If GRAPHICS Then
          If birth Then draw_cell(x, y, Yellow) Else draw_cell(x, y, Green)
        EndIf
      Else
        dying = adj <> 3 And CurM(x, y) = 1
        CurM(x, y) = (adj = 3)
        If GRAPHICS Then
          If dying Then draw_cell(x, y, Red) Else draw_cell(x, y, Black)
        EndIf
      EndIf
      b = c
      c = d
    Next x
    If Not GRAPHICS Then Print s$
  Next y
End Sub


