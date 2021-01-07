#!/usr/bin/sh

options="et:"
longopts="execute,target-file:"
progname="EasyTargets"
new_args="$(getopt --quiet --options "$options" --longoptions "$longopts" --name "$progname" -- "$@")"
getopt_status=$?
usage="Usage: (to be written)"

e="false"
t=""
default_t=".target.sh"

if [ $getopt_status -ne 0 ]; then
	echo -e "Invalid options.\n"
	echo "$usage"
	exit 1
fi

find_target_file() {
	local target_filepath
	target_filepath="$(./utilities/call_wrapper.py upfind "$t")"
	local search_status=$?
	
	if [ $search_status -ne 0 ]; then
		return 1
	else
		echo -n "$target_filepath"
		return 0
	fi
}

execute_target_file() {
	local target_filepath
	target_filepath="$(find_target_file)"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		echo "Error: Target file \"$t\" was not found."
		exit 1
	else
		cd "$(dirname "$target_filepath")"
		"$target_filepath"
	fi
}


eval set -- "$new_args"

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

if [ -z "$t" ]; then
	t="$default_t"
fi

if [ "$e" = "true" ]; then
	execute_target_file
fi

