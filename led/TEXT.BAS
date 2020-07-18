' Copyright (c) 2020 Thomas Hugo Williams
' For Maximite BASIC v4.5C

' LED scrolling text demo.

Library Load "matrix.lib"
Library Load "text.lib"

Cls
m7219_init(8,8)
text_init()
SetTick 50, m7219_draw
s$ = MM.CmdLine$
If Len(s$) = 0 Then Line Input "Message: ", s$
text_scroll(s$)
End
