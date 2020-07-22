# MMBasic Transpiler

A BASIC transcompiler and code-formatter for the [Colour Maximite 2](http://geoffg.net/maximite.html).

Features:
 * Flattens #Include hierarchies
     * useful for moving code from the CMM2 to other MMBasic flavours that currently do not support #Include.
 * Configurable code reformatting
     * automatic indentation.
     * remove empty-lines.
     * remove comments.
     * automatically "fix" spacing between tokens.
 * Conditional commenting/uncommenting of code sections
     * useful for supporting multiple MMBasic flavours from a single source-tree.
 * Configurable token replacement
     * currently only supports a 1 → 1 mapping.
     * useful for improve performance by inlining constants and shortening identifiers.

Written in MMBasic 5.05 by Thomas Hugo Williams in 2020

## How do I run it?

1. Download the latest release:
    - https://github.com/thwill1000/mmbasic-transpiler/releases/download/r1b1/mbt-r1b1.zip
    - or clone/download the latest work in progress: https://github.com/thwill1000/mmbasic-transpiler

2. Extract all the files to ```\mbt\```
    - to run from a different directory you need to edit the ```INSTALL_DIR$``` constant near the top of ```mbt.bas```.

3. Run `mbt` with:
    - ```RUN "\mbt\mbt.bas", [OPTION]... "input file" ["output file"]```

**Examples**
        
Use the program to transpile itself:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```RUN "\mbt\mbt.bas", "\mbt\src\mbt_cm2.mbt" "mbt_new.bas"```
 
Or to transpile Z-MIM (https://github.com/thwill1000/zmim):

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```RUN "\mbt\mbt.bas", "\zmim\src\zmim_cm2.mbt" "\zmim_new.bas"```

Or just reformat a file:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```RUN "\mbt\mbt.bas", -f --indent=2 --spacing=generous "old.bas" "new.bas"```

## Command-line options

* ```-C, --colour```
    * Use VT100 control codes to syntax highlight the output.
    * This should only be used when accessing the CMM2 via a VT100 compatible terminal.
    * It has no effect if outputting to a file.

* ```-e, --empty-lines=off|single```
    * Controls inclusion of empty lines in the transpiled output:<br/>
        * ```off``` (or 0) - do not include empty lines.<br/>
        * ```single``` (or 1) - include a single empty line before each Function/Sub, otherwise do not include any empty lines.
    * The default is to include all existing empty lines.

* ```-f, --format-only```
    * Only format the output, do not follow #Includes or process directives.
    * Useful if you just want to reformat the whitespace in a single file.

* ```-h, --help```
    * Displays basic help information, including a description of these options, and then exits.

* ```-i, --indent=<number>```
    * Automatically indent by \<number\> spaces per level, may be 0.
    * The default is to use the existing indentation.

* ```-n, --no-comments```
    * Do not include comments in the transpiled output.

* ```-s, --spacing=minimal|compact|generous```
    * Controls output of spacing between tokens, see the description of the ```'!spacing``` directive for details:
         * `minimal` (or 0)
         * `compact` (or 1)
         * `generous` (or 2)
    * The default is to use the existing spacing. 

* ```-v, --version```
    * Displays version information and then exits.

## Directives

Directives can be added to the MMBasic code to control the behaviour of the transpiler:
* They all begin ```'!``` with the leading single-quote meaning that the MMBasic interpreter will ignore them if the untranspiled code is ```RUN```.
* They must be the first token on a line.

### Directives that control formatting of transpiled code

*Where present these directives override any formatting specified in the command-line options.*

#### '!comments {on | off}

Controls the inclusion of comments in the transpiled output, e.g.

```
'!comments off
' This comment will not be included in the transpiled output,
' and nor will this one,
'!comments on
' but this one will be.
```

The default setting is ```on``` unless the ```--no-comments``` command-line option is used.

#### '!empty-lines {on | off | single}

Controls the inclusion of empty lines in the transpiled output:
* ```off``` - do not include empty lines.
* ```on``` - include existing empty lines.
* ```single``` - include a single empty line before each Function/Sub, otherwise do not include any empty lines.

The default setting is ```on``` unless the ```--empty-lines``` command-line option is used.

#### '!indent {on | \<number\>}

Controls the code indentation of the transpiled output:
* ```on``` - use existing indentation.
* ```<number>``` - indent by \<number\> spaces per level, may b 0 to use no indentation.

The default setting is ```on``` unless the ```--indent``` command-line option is used.

#### '!spacing {on | minimal | compact | generous}

Controls the spacing between tokens in the the transpiled output:
* ```on``` - use existing spacing.
* ```minimal``` - use the minimal spacing required for the code to be valid, e.g.
    ```TODO```
* ```compact``` - additional spacing, e.g.
    ```TODO```
* ```generous``` - even more spacing, e.g.
    ```TODO```

The default setting is ```on``` unless the ```--spacing``` command-line option is used.

### Directives that control conditional (un)commenting of code

#### !set \<flag\>

Sets \<flag\> for use with the ```'!comment_if``` and ```'!uncomment_if``` directives.

#### !clear \<flag\>

Clears \<flag\>.

#### !comment_if \<flag\>

If \<flag\> is set then the transpiler will comment out all the following lines until the next ```'!end_if```, e.g.
```vba
'!set foo
'!comment_if foo
Print "This line and those that follow it will be commented out,"
Print "including this one,"
'!endif
Print "but not this one."
```

#### !uncomment_if \<flag\>

If \<flag\> is set then the transpiler will remove **one** comment character from all the following lines until the next ```'!end_if```, e.g.
```vba
'!set foo
'!uncomment_if foo
'Print "This line and those that follow it will be uncommented,"
'Print "including this one,"
''Print "but this one will still have a single comment character,"
'!endif
'Print "and this one will not be affected."
```

#### '!endif

Ends a ```'!comment_if``` or ```'!uncomment_if``` block.

### Directives that control replacement of tokens

#### '!replace \<to\> \<from\>

Tells the transpiler to replace **one** token with another, e.g.

When transpiled this:
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

## Known Issues

 1. Does not recognise REM statements as being comments.
 2. Automatic indenting does not handle multiple statement lines correctly.
     * to be honest the auto-indent code is a "hive of scum an villainy" that I need to put under unit-test and rewrite.

## FAQ

**1. Why didn't you just copy the design of the C preprocessor like FreeBASIC does ?**

 1. The current design was chosen so that a file annotated with !directives is still a valid MMBasic file for at least one flavour of MMBasic (currently MMBasic 5.05 on the CMM2) that can be RUN without first running the transpiler over it.

 2. Because that would be a lot more work.

**2. When is it getting C preprocessor style macro support ?**

Not yet ;-)

