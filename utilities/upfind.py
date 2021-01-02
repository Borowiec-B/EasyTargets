import os, sys;
from typing import Optional


def directory_up(directory: str) -> str:
	"""
	Shorthand for returning the parent directory.

	Args:
		directory: Directory to return the parent of.

	Returns:
		Parent directory of argument.
	"""

	return os.path.dirname(directory)



def upfind(target_filename: str, last_directory_to_check: str = "/") -> Optional[str]:
	"""
	Tries to find absolute path to target_filename in current directory, goes up, and repeats the process.

	Args:
		target_filename:		 File name to be found.
		last_directory_to_check: If file name is not found there, stop the search.

	Returns:
		Success: Absolute path to target_filename.
		Failure: None.
	"""

	# Somewhat arbitrary number to limit iterations when last_directory_to_check is not cwd's parent,
	# and the hierarchy is really deep (after "/", search always stops regardless of last_directory_to_check).
	max_iterations			 = 25
	current_iteration		 = 0
	current_search_directory = os.getcwd()

	while (True):
		current_directory_files_list = os.listdir(current_search_directory)
	
		if (target_filename in current_directory_files_list):
			# Join directory containing target_filename with target_filename, separating them with '/' to form the final found path.
			found_file_path = current_search_directory + '/' + target_filename

			# If directory containing target_filename is "/", above statement results in "//target_filename".
			# In this case, remove the unnecessary leading slash.
			if (current_search_directory == "/"):
				found_file_path = found_file_path[1:];

			return found_file_path;

		else:
			if (current_search_directory == "/"						or
				current_search_directory == last_directory_to_check	or
				current_iteration		 == max_iterations):

				return None

		current_iteration		 = current_iteration + 1
		current_search_directory = directory_up(current_search_directory)

def upfind_parent(target_filename: str, last_directory_to_check: str = "/") -> Optional[str]:
	""" Same as upfind(), but returns parent directory of its result.
	"""
	# If upfind() returns None on unsuccessful search, directory_up is gonna throw.
	try:
		return directory_up(upfind(target_filename, last_directory_to_check))
	except TypeError:
		return None

def upfind_any(*target_filenames: str, last_directory_to_check: str = "/") -> Optional[str]:
	"""
	Calls upfind on each filename.
		
	Args:
		*target_filenames: File names to be found.

	Returns:
		Success: First found file from target_filenames.
		Failure: None.
	"""

	for target_filename in set(target_filenames):
		result = upfind(target_filename, last_directory_to_check)
		if (result != None):
			return result

	return None;
