# sptrans

MMBasic pre-processor and code-formatter.

Written for MMBasic 5.07 and MMB4L 0.6.0 by Thomas Hugo Williams in 2020-2023.

**sptrans** is distributed for free subject to the [LICENSE](../../LICENSE), but if you use it then perhaps you would like to buy me a coffee?

<a href="https://www.buymeacoffee.com/thwill"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="width:217px;"></a>

## Contents

1. Features<br>
2. Usage<br>
3. Command-line options<br>
4. Pre-processor directives<br>
5. Known issues<br>
6. FAQ

## 1. Features

* Flattens ```#Include``` hierarchies
    * useful for moving code from MMBasic flavours that do support ```#Include``` (MMBasic for Windows, MMB4L, Colour Maximite 2) to other MMBasic flavours that currently do not support ```#Include```, e.g. PicoMite.
    * supports multiple levels of ```#Include``` and does not require the files to have ".inc" file-extension
        * MMBasic for Windows, MMB4L and the Colour Maximite 2 only support a single level of ```#Include```, i.e. a ".bas" file can ```#Include``` one or more ".inc" files and that's it.
* Configurable code reformatting
    * automatic indentation.
    * automatic update of spacing between tokens.
    * remove comments.
    * remove empty-lines.
* Conditional commenting, uncommenting, inclusion and exclusion of code sections
    * useful for supporting multiple MMBasic flavours from a single source-tree.
* Configurable token replacement
    * useful for inlining constants, shortening identifiers and transpiling between basic flavours.
    * many to many replacements with limited pattern matching.
* Tree-shaking
    * automatically remove Functions/Subs that are unused.
* Generates lists of identifiers, Functions/Subs, references and orphan Functions/Subs
    * useful for debugging, documentation and control flow analysis.

## 2. Usage

&nbsp;&nbsp;&nbsp;&nbsp;Use sptrans to pre-process itself:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```RUN "/sptools/sptrans.bas", "/sptools/src/sptrans/main.bas" "out.bas"```

