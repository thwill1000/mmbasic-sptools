'!comments on
'!define foo

'!comment_if foo
Print "Should be commented"
'!endif

'!comment_if FOO
Print "Should be commented"
'!endif

'!comment_if Not bar
Print "Should be commented"
'!endif

'!comment_if Not BAR
Print "Should be commented"
'!endif

'!uncomment_if foo
'Print "Should be uncommented"
'!endif

'!uncomment_if FOO
'Print "Should be uncommented"
'!endif

'!uncomment_if Not bar
'Print "Should be uncommented"
'!endif

'!uncomment_if Not BAR
'Print "Should be uncommented"
'!endif

