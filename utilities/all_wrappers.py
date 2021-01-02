from collections.abc import Callable
from shell import exit_error
from typing import NoReturn
import upfind_wrappers

all_wrappers = upfind_wrappers.wrappers()

def exit_wrapper_not_found(name: str) -> NoReturn:
	exit_error("Wrapper was not found.")

def get_wrapper(name: str) -> Callable[..., NoReturn]:
	try:
		return all_wrappers[name]
	except KeyError:
		return exit_wrapper_not_found

