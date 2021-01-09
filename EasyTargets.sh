#!/usr/bin/sh

options="est:T:"
longopts="execute,select,target-file:,targets-file:"
progname="EasyTargets"
new_args="$(getopt --quiet --options "$options" --longoptions "$longopts" --name "$progname" -- "$@")"
getopt_status=$?
usage="Usage: (to be written)"

e="false"
t=""
default_t=".target.sh"
T=""
default_T=".targets"

if [ $getopt_status -ne 0 ]; then
	echo -e "Invalid options.\n"
	echo "$usage"
	exit 1
fi

upfind_file() {
	local filepath
	filepath="$(./utilities/call_wrapper.py upfind "$1")"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		return 1
	else
		echo -n "$filepath"
		return 0
	fi
}

find_target_file() {
	local filepath
	filepath="$(upfind_file "$t")"
	local search_status=$?

	if [ $search_status -ne 0 ]
		return 1
	else
		echo -n "$filepath"
		return 0
	fi
}

find_targets_file() {
	local filepath
	filepath="$(upfind_file "$T")"
	local search_status=$?

	if [ $search_status -ne 0 ]
		return 1
	else
		echo -n "$filepath"
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

write_target_file() {
	local target_filepath
	target_filepath="$(find_target_file)"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		return 1
	fi

	echo "$@" > "$target_filepath"
	local write_status=$?

	if [ $write_status -ne 0 ]; then
		return 1
	fi

	return 0
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
		"-T"|"--targets-file")
			T="$2"
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

if [ -z "$T" ]; then
	T="$default_T"
fi

if [ "$e" = "true" ]; then
	execute_target_file
fi

