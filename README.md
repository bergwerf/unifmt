molviewfmt
==========
[![Pub Package](https://img.shields.io/pub/v/molviewfmt.svg)](https://pub.dartlang.org/packages/molviewfmt)
[![Build Status](https://travis-ci.org/molview/molviewfmt.svg?branch=dev)](https://travis-ci.org/molview/molviewfmt/)

The universal code formatter for the MolView project. This program automatically
formats all code in the current directory to match the style conventions. You
can find out which conventions are used by looking at the source code of this
tool. It will automatically alert you if you have to install a formatter on your
system.

Getting started
---------------
### Install
To install `molviewfmt` on your system, run:
```
pub global activate molviewfmt
```

### Run
To format all underlying files, run:
```
molviewfmt
```

To watch all underlying files for changes, run:
```
molviewfmt --watch
```

To get more output (info, warnings) when running `molviewfmt`, add the
`--verbose` flag.

Notes
-----
### Gitignore
`molviewfmt` parses the `.gitignore` file in the directory where it is executed
and does not format files that are excluded in the `.gitignore` file. However,
`.gitignore` files that are located in subdirectories are not parsed!
