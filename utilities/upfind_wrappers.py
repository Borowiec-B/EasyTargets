# Wrappers for purely Python functions, for straightforward calling from shell using callpython.sh.
# (e.g. callpythonwrapper.py upfind filename1 filename2 filename3)
#
# All functions defined here must have a single list parameter.
# The argument will always be composed of all arguments taken from shell minus function name.
# (e.g. (from example above) ['filename1', 'filename2', 'filename3'])
#
# Functions here will print return values to stdout where applicable.
#
# All functions here should be type-hinted as NoReturn.
#
# For documentation of functions defined here, refer to upfind.py.

import shell, upfind as upfind_raw
from typing import NoReturn


def upfind(args: list) -> NoReturn:
	shell.assert_args_count_range(args, 1, 2)

	result = upfind_raw.upfind(*args)

	if (result == None):
		shell.exit_error() 
	
	shell.exit_success(result)

def upfind_parent(args: list) -> NoReturn:
	shell.assert_args_count_range(args, 1, 2)

	result = upfind_raw.upfind_parent(*args)

	if (result == None):
		shell.exit_error() 

	shell.exit_success(result)

def upfind_any(args: list) -> NoReturn:
	shell.assert_args_count_range(args, 1, None)

	result = upfind_raw.upfind_any(*args)

	if (result == None):
		shell.exit_error()
	
	shell.exit_success(result)

def wrappers():
	return {
		"upfind":		 upfind,
		"upfind_parent": upfind_parent,
		"upfind_any":	 upfind_any
	}

