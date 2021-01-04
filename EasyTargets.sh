#!/usr/bin/sh

options=""
longopts=""
progname="EasyTargets"
new_args="$(getopt --quiet --options "$options" --longoptions "$longopts" --name "$progname" -- "$@")"
getopt_status=$?

usage="Usage: (to be written)"

if [ $getopt_status -ne 0 ]; then
	echo -e "Invalid options.\n"
	echo "$usage"
	exit
fi

eval set -- "$new_args"

while true; do
	case "$1" in
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
