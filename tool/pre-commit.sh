#!/bin/bash
# Git pre-commit hook

molviewfmt -e 'test/data/*'
make check
