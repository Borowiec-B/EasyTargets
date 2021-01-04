#!/usr/bin/sh

options=""
longopts=""
progname="EasyTargets"
new_args="$(getopt --quiet --options "$options" --longoptions "$longopts" --name "$progname" -- "$@")"

if [ $? -ne 0 ]; then
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
