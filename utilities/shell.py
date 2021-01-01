# Set of helper functions for interacting with shell.

import sys
from typing import NoReturn, Optional


EXIT_SUCCESS = 0
EXIT_FAILURE = 1

def input_to_list(input: str) -> list:
	"""
	Converts string into a list, using space as separator.

	Args:
		input: All arguments taken from shell as a single string.

	Returns:
		A list of arguments obtained from input.
	"""

	return input.split()

def arguments_count(input: str) -> int:
	"""
	Returns amount of arguments in string, using space as separator.

	Args:
		input: All arguments taken from shell as a single string.

	Returns:
		Length of list of arguments created from input.
	"""

	return len(input_to_list(input))

def test_arguments_count_equal(input: str, target: int) -> bool:
	"""
	Tests if string contains target amount of arguments.

	Args:
		input: All arguments taken from shell as a single string.

	Returns:
		Boolean indicating if input contains target amount of arguments.
	"""

	return (arguments_count(input) == target)

def test_arguments_count_in_range(input: str, min: int, max: int) -> bool:
	"""
	Tests if string contains amount of arguments between min and max (inclusive).

	Args:
		input: All arguments taken from shell as a single string.

	Returns:
		Boolean indicating if input's amount of arguments is within [min, max].
	"""

	args_count = arguments_count(input)
	return (args_count >= min and args_count <= max)

def exit_error(message: Optional[str] = None) -> NoReturn:
	"""
	Optionally prints a message and calls sys.exit with failure code.

	Args:
		message: String to print before exiting, or None to not print anything.

	Returns:
		N/A - exits the program with failure code.
	"""

	if (message != None):
		print(message)
	sys.exit(EXIT_FAILURE)

def exit_success(message: Optional[str] = None) -> NoReturn:
	"""
	Optionally print a message and call sys.exit with success code.

	Args:
		message: String to print before exiting, or None to not print anything.

	Returns:
		N/A - exits the program with success code.
	"""

	if (message != None):
		print(message)
	sys.exit(EXIT_SUCCESS)


def exit_error_invalid_arguments_count(valid_arguments_count: int, supplied_arguments_count: Optional[int] = None):
	"""
	Exit with error code and print a message indicating invalid count of supplied arguments.

	Args:
		valid_arguments_count:		Count of arguments which should have been supplied.
		supplied_arguments_count:	Count of arguments which have been supplied.

	Returns:
		N/A - exits the program with error code.
	"""

	message = f"Invalid count of arguments. Program takes: {valid_arguments_count}."
	if (supplied != None):
		message = f"{message} Supplied: {supplied_arguments_count}."

	exit_error(message)

def exit_error_invalid_arguments_count_range(valid_arguments_count_min: int, valid_arguments_count_max: int, supplied_arguments_count: Optional[int] = None):
	"""
	Exit with error code and print a message indicating invalid count of supplied arguments.

	Args:
		valid_arguments_count_min:	Minimum (inclusive) count of arguments which should have been supplied.
		valid_arguments_count_max:	Maximum (inclusive) count of arguments which should have been supplied.
		supplied_arguments_count:	Count of arguments which have been supplied.
	
	Returns:
		N/A - exits the program with error code.
	"""

	message = f"Invalid count of arguments. Program takes: [{valid_arguments_count_min}, {valid_arguments_count_max}]."
	if (supplied != None):
		message = f"{message} Supplied: {supplied_arguments_count}."

	exit_error(message)

