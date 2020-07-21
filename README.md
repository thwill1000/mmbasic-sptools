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

