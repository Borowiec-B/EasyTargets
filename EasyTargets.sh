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

execute_file() {
	local default_filename=".target.sh"
	local target_filename="$default_filename"

	if [ ! -z "$1" ]; then
		target_filename="$1"
	fi

	local target_filepath
	# Upfind returns an absolute path.
	target_filepath="$(./utilities/call_wrapper.py upfind "$target_filename")"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		echo "Error: \"$target_filename\" was not found."
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

