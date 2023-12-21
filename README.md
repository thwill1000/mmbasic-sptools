# SP Tools

Development tools for MMBasic running on the [Colour Maximite 2](http://geoffg.net/maximite.html).

Written for MMBasic 5.07 / MMB4L 0.6.0 by Thomas Hugo Williams in 2020-2023.

SP Tools is distributed for free subject to the [LICENSE](LICENSE), but if you use it then perhaps you would like to buy me a coffee?

<a href="https://www.buymeacoffee.com/thwill"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="width:217px;"></a>

## Contents

1. Installation
2. ```spflow``` - Function/Subroutine dependency generator<br>
 2.1. Features<br>
 2.2. Usage<br>
 2.3. Command-line options<br>
 2.4. Known issues
3. ```sptrans```- MMBasic pre-processor and code-formatter.<br>
 See [src/sptrans/README.md](src/sptrans/README.md)
4. ```sptest``` - Unit-test framework<br>
 4.1. Features<br>
 4.2. Usage<br>
 4.3. Command-line options<br>
 4.4. Known issues
5. FAQ<br>
 5.1. General

## 1. Installation

1. Download the latest release:
    - https://github.com/thwill1000/mmbasic-sptools/releases/download/r1b2/sptools-r1b2.zip
    - or clone/download the latest work in progress: https://github.com/thwill1000/mmbasic-sptools

2. Extract all the files to ```/sptools/```
    - if you install in a different directory then you need to edit the value of ```SPT_INSTALL_DIR$``` in ```/src/common/sptools.inc```.

<div style="page-break-after: always;"></div>

## 2. ```spflow``` - Function/subroutine dependency generator

### 2.1. Features

```spflow``` analyses an MMBasic ".bas" file and its ".inc" dependencies and prints a graph, charting control flow within the program; it tries to emulate the behaviour of [GNU cflow](https://www.gnu.org/software/cflow).

e.g. Given these files:

**foo.inc:**
```
Sub foo()
  foo()
End Sub
```

**example.bas:**
```
#Include "foo.inc"

Sub bar()
  foo
End Sub

bar()
foo()
```

Then ```spflow``` outputs:
```
> RUN "/sptools/spflow.bas", "example.bas"
Generating MMBasic flowgraph from 'example.bas' ...

PASS 1
example.bas
  foo.inc

PASS 2
example.bas
  foo.inc

    1 *GLOBAL* <example.bas:1>
    2   bar() <example.bas:3>
    3     foo() <foo.inc:1>
    4       foo() <foo.inc:1> [recursive, see 3]
    5   foo() <foo.inc:1>
    6     foo() <foo.inc:1> [recursive, see 5]

Time taken = 0.3 s
```

<div style="page-break-after: always;"></div>

### 2.2. Usage

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```RUN "/sptools/spflow.bas", [OPTION]... "input file" ["output file"]```

### 2.3. Command-line options

* ```-A, --all```
    * Produce graphs for all functions/subroutines, even those unreachable from the global scope.

* ```-b, --brief```
    * Output the expanded subgraph for each subroutine only once, subsequent calls reference the output line containing the original expansion.

* ```-h, --help```
    * Display basic help information, including a description of these options, and then exit.

* ```--no-location```
    * Omit filenames and line numbers for each function/subroutine declaration from the output.

* ```-v, --version```
    * Display version information and then exit.

### 2.4. Known issues

1. ```spflow``` cannot determine that an identifier refers to a function/subroutine (and thus include calls to it in its output) unless it finds a corresponding ```Function id``` or ```Sub id``` declaration. This is different to ```cflow``` where C functions calls can be recognised uniquely by their syntax, whereas MMBasic function calls are syntactically indistinguishable from array variable access.
    * this limitation makes running ```spflow``` on a ".inc" file of dubious utility.

<div style="page-break-after: always;"></div>

## 3. ```sptrans``` - Transpiler and code-formatter

See [src/sptrans/README.md](src/sptrans/README.md)

<div style="page-break-after: always;"></div>

## 4. ```sptest``` -  Unit-test framework

### 4.1. Features

Implements rudimentary [xUnit](https://en.wikipedia.org/wiki/XUnit) style unit-testing for MMBasic.

See the contents of ```/sptools/src/sptest/common/tests``` to see it being used in practice.

### 4.2. Usage

Run all the ```tst_*.bas``` files in the ```tests/``` sub-directory of the current working-directory:

&nbsp;&nbsp;&nbsp;&nbsp;```RUN "/sptools/sptest.bas"```

Notes:
1. If ```tests/``` does not exist then this will run all the ```tst*.bas``` files in the current working-directory.
2. Relies on each ```tst_*.bas``` file calling ```run_tests()``` as this is what chains the file execution together.

### 4.3. Command-line options

The ```sptest``` program current has no command-line options or arguments.

### 4.4. Known issues

1. The routines in ```unittest.inc``` and the other code it depends on in ```src\common``` all currently require the code being tested to use ```Option Base 0``` for arrays.

<div style="page-break-after: always;"></div>

## 5. FAQ

### 5.1 General

#### 5.1.1 Will you be supporting the original Colour Maximite / Mono Maximite / Pi-cromite / MMBasic for DOS ?

I do not intend to support the original Colour Maximite or Mono Maximite as the MMBasic 4.5 that these run is missing a number of important features that the code relies on. It is also questionable whether they have sufficient memory to run ```spflow``` which uses significant in-memory data-structures.

Pi-cromite and MMBasic for DOS ports are in theory possible, especially if their respective MMBasic implementations get some of the CMM2 updates, however I do not currently have the time to work on them, please feel free to contribute your own changes ;-)

#### 5.1.2 What is the Colour Maximite 2 ?

The Colour Maximite 2 is a small self contained "Boot to BASIC" computer inspired by the home computers of the early 80's such as the Tandy TRS-80, Commodore 64 and Apple II.

While the concept of the Colour Maximite 2 is borrowed from the computers of the 80's the technology used is very much up to date.  Its CPU is an ARM Cortex-M7 32-bit RISC processor running at 480MHz and it generates a VGA output at resolutions up to 800x600 pixels with up to 65,536 colours.

The power of the ARM processor means it is capable of running BASIC at speeds comparable to running native machine-code on an 8-bit home computer with the additional advantage of vastly more memory and superior graphics and audio capabilities.

More information can be found on the official Colour Maximite 2 website at http://geoffg.net/maximite.html

#### 5.1.3 How do I contact the author ?

The author can be contacted via:
 - https://github.com as user "thwill1000"
 - https://www.thebackshed.com/forum/index.php as user "thwill"
