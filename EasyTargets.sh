#!/usr/bin/sh

options="elt:T:"
longopts="execute,list,target-file:,targets-file:"
progname="EasyTargets"
new_args="$(getopt --quiet --options "$options" --longoptions "$longopts" --name "$progname" -- "$@")"
getopt_status=$?
usage="Usage: (to be written)"

e="false"
l="false"
t=""
default_t=".target.sh"
T=""
default_T=".targets"

if [ $getopt_status -ne 0 ]; then
	echo -e "Invalid options.\n"
	echo "$usage"
	exit 1
fi

remove_duplicate_lines() {
	awk '!seen[$0]++' <<< "$@"
	return 0
}

upfind_file() {
	local filepath
	filepath="$(./utilities/call_wrapper.py upfind "$1")"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		return 1
	fi

	echo -n "$filepath"
	return 0
}

find_target_file() {
	local filepath
	filepath="$(upfind_file "$t")"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		return 1
	fi

	echo -n "$filepath"
	return 0
}

find_targets_file() {
	local filepath
	filepath="$(upfind_file "$T")"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		return 1
	fi

	echo -n "$filepath"
	return 0
}

execute_target_file() {
	local target_filepath
	target_filepath="$(find_target_file)"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		echo "Error: Target file \"$t\" was not found."
		exit 1
	fi

	cd "$(dirname "$target_filepath")"
	"$target_filepath"
	
	exit 0
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
		return 2
	fi

	return 0
}

print_targets_file() {
	local targets_filepath

	targets_filepath="$(find_targets_file)"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		return 1
	fi

	local targets
	# Suppress stderr, EasyTargets should only print its own error messages.
	targets="$(cat "$targets_filepath" 2>/dev/null)"
	local read_status=$?
	
	if [ $read_status -ne 0 ]; then
		return 2
	fi

	echo -n "$targets"
	return 0
}

print_target_tags() {
	local targets_file
	targets_file="$(print_targets_file)"
	local print_status=$?

	if [ $print_status -ne 0 ]; then
		return $print_status
	fi

	sed -En '/^\[.+\]$/p' <<< "$targets_file"
	return 0
}

print_unique_target_names() {
	local tags targets=""
	tags="$(print_target_tags)"
	local print_status=$?

	if [ $print_status -ne 0 ]; then
		return $print_status
	fi

	targets="$(sed 's/^\[\(.*\)\]$/\1/' <<< "$tags")"
	echo "$(remove_duplicate_lines "$targets")"
	return 0
}

target_exists() {
	local all_tags="$(print_target_tags)"
	local arg_tag="[${1}]"
	local arg_tag_found="false"

	# print_target_tags() prints line-separated results.
	while read tag; do
		if [ "$tag" = "$arg_tag" ]; then
			arg_tag_found="true"
		fi
	done <<< "$all_tags"

	if [ "$arg_tag_found" = "true" ]; then
		return $(true)
	else
		return $(false)
	fi
}

print_target_content() {
	local tags="$(print_target_tags)"
	local arg_tag="[$1]"
	local arg_tag_found="false"

	for tag in "$tags"; do
		if [ "$tag" = "$arg_tag" ]; then
			arg_tag_found="true"
		fi
	done

	if [ "$arg_tag_found" = "false" ]; then
		return 1
	fi

	local targets_file
	targets_file="$(print_targets_file)"
	local print_status=$?

	if [ $print_status -ne 0 ]; then
		return $print_status
	fi

	local tag_line_number="$(grep --line-number --fixed-strings "$tag" <<< "$targets_file" | head -1 | cut --fields=1 --delimiter=:)"
	local content_line_number=$((tag_line_number + 1))
	local content="$(sed --quiet --expression "${content_line_number},/^\s*\[.*\]\s*$/p" <<< "$targets_file" | head -n -1)"

	echo "$content"
	return 0
}

prefix_with_line_numbers() {
	local number_prefix="["
	local line_number=1
	local number_suffix="]:"

	# Without this, whitespace in read lines gets reduced to single spaces.
	preserved_IFS="$IFS"
	IFS=""

	while read line; do
		echo ""$number_prefix"$line_number"$number_suffix" "$line""
		line_number=$((line_number + 1))
	done <<< "$@"

	IFS="$preserved_IFS"

	return 0
}

remove_whitespace_lines() {
	sed '/^\s*$/d' <<< "$@"

	return 0
}

is_valid_integer() {
	local num_lines="$(wc --lines <<< "$@")"

	if [ $num_lines -ne 1 ]; then
		return $(false)
	fi

	local first_line="$(head --lines=1 - <<< "$@")"

	# Sed prints output only if $first_line is a valid integer.
	if [ -z "$(sed --quiet --expression '/^-\?([1-9][0-9]*|0)$/p' <<< "$first_line")" ]; then
		return $(false)
	fi

	return $(true)
}

print_nth_line() {
	local n="$1"
	shift
	local text="$@"
	local num_lines="$(wc --lines <<< "$@")"

	if ! is_valid_integer "$n" || [ "$n" -lt 0 ] || [ "$n" -gt "$num_lines" ]; then
		return 1
	fi

	head -$n <<< "$text" | tail -1
	return 0
}


eval set -- "$new_args"

while true; do
	case "$1" in
		"-e"|"--execute")
			e="true"
			shift
			;;
		"-l"|"--list")
			l="true"
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

if [ "$l" = "true" ]; then
	print_unique_target_names
fi

if [ "$e" = "true" ]; then
	execute_target_file
fi

