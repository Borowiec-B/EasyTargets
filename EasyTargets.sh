#!/usr/bin/sh

options="ef:F:lm:s"
longopts="execute,list,menu:,select,target-file:,targets-file:"
progname="EasyTargets"
new_args="$(getopt --quiet --options "$options" --longoptions "$longopts" --name "$progname" -- "$@")"
getopt_status=$?
usage="Usage: (to be written)"

e="false"
l="false"
m=""
s="false"
f=""
default_f=".target"
F=""
default_F=".targets"

declare -ir ENOTFOUND=1
declare -ir EMISSINGARG=2
declare -ir EINVALIDARG=3
declare -ir ENOTCREATED=4
declare -ir ERDERROR=5
declare -ir EWRERROR=6
declare -ir ENOPERMS=7
declare -ir EOTHER=255


if [ $getopt_status -ne 0 ]; then
	echo -e "Invalid options.\n"
	echo "$usage"
	exit $EINVALIDARG
fi

remove_duplicate_lines() {
	awk '!seen[$0]++' <<< "$@"
	return 0
}

# upfind_file(): Check if file $examined_directory/$1 exists.
#				 Examined directory is at first cwd, then enters a loop of going up and checking until / is hit.
#   Args:
#     $1 - filename or filepath
#
#   Errors:
#     $ENOTFOUND - Argument was not found
#
upfind_file() {
	local filename="$1"
	# A little edge case, without this "/" argument prints cwd.
	if [ "$filename" = "/" ]; then
		echo "/"
		return 0
	fi

	local current_examined_dir="$(pwd)"

	while true; do
		if [ -e "$current_examined_dir"/"$filename" ]; then
			realpath --no-symlinks "$current_examined_dir"/"$filename"
			return 0
		elif [ ! "$current_examined_dir" = "/" ]; then
			current_examined_dir="$(dirname "$current_examined_dir")"
		else
			break
		fi
	done
	
	return $ENOTFOUND
}

# find_target_file(): Call upfind_file() with $f, which is either argument given to -f/--target-file, or $default_f.
#
#   Errors:
#     $ENOTFOUND - $f was not found.
#
find_target_file() {
	local filepath
	filepath="$(upfind_file "$f")"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		return $search_status
	fi

	echo -n "$filepath"
	return 0
}

# find_targets_file(): Call upfind_file() with $F, which is either argument given to -F/--targets-file, or $default_F.
#
#   Errors:
#     $ENOTFOUND - $F was not found.
#
find_targets_file() {
	local filepath
	filepath="$(upfind_file "$F")"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		return $search_status
	fi

	echo -n "$filepath"
	return 0
}

# execute_target_file(): Find target file, cd into its directory and execute it.
#
#   Errors:
#     $ENOTFOUND - target file was not found.
#     $ENOPERMS  - Found file's permissions don't allow executing.
#
execute_target_file() {
	local target_filepath
	target_filepath="$(find_target_file)"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		echo "Error: Target file \"$f\" was not found."
		exit $search_status
	fi

	cd "$(dirname "$target_filepath")"
	if [ ! -x "$target_filepath" ]; then
		echo "Error: Target file \"$f\" has no execute permissions."
		exit $ENOPERMS
	fi

	"$target_filepath"
	
	exit 0
}

create_target_file_in_targets_dir() {
	if [ -z "$f" ]; then
		return $EMISSINGARG
	fi

	local targets_filepath
	targets_filepath="$(find_targets_file)"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		return $search_status
	fi

	local targets_dir="$(dirname "$targets_filepath")"
	local target_filepath="$targets_dir"/"$f"

	touch "$target_filepath"
	local touch_status=$?

	if [ $touch_status -ne 0 ]; then
		return $ENOTCREATED
	fi

	chmod u+x "$target_filepath"
	local chmod_status=$?

	if [ $chmod_status -ne 0 ]; then
		return $ENOTCREATED
	fi

	echo "$target_filepath"
	return 0
}

write_target_file() {
	local target_filepath
	target_filepath="$(find_target_file)"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		target_filepath="$(create_target_file_in_targets_dir)"
		local create_status=$?

		if [ $create_status -ne 0 ]; then
			return $create_status
		fi
	fi

	echo "$@" > "$target_filepath"
	local write_status=$?

	if [ $write_status -ne 0 ]; then
		return $EWRERROR
	fi

	return 0
}

is_valid_integer() {
	local lines_in_input="$(wc --lines <<< "$@")"

	if [ $lines_in_input -ne 1 ]; then
		return $(false)
	fi

	local first_line="$(head --lines=1 - <<< "$@")"

	# Sed prints output only if $first_line is a valid integer.
	if [ -z "$(sed --quiet -E '/^-?([1-9][0-9]*|0)$/p' <<< "$first_line")" ]; then
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
		return $ENOTFOUND
	fi

	head -$n <<< "$text" | tail -1
	return 0
}