**3. Will you be supporting the original Colour Maximite / Mono Maximite / Pi-cromite / MMBasic for DOS ?**

My next goal (after rewriting the auto-indent code) is to use the transpiler to help port itself to Pi-cromite and MMBasic for DOS.

I do not intend to support the original Colour Maximite or Mono Maximite as the MMBasic 4.5 that these run is missing a number of important features that the code relies on.

**4. What is the Colour Maximite 2 ?**

The Colour Maximite 2 is a small self contained "Boot to BASIC" computer inspired by the home computers of the early 80's such as the Tandy TRS-80, Commodore 64 and Apple II.

While the concept of the Colour Maximite 2 is borrowed from the computers of the 80's the technology used is very much up to date.  Its CPU is an ARM Cortex-M7 32-bit RISC processor running at 480MHz and it generates a VGA output at resolutions up to 800x600 pixels with up 65,536 colours.

The power of the ARM processor means it is capable of running BASIC at speeds comparable to running native machine-code on an 8-bit home computer with the additional advantage of vastly more memory and superior graphics and audio capabilities.

More information can be found on the official Colour Maximite 2 website at http://geoffg.net/maximite.html

**5. How do I contact the author ?**

The author can be contacted via:
 - https://github.com as user "thwill1000"
 - https://www.thebackshed.com/forum/index.php as user "thwill"

