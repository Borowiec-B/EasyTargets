#!/usr/bin/sh

function="$1"
shift
args="$*"

python -c "import all_wrappers; all_wrappers.$function(\"$args\")"
