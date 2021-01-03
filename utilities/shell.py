# Set of helper functions for interacting with shell.

import sys
from typing import NoReturn, Optional


EXIT_SUCCESS = 0
EXIT_FAILURE = 1


def args_count(args: list) -> int:
	"""
	Returns amount of arguments (items) in a list.

	Args:
		args: List of shell arguments.

	Returns:
		Length of args.
	"""

	return len(args)

def test_args_count_equal(args: list, target: int) -> bool:
	"""
	Tests if args contains target amount of arguments.

	Args:
		args: List of shell arguments.

	Returns:
		Boolean indicating if args contains target amount of arguments.
	"""

	return (args_count(args) == target)

def test_args_count_in_range(args: list, min: int, max: int) -> bool:
	"""
	Tests if args contains amount of arguments between min and max (inclusive).

	Args:
		args: List of shell arguments.

	Returns:
		Boolean indicating if args's amount of arguments is within [min, max].
	"""

	count = args_count(args)
	return (count >= min and count <= max)

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
	Optionally prints a message and calls sys.exit with success code.

	Args:
		message: String to print before exiting, or None to not print anything.

	Returns:
		N/A - exits the program with success code.
	"""

	if (message != None):
		print(message)
	sys.exit(EXIT_SUCCESS)

def exit_error_invalid_args_count(valid_count: int, supplied_count: Optional[int] = None):
	"""
	Exits with error code and prints a message indicating invalid count of supplied arguments, and displays allowed count.

	Args:
		valid_count:	Count of arguments which should have been supplied.
		supplied_count:	Count of arguments which have been supplied.

	Returns:
		N/A - exits the program with error code.
	"""

	message = f"Invalid count of arguments. Program takes: {valid_count}."
	if (supplied_count != None):
		message = f"{message} Supplied: {supplied_count}."

	exit_error(message)

def exit_error_invalid_args_count_range(valid_count_min: Optional[int], valid_count_max: Optional[int], supplied_count: Optional[int] = None):
	"""
	Exits with error code and prints a message indicating invalid count of supplied arguments, and displays allowed counts.

	Args:
		valid_count_min: Minimum (inclusive) count of arguments which should have been supplied. None for (∞, max].
		valid_count_max: Maximum (inclusive) count of arguments which should have been supplied. None for [min, ∞).
		supplied_count:	 Count of arguments which have been supplied. Can be omitted.
	
	Returns:
		N/A - exits the program with error code.
	"""

	if (valid_count_min == valid_count_max == None):
		raise ValueError("At least one (min or max) limit of range must not be None.")

	message = f"Invalid count of arguments."
	if (valid_count_max == None):
		message += f" Program takes at least {valid_count_min} arguments."
	elif (valid_count_min == None):
		message += f" Program takes up to {valid_count_max} arguments."
	else:
		message += f" Program takes between {valid_count_min} and {valid_count_max} arguments."

	if (supplied_count != None):
		message += f" Supplied: {supplied_count}."

	exit_error(message)

def assert_args_count(args: list, valid_count: int) -> None:
	"""
	Calls exit_error_invalid_args_count() if args doesn't contain valid_count arguments.

	Args:
		args: List of shell arguments.
		valid_count: Count of arguments args must contain to successfully return from this function.

	Returns:
		Nothing if counts are equal.
		N/A otherwise - exits the program with error code.
	"""

	supplied_count = args_count(args)

	if (supplied_count != valid_count):
		exit_error_invalid_args_count(valid_count, supplied_count)

def assert_args_count_range(args: list, valid_count_min: Optional[int], valid_count_max: Optional[int]) -> None:
	"""
	Calls exit_error_invalid_arguments_count_range() if args's count of arguments is not within [valid_count_min, valid_count_max].
	Either min or max can be omitted.

	Args:
		args: List of shell arguments.
		valid_count_min: Minimum (inclusive) count of arguments input must contain to return successfully from this function. None if count is allowed to be in (∞, max].
		valid_count_max: Maximum (inclusive) count of arguments input must contain to return successfully from this function. None if count is allowed to be in [min, ∞).

	Returns:
		Nothing if input contains allowed count of arguments.
		N/A otherwise - exits the program with error code.
	"""

	if (valid_count_min == valid_count_max == None):
		raise ValueError("At least one (min or max) limit of range must not be None.")

	if (valid_count_min != None and
		valid_count_max != None and
		valid_count_min > valid_count_max
		):
		raise ValueError("Minimum count must not be higher than maximum count.")


	supplied_count = args_count(args)
	if ((valid_count_max == None and supplied_count < valid_count_min) or # Trigger error if supplied_count is outside of allowed range [min, ∞).
		(valid_count_min == None and supplied_count > valid_count_max) or # Trigger error if supplied_count is outside of allowed range (∞, max].
		(valid_count_min != None and valid_count_max != None and not valid_count_min <= supplied_count <= valid_count_max) # Trigger error if supplied_count is outside of allowed range [min, max].
		):
		exit_error_invalid_args_count_range(valid_count_min, valid_count_max, supplied_count)

