#!/bin/bash

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

# Make temporary directory to run the tests.
mkdir tmp
cp data/.gitignore tmp/.gitignore
cp data/in/* tmp
cd tmp

# Create non-executable empty files.
# Executable files are commited into the repo because they include a shebang.
# Note that Go is not tested for empty files because gofmt does not tolerate an
# empty file. Also note that empty.css is used to test if no licese header is
# added if a file only contains a license header.
touch empty.dart empty.js

# Tests use -v by default to make debugging easier.
# This also tests .gitignore and --exclude.
dart ../../bin/molviewfmt.dart -v -e 'exclude.*' -c 'Herman Bergwerf' -l 'MIT'

# Remove the bashbeautifier backup file (hello.sh~)
rm hello.sh~

# Compare all files one by one.
for file in *
do
  echo "Checking $file"
  diff=$(diff -q "$file" "../data/out/$file")
  if [ -n "$diff" ]; then
    echo "$file was not formatted correctly."

    # Clean up.
    cd ../
    rm -rf tmp
    rm data/in/ignore.* data/in/exclude.* data/out/ignore.* data/out/exclude.*

    # Terminate.
    exit 1
  fi
done

# Clean up.
cd ../
rm -rf tmp
rm data/in/ignore.* data/in/exclude.* data/out/ignore.* data/out/exclude.*