print_targets_file() {
	local targets_filepath

	targets_filepath="$(find_targets_file)"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		return $search_status
	fi

	local targets
	targets="$(cat "$targets_filepath")"
	local read_status=$?
	
	if [ $read_status -ne 0 ]; then
		return $ERDERROR
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

	sed -E --quiet '/^\[.+\]$/p' <<< "$targets_file"
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
	local all_tags
	all_tags="$(print_target_tags)"
	local print_status=$?

	if [ $print_status -ne 0 ]; then
		return $print_status
	fi

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
	local tags
	tags="$(print_target_tags)"
	print_status=$?

	if [ $print_status -eq $ENOTFOUND ]; then
		echo "Error: Failed to find target file \"$f\"."
		exit $ENOTFOUND
	elif [ $print_status -eq $ERDERROR ]; then
		echo "Error: Found, but failed to read target file \"$f\."
		exit $ERDERROR
	fi

	local arg_tag="[$1]"
	local arg_tag_found="false"

	while read tag; do
		if [ "$tag" = "$arg_tag" ]; then
			arg_tag_found="true"
		fi
	done <<< "$tags"

	if [ "$arg_tag_found" = "false" ]; then
		return $ENOTFOUND
	fi

	local targets_file
	targets_file="$(print_targets_file)"
	local print_status=$?

	if [ $print_status -ne 0 ]; then
		return $print_status
	fi

	local tag_line_number="$(print_nth_line 1 "$(grep --line-number --fixed-strings "$arg_tag" <<< "$targets_file")" | cut --fields=1 --delimiter=:)"
	local content_line_number="$((tag_line_number + 1))"

	# Following sed call prints lines below tag given to this command, all the way to either end of file or line above next tag.
	local tag_regex='^\s*\[.*\]\s*$'
	local content="$(sed --quiet "${content_line_number},/${tag_regex}/ { /${tag_regex}/q ; p }" <<< "$targets_file")"

	echo "$content"
	return 0
}

prefix_with_line_numbers() {
	local number_prefix="["
	local line_number=1
	local number_suffix="]: "

	# Without this, whitespace in read lines gets reduced to single spaces.
	preserved_IFS="$IFS"
	IFS=""

	while read line; do
		echo ""$number_prefix"$line_number"$number_suffix""$line""
		line_number=$((line_number + 1))
	done <<< "$@"

	IFS="$preserved_IFS"

	return 0
}

remove_line_number_prefixes() {
	local number_prefix="["
	local number_suffix="]: "

	sed "s/^${number_prefix}[0-9]*${number_suffix}\(.*\)/\1/" <<< "$@"
	return 0
}

remove_whitespace_lines() {
	sed '/^\s*$/d' <<< "$@"

	return 0
}

select_target() {
	local targets_prompt_separator="---"
	local prompt="Select target: "
	local invalid_input_message="Invalid input. Enter one of the shown numbers."

	local target_names
	target_names="$(print_unique_target_names)"
	local print_status=$?

	if [ $print_status -eq $ENOTFOUND ]; then
		echo "Error: Couldn't find targets file \"$F\"."
		exit $ENOTFOUND
	elif [ $print_status -eq $ERDERROR ]; then
		echo "Error: Found, but couldn't read targets file \"$F\"."
		exit $ERDERROR
	fi

	numbered_target_names="$(prefix_with_line_numbers "$target_names")"

	echo "$numbered_target_names"
	echo "$targets_prompt_separator"
	echo -n "$prompt"

	local selected_number
	local min=1
	local max="$(wc --lines <<< "$numbered_target_names")"

	read selected_number

	while ! is_valid_integer "$selected_number" || [ "$selected_number" -lt "$min" ] || [ "$selected_number" -gt "$max" ]; do
		echo "$invalid_input_message"
		echo -n "$prompt"
		read selected_number
	done

	selected_target_name="$(print_nth_line "$selected_number" "$target_names")"

	write_target_file "$(print_target_content "$selected_target_name")"
	local target_write_status=$?

	if [ $target_write_status -eq $ENOTCREATED ]; then
		echo "Error: Failed to find, then failed to create missing target file \"$f\"."
		exit $ENOTCREATED
	elif [ $target_write_status -eq $EWRERROR ]; then
		echo "Error: Failed to write to target file \"$f\"."
		exit $EWRERROR
	fi

	return 0
}

select_target_by_menu() {
	if [ -z "$m" ]; then
		echo "Error: Menu not supplied to select_target_by_menu()."
		exit $EMISSINGARG
	fi

	local target_names
	target_names="$(print_unique_target_names)"
	local print_status=$?

	if [ $print_status -eq $ENOTFOUND ]; then
		echo "Error: Couldn't find targets file \"$F\"."
		exit $ENOTFOUND
	elif [ $print_status -eq $ERDERROR ]; then
		echo "Error: Found, but couldn't read targets file \"$F\"."
		exit $ERDERROR
	fi

	local selected_target_name;
	selected_target_name="$($m <<< "$target_names")"
	local menu_status=$?

	if [ $menu_status -ne 0 ] || [ -z "$selected_target_name" ] || ! target_exists "$selected_target_name" ; then
		echo "Failed to get target name through menu: \"$m\"."
		exit $EOTHER
	fi

	write_target_file "$(print_target_content "$selected_target_name")"
	local write_status=$?

	if [ $write_status -eq $ENOTCREATED ]; then
		echo "Error: Failed to find, then failed to create missing target file \"$f\"."
		exit $ENOTCREATED
	elif [ $write_status -eq $EWRERROR ]; then
		echo "Error: Failed to write to target file \"$f\"."
		exit $EWRERROR
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
		"-f"|"--target-file")
			f="$2"
			shift 2
			;;
		"-F"|"--targets-file")
			F="$2"
			shift 2
			;;
		"-l"|"--list")
			l="true"
			shift
			;;
		"-m"|"--menu")
			m="$2"
			shift 2
			;;
		"-s"|"--select")
			s="true"
			shift
			;;
		--)
			shift
			break
			;;
		*)
			echo "Error: Unimplemented option "$1"."
			exit $EINVALIDARG
			;;
	esac
done

if [ -z "$f" ]; then
	f="$default_f"
fi

if [ -z "$F" ]; then
	F="$default_F"
fi

if [ "$l" = "true" ]; then
	print_unique_target_names
fi

if [ "$s" = "true" ]; then
	if [ ! -z "$m" ]; then
		select_target_by_menu
	else
		select_target
	fi
fi

if [ "$e" = "true" ]; then
	execute_target_file
fi

