init:
	# Create symlink for pre-commit hook.
	ln -sf ../../tool/pre-commit.sh .git/hooks/pre-commit

check:
	./test/test.sh
