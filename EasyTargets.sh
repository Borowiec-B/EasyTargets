#!/usr/bin/sh

options="r"
longopts="run"
progname="EasyTargets"
new_args="$(getopt --quiet --options "$options" --longoptions "$longopts" --name "$progname" -- "$@")"
getopt_status=$?

if [ $getopt_status -ne 0 ]; then
	echo -e "Invalid options.\n"
	echo "$usage"
	exit 1
fi

usage="Usage: (to be written)"

run_selected_cmd() {
	default_filename=".target.sh"
	cmd_filename="$1"

	if [ -z "$cmd_filename" ]; then
		cmd_filename="$default_filename"
	fi

	# Upfind returns an absolute path
	cmd_filepath="$(./utilities/call_wrapper.py upfind "$cmd_filename")"

	cd "$(dirname "$cmd_filepath")"
	"$cmd_filepath"
}


eval set -- "$new_args"

while true; do
	case "$1" in
		"-r"|"--run")
			run_selected_cmd
			break
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

