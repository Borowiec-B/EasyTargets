#!/usr/bin/sh

options="et:"
longopts="execute,target-file:"
progname="EasyTargets"
new_args="$(getopt --quiet --options "$options" --longoptions "$longopts" --name "$progname" -- "$@")"
getopt_status=$?
usage="Usage: (to be written)"

if [ $getopt_status -ne 0 ]; then
	echo -e "Invalid options.\n"
	echo "$usage"
	exit 1
fi

find_target_file() {
	local default_filename=".targets.sh"

	if [ ! -z "$1" ]; then
		local filename_to_search="$1"
	else
		local filename_to_search="$default_filename"
	fi

	local found_filepath
	found_filepath="$(./utilities/call_wrapper.py upfind "$filename_to_search")"
	local search_status=$?
	
	if [ $search_status -ne 0 ]; then
		return 1
	else
		echo -n "$found_filepath"
		return 0
	fi
}

execute_file() {
	local target_filepath
	target_filepath="$(find_target_file "$1")"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		echo "Error: Target file was not found."
		exit 1
	else
		cd "$(dirname "$target_filepath")"
		"$target_filepath"
	fi
}


eval set -- "$new_args"

e="false"
t=""

while true; do
	case "$1" in
		"-e"|"--execute")
			e="true"
			shift
			;;
		"-t"|"--target-file")
			t="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			echo "Unrecognized option "$1", exiting."
			break
			;;
	esac
done

if [ "$e" = "true" ]; then
	execute_file "$t"
fi

