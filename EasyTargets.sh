#!/usr/bin/sh

options="ef:F:hlm:st:"
longopts="execute,help,list,menu:,select,target:,target-file:,targets-file:"
progname="EasyTargets"
new_args="$(getopt --quiet --options "$options" --longoptions "$longopts" --name "$progname" -- "$@")"
getopt_status=$?
usage=\
"Usage: EasyTargets.sh [OPTION]...

  -e, --execute             Execute target file.
  -f, --target-file=FILE    Override target filepath with FILE. (default: .target)
  -F, --targets-file=FILE   Override targets filepath with FILE. (default: .targets)
  -h, --help                Print this message.
  -m, --menu=MENU           Use MENU for -s/--select instead of terminal.
  -s, --select              Choose content from targets file (default: \".targets\")
                            to replace target file's content.
  -t, --target=TARGET       Make -e/--execute only execute TARGET's content from
                            targets file, completely ignoring target file.
                            Working directory will be targets file's directory.

Used targets file will be FILE if it's an absolute path, or first occurence of
FILE found upwards from working directory if it's relative.

Used target file will be \"targets_file_directory/FILE\" if it exists,
or - if not - first occurence of FILE found upwards from working directory.

If -s/--select is selected, and target file is not found, -f's FILE will be
created in targets file directory and used as target file.

If -m/--menu is selected, -s/--select will pipe target names found in targets file
to MENU's stdin line-by-line, and expect stdout to return one of these lines."

e="false"
h="false"
l="false"
m=""
s="false"
f=""
default_f=".target"
F=""
default_F=".targets"
t=""

declare -ir ENOTFOUND=1
declare -ir EMISSINGARG=2
declare -ir EINVALIDARG=3
declare -ir ENOTCREATED=4
declare -ir ERDERROR=5
declare -ir EWRERROR=6
declare -ir ENOPERMS=7
declare -ir EOTHER=255


if [ $getopt_status -ne 0 ]; then
	echo -e "Error: Invalid options.\n"
	echo "$usage"
	exit $EINVALIDARG
fi

# remove_duplicate_lines(): Print all unique lines of "$@".
#
remove_duplicate_lines() {
	awk '!seen[$0]++' <<< "$@"
	return 0
}

# upfind_file(): Check if file $examined_directory/$1 exists, print the resulting absolute path on success.
#				 Examined directory is at first cwd, then enters a loop of going up and checking until / is hit.
#   Args:
#     $1 - filename or filepath.
#
#   Errors:
#     $ENOTFOUND - Argument was not found.
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

# find_targets_file(): Try to find targets file, print its absolute path on success.
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

# find_target_file(): Try to find target file, print its absolute path on success.
#                     Checks targets file's directory first. On fail, searches upwards.
#   Errors:
#     $ENOTFOUND - $f was not found.
#
find_target_file() {
	local targets_filepath
	targets_filepath="$(find_targets_file)"
	local search_status=$?
	
	# If targets file is found, first check if $f exists in its directory.
	if [ $search_status -eq 0 ]; then
		local target_file_in_targets_dir="$(dirname "$targets_filepath")/$f"
		if [ -f "$target_file_in_targets_dir" ]; then
			echo "$target_file_in_targets_dir"
			return 0
		fi
	fi

	# If not, start searching upwards for $f, starting from cwd.
	local filepath
	filepath="$(upfind_file "$f")"
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
#     $ENOTFOUND - Target file was not found.
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

# create_target_file_in_targets_dir(): Find targets file, create $f in its directory, and set permissions. Print resulting absolute filepath.
#
#   Errors:
#     $EMISSINGARG - $f is unset.
#     $ENOTCREATED - Target file could not be created.
#     $ENOTFOUND   - Targets file was not found.
#
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
		rm "$target_filepath"
		return $ENOTCREATED
	fi

	echo "$target_filepath"
	return 0
}

# write_target_file(): Find target file, or create one next to targets file on failure, and replace its content with "$@".
#
#   Errors:
#     $EMISSINGARG - $f is unset.
#     $ENOTCREATED - Target file was not found, and a new one couldn't be created.
#     $ENOTFOUND   - Targets file was not found.
#     $EWRERROR    - Target's content couldn't be replaced.
#
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

# is_valid_integer(): Check if "$@" is a one-line, valid integer. Returns $(true) or $(false).
#
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

# print_nth_line(): Print line no. $1 of shifted by one "$@".
#
#   Args:
#     $1 - Positive [1, inf) index of line to print.
#
#   Errors:
#     $EINVALIDARG - $1 is not an integer, or is not in [1, inf).
#     $ENOTFOUND   - $1 is higher than "$@"'s amount of lines.
#
print_nth_line() {
	local n="$1"
	shift
	local text="$@"
	local num_lines="$(wc --lines <<< "$@")"

	if ! is_valid_integer "$n" || [ "$n" -le 0 ]; then
		return $EINVALIDARG
	fi

	if [ "$n" -gt "$num_lines" ]; then
		return $ENOTFOUND
	fi

	head -$n <<< "$text" | tail -1
	return 0
}


# print_targets_file(): Try to find the targets file and print its content.
#
#   Errors:
#     $ENOTFOUND - Targets file was not found.
#     $ERDERROR  - Targets file was found, but couldn't be read.
#
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

# print_target_tags(): Print line-separated tags found in targets file.
#                      Tag is '[target_name]' from line in form of '[target_name]optional_whitespace'
#
#   Errors:
#     $ENOTFOUND - Targets file was not found.
#     $ERDERROR  - Targets file was found, but couldn't be read.
#
print_target_tags() {
	local targets_file
	targets_file="$(print_targets_file)"
	local print_status=$?

	if [ $print_status -ne 0 ]; then
		return $print_status
	fi

	unstripped_tags="$(sed -E --quiet '/^\[.+\]\s*$/ p' <<< "$targets_file")"
	stripped_tags="$(sed --quiet 's/^\(.*\]\)\s*/\1/ p' <<< "$unstripped_tags")"
	echo "$stripped_tags"
	return 0
}

# print_unique_target_names(): Get all tags, strip them of '[' and ']', and print unique values.
#
#   Errors:
#     $ENOTFOUND - Targets file was not found.
#     $ERDERROR  - Targets file was found, but couldn't be read.
#
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

# target_exists(): Check if targets file contains a tag corresponding to target name $1. Returns $(true) or $(false).
#
#   Args:
#     $1 - Target name.
#
#   Errors:
#     $ENOTFOUND - Targets file was not found.
#     $ERDERROR  - Targets file was found, but couldn't be read.
#
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

# print_target_content(): Print target $1's content.
#                         That is, everything below target's tag until next tag or end of file.
#
#   Errors:
#     $ENOTFOUND - Targets file or target's content was not found.
#     $ERDERROR  - Targets file was found, but couldn't be read.
#
print_target_content() {
	local tags
	tags="$(print_target_tags)"
	print_status=$?

	if [ $print_status -ne 0 ]; then
		return $print_status
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

# prefix_with_line_numbers(): Print each line of "$@" with "[${index}] " added at the beginning.
#                             Index starts at 1, and goes up one with each line.
#
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

# remove_line_numbers(): Remove text from each line of "$@" added by prefix_with_line_numbers(), and print results.
#
remove_line_numbers() {
	local number_prefix="["
	local number_suffix="]: "

	sed "s/^${number_prefix}[0-9]*${number_suffix}\(.*\)/\1/" <<< "$@"
	return 0
}

# remove_whitespace_lines(): Print each line of "$@", except those with only whitespace.
#
remove_whitespace_lines() {
	sed '/^\s*$/d' <<< "$@"

	return 0
}

execute_target() {
	local targets_file
	targets_file="$(find_targets_file)"
	local search_status=$?

	if [ $search_status -ne 0 ]; then
		echo "Error: Targets file \"$F\" was not found."
		exit $ENOTFOUND
	fi

	if ! target_exists "$t"; then
		echo "Error: Target \"$t\" was not found in targets file."
		exit $ENOTFOUND
	fi

	local saved_f="$f"
	f="$(mktemp --suffix="_EasyTargets")"
	
	local create_status=$?
	if [ $create_status -ne 0 ]; then
		echo "Error: Failed to create temporary target file \"$f\"."
		rm "$f"
		exit $ENOTCREATED
	fi

	chmod u+x "$f"
	local chmod_status=$?
	if [ $chmod_status -ne 0 ]; then
		echo "Error: Failed to give executable permissions to temporary target file \"$f\"."
		rm "$f"
		exit $ENOTCREATED
	fi

	write_target_file "$(print_target_content "$t")"
	local write_status=$?
	if [ $write_status -ne 0 ]; then
		echo "Error: Failed to write to temporary target file \"$f\"."
		rm "$f"
		exit $EWRERROR
	fi

	cd "$(dirname "$targets_file")"
	"$f"
	rm "$f"

	# Restoring saved f in case this function will return instead of exit in the future.
	f="$saved_f"
	exit 0
}

# select_target(): Present unique target names from targets file to user, ask to choose one, and replace target's file content with target's content.
#
#   Errors:
#     $ENOTFOUND   - Targets file was not found.
#     $ENOTCREATED - Target file was not found, and a new one couldn't be created.
#     $ERDERROR    - Targets file could not be read.
#     $EWRERROR    - Target's file content couldn't be replaced.
#
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

# select_target_by_menu(): Print unique target names to "$m"'s stdin for the user to choose, and replace target file's content with chosen target's content.
#
#   Errors:
#     $ENOTCREATED - Target file was not found, and a new one couldn't be created.
#     $ENOTFOUND   - Targets file was not found.
#     $EOTHER      - Menu returned error, or didn't output target's name, or output invalid name.
#     $ERDERROR    - Targets file could not be read.
#     $EWRERROR    - Target's file content couldn't be replaced.
#
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
		"-h"|"--help")
			h="true"
			shift
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
		"-t"|"--target")
			t="$2"
			shift 2
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

if [ "$h" = "true" ]; then
	echo "$usage"
	exit 0
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
	if [ ! -z "$t" ]; then
		execute_target
	else
		execute_target_file
	fi
fi

