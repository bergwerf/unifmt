#!/bin/bash

# This is a very minimal test.
# TODO: Cover more use cases and validate output.

# Descend to where the script location.
cd "$(dirname "$0")"

# Run molviewfmt for tmpdata.
echo "##########"
echo "Silent run"
echo "##########"
dart ../bin/molviewfmt.dart
echo "###########"
echo "Verbose run"
echo "###########"
dart ../bin/molviewfmt.dart --verbose
