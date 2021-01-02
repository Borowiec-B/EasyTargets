# Wrappers for purely Python functions, for straightforward calling from shell using callpython.sh.
# (e.g. callpythonwrapper.py upfind filename1 filename2 filename3)
#
# All functions defined here must have a single String parameter.
# Supplied String will always be composed of all arguments taken from shell minus function name and leading/trailing spaces.
# (e.g. (from example above) "filename1 filename2 filename3")
#
# Functions here will print return values to stdout where applicable.
#
# All functions here should be type-hinted as NoReturn.
#
# For documentation of functions defined here, refer to upfind.py.

import shell, upfind as upfind_raw
from typing import NoReturn


def upfind(input: str) -> NoReturn:
	shell.assert_args_count_range(input, 1, 2)

	result = upfind_raw.upfind(*shell.input_to_list(input))

	if (result == None):
		shell.exit_error() 
	
	shell.exit_success(result)

def upfind_parent(input: str) -> NoReturn:
	shell.assert_args_count_range(input, 1, 2)

	result = upfind_raw.upfind_parent(*shell.input_to_list(input))

	if (result == None):
		shell.exit_error() 

	shell.exit_success(result)

def upfind_any(input: str) -> NoReturn:
	shell.assert_args_count_range(input, 1, None)

	result = upfind_raw.upfind_any(*shell.input_to_list(input))

	if (result == None):
		shell.exit_error()
	
	shell.exit_success(result)
