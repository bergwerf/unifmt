#!/bin/bash

# Copyright (c) 2015, Herman Bergwerf. All rights reserved.
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file.

# Notes about the things that are tested are spread trough this bash script.
# Some additional notes are below.
# - empty.css and hello.js contain a wrong copyright holder to test if this is
#   the correct copyright holder is successfully substituted.
# - empty.css is used to test if no extra licese header is added if a file only
#   contains a license header.

# Descend to the script location.
cd "$(dirname "$0")"

# Clean up.
rm -rf tmp
rm -f data/in/ignore.* data/in/exclude.* data/out/ignore.* data/out/exclude.*

# Create ignore.* and exclude.* files.
cp data/in/hello.go data/in/ignore.go
cp data/in/hello.js data/in/exclude.js
cp data/in/hello.py data/in/ignore.py
cp data/in/hello.sh data/in/exclude.sh
cp data/in/hello.css data/in/ignore.css
cp data/in/hello.dart data/in/exclude.dart
cp data/in/hello.html data/in/ignore.html

# Copy ignore.* and exclude.* files to out directory.
cp data/in/ignore.* data/out
cp data/in/exclude.* data/out

# Update copyright year in the out directory for the files that will get a new
# license notice.
year=$(date +'%Y')
sed -i "s/Copyright (c) [0-9]*,/Copyright (c) $year,/g" data/out/empty.py \
data/out/empty.sh data/out/hello.css data/out/hello.go data/out/hello.sh \
data/out/empty.dart data/out/empty.js data/out/hello.c data/out/hello.h \
data/out/hello.cpp data/out/hello.hpp

# Make temporary directory to run the tests.
mkdir tmp
cp data/.gitignore tmp/.gitignore
cp data/in/* tmp
cd tmp

# Create non-executable empty files.
# Executable files are commited into the repo because they include a shebang.
# Note that Go is not tested for empty files because gofmt does not tolerate an
# empty file.
touch empty.dart empty.js

# Tests use -v by default to make debugging easier.
# This also tests .gitignore and --exclude and --force.
# Note that --force is tested because the tidy DOCTYPE warning is skipped.
dart ../../bin/unifmt.dart -fv -e 'exclude.*' -c 'Herman Bergwerf' -l 'MIT'

# Remove the bashbeautifier backup file (*~)
rm hello.sh~

# Clean up.
function cleanUp {
  # Remove temporary test files.
  rm -rf tmp
  rm data/in/ignore.* data/in/exclude.* data/out/ignore.* data/out/exclude.*

  # Change out files copyright year back to 2015 so no changes have to be
  # committed.
  sed -i "s/Copyright (c) [0-9]*,/Copyright (c) 2015,/g" data/out/empty.py \
  data/out/empty.sh data/out/hello.css data/out/hello.go data/out/hello.sh \
  data/out/empty.dart data/out/empty.js data/out/hello.c data/out/hello.h \
  data/out/hello.cpp data/out/hello.hpp
}

# Compare all files one by one.
for file in *
do
  echo "Checking $file"
  diffout=$(diff -q "$file" "../data/out/$file")
  if [ -n "$diffout" ]; then
    echo "$file was not formatted correctly."
    diff "$file" "../data/out/$file"

    # Terminate.
    cd ../
    cleanUp
    exit 1
  fi
done

cd ../
cleanUp