&nbsp;&nbsp;&nbsp;&nbsp;Or pre-process [Z-MIM](https://github.com/thwill1000/zmim):

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```RUN "/sptools/sptrans.bas", "/zmim/src/zmim_cm2.mbt" "/zmim_new.bas"```

&nbsp;&nbsp;&nbsp;&nbsp;Or just reformat a file:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```RUN "/sptools/sptrans.bas", -f --indent=2 --spacing=generous "in.bas" "out.bas"```

## 3. Command-line options

* ```-C, --colour```
    * Use VT100 control codes to syntax highlight the output.
    * This should only be used when accessing the CMM2 via a VT100 compatible terminal, otherwise you see the control codes verbatim.
    * It has no effect when an output file is specified.

* ```--crunch```
    * Equivalent to ```--empty-lines=0 --indent=0 --no-comments --spacing=0```.

* ```-D<id>```
    *  Define ```<id>``` for interrogation by the ```!if```, ```!elif```, ```!ifdef```, ```!ifndef```, ```!comment_if``` and ```!uncomment_if``` directives.
    *  Equivalent to having the ```!define <id>``` directive at the start of a program.

* ```-e, --empty-lines=off|single```
    * Control inclusion of empty lines in the pre-processed output:<br/>
        * ```off``` (or 0) - do not include empty lines.<br/>
        * ```single``` (or 1) - include a single empty line before each Function/Sub, otherwise do not include any empty lines.
    * The default is to include all existing empty lines.

* ```-f, --format-only```
    * Only format the output, do not follow ```#Include``` or process directives.
    * Useful if you just want to reformat the whitespace in a single file.

* ```-h, --help```
    * Display basic help information, including a description of these options, and then exit.

* ```-i, --indent=<number>```
    * Automatically indent by ```<number>``` spaces per level, may be 0.
    * The default is to use the existing indentation.

* ```-I, --include-only```
    * Process ```#Include``` and formatting options from the command-line, do not process directives.

* ```-k, --keyword=l|p|u```
    * Update keyword capitalisation:
         * ```l``` - lowercase"
         * ```p``` - PascalCase"
         * ```u``` - UPPERCASE

* ```-L, --list-all```
    * Output files containing lists of the identifiers, Functions/Subs, references and orphan (unreferenced) Functions/Subs in the processed program.

* ```-n, --no-comments```
    * Do not include comments in the pre-processed output.

* ```-q, --quiet```
    * Write no output to the console except on an error.

* ```-s, --spacing=minimal|compact|generous```
    * Control output of spacing between tokens, see the description of the ```!spacing``` directive for details:
         * `minimal` (or 0)
         * `compact` (or 1)
         * `generous` (or 2)
    * The default is to use the existing spacing. 

* ```-T, --tree-shake```
    * Remove unused Functions/Subs from the processed program.
    * Note that if a program contains Functions/Subs that are only called via ```CALL``` then the ```!dynamic_call <function name>``` directive must be used to prevent them from being removed.

* ```-v, --version```
    * Display version information and then exit.

<div style="page-break-after: always;"></div>

## 4. Pre-processor directives

Directives can be added to the MMBasic code to control the behaviour of the pre-processor:
* They all begin ```'!``` with the leading single-quote meaning that the MMBasic interpreter will ignore them if the unprocessed code is ```RUN```.
* They must be the first token on a line.

### 4.1. Directives that control formatting

*Where present these directives override any formatting specified by the command-line options.*

#### '!comments {on | off}

Controls the inclusion of comments in the pre-processor output, e.g.

```
'!comments off
' This comment will not be included in the pre-processor output,
' and nor will this one,
'!comments on
' but this one will be.
```

The default setting is ```on``` unless the ```--no-comments``` command-line option is used.

#### '!empty-lines {on | off | single}

Controls the inclusion of empty lines in the pre-processor output:
* ```off``` - do not include empty lines.
* ```on``` - include existing empty lines.
* ```single``` - include a single empty line before each Function/Sub, otherwise do not include any empty lines.

e.g. ```'!empty-lines single```

The default setting is ```on``` unless the ```--empty-lines``` command-line option is used.

#### '!indent {on | \<number\>}

Controls the code indentation of the pre-processor output:
* ```on``` - use existing indentation.
* ```<number>``` - indent by ```<number>``` spaces per level, use 0 for no indentation.

e.g. ```'!indent 2```

The default setting is ```on``` unless the ```--indent``` command-line option is used.

#### '!spacing {on | minimal | compact | generous}

Controls the spacing between tokens in the the pre-processor output:
* ```on``` - use existing spacing.
* ```minimal``` - use the minimal spacing required for the code to be valid, e.g.
    ```vba
    If Left$(s$,1)="B"Then
      st=-1:br=de_branch()' comment
    EndIf
    ```
* ```compact``` - additional spacing, e.g.
    ```vba
    If Left$(s$,1)="B" Then
      st=-1 : br=de_branch() ' comment
    EndIf
    ```
* ```generous``` - even more spacing, e.g.
    ```vba
    If Left$(s$, 1) = "B" Then
      st = -1 : br = de_branch() 'comment
    EndIf
    ```

e.g. ```'!spacing compact```

The default setting is ```on``` unless the ```--spacing``` command-line option is used.

### 4.2. Directives that control conditional (un)commenting of code

#### !define \<id\>

Defines \<id\> for use with the ```'!comment_if``` and ```'!uncomment_if``` directives.

e.g. ```'!define foo```

#### !comment_if \<id\>

If \<id\> is defined then the pre-processor will comment out all the following lines until the next ```'!end_if```, e.g.
```vba
'!define foo
'!comment_if foo
Print "This line and those that follow it will be commented out,"
Print "including this one,"
'!endif
Print "but not this one."
```

#### '!elif

TODO

#### '!endif

Ends a ```'!comment_if``` or ```'!uncomment_if``` block.

e.g. ```'!endif```

#### !if \<expression\>

TODO

#### !ifdef \<expression\>

TODO

#### !ifndef \<expression\>

TODO

#### !uncomment_if \<id\>

If \<id\> is defined then the pre-processor will remove **one** comment character from all the following lines until the next ```'!end_if```, e.g.
```vba
'!define foo
'!uncomment_if foo
'Print "This line and those that follow it will be uncommented,"
'Print "including this one,"
''Print "but this one will still have a single comment character,"
'!endif
'Print "and this one will not be affected."
```

#### !undef \<id\>

Undefines \<id\>.

e.g. ```'!undef foo```

### 4.3. Directives that control replacement of tokens

#### '!replace \<to\> \<from\>

Tells the pre-processor to replace **one** token with another, e.g.

When pre-processed this:
```vba
'!replace apple pear
'!replace banana 30
'!replace "Hello, world!" "Goodbye, world!"
Dim apple = banana
Print "Hello, world!"
```

Will become this:
```vba
Dim pear = 30
Print "Goodbye, world!"
```
#### '!unreplace

TODO

### 4.4 Miscellaneous directives

#### '!dynamic_call \<function name\>

TODO

#### '!error "\<message\>"

TODO

#### '!info defined \<id\>

TODO

## 5. Known issues

1. Automatic indenting does not handle multiple statement lines correctly.
    * If I am honest the auto-indent code is a "hive of scum and villainy" that I need to put under unit-test and rewrite.

## 6. FAQ

### 6.1 Why didn't you just copy the design of the C preprocessor like FreeBASIC does ?

 1. The current design was chosen so that a file annotated with !directives is still a valid MMBasic file for MMBasic for Windows, MMB4L and the Colour Maximite 2 that can be ```RUN``` without first running the pre-processor over it.

 2. Because that would be a lot more work.

### 6.2. When is it getting C preprocessor style macro support ?

Not yet ;-)
