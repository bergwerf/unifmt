unifmt
======
[![Pub Package](https://img.shields.io/pub/v/unifmt.svg)](https://pub.dartlang.org/packages/unifmt)

The universal code formatter for the MolView project. This program automatically
formats all code in the current directory to match the style conventions. You
can find out which conventions are used by looking at the source code of this
tool. It will automatically alert you if you have to install a formatter on your
system.

Getting started
---------------
### Install
To install `unifmt` on your system, run:
```
pub global activate unifmt
```

### Command line arguments
#### -h, --[no-]help
Displays usage information.

#### -v, --[no-]verbose
Output non-critical formatting messages.

#### -f, --[no-]force
Ignore errors in run-once mode (i.e. --no-watch).

#### -w, --[no-]watch
Watch current directory for changes and reformat them.

#### -e, --exclude
Exclude the given file globs.

#### -c, --copyright
Set copyright holder for license headers.

#### -l, --license
Set SPDX license ID for license headers.

Notes
-----
### Gitignore
`unifmt` parses the `.gitignore` file in the directory where it is executed
and does not format files that are excluded in the `.gitignore` file. However,
`.gitignore` files that are located in subdirectories are not parsed!
