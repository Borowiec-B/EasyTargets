#!/usr/bin/env python3

import all_wrappers, shell, sys


if __name__ == "__main__":
	try:
		fun = sys.argv[1]
	except IndexError:
		shell.exit_error("Error: Function name was not supplied.")

	args = sys.argv[2:]

	all_wrappers.get_wrapper(fun)(' '.join(args))
