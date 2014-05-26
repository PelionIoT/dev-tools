#!/bin/sh
# Find the shared libraries that define specific symbol
# arg 1 - symbol name to search for
# arg 2 - Files to search

# NA arg 3 - the symbol to search for.

PATTERN=$1
shift

for F in $@
do
echo "IN: ${F} ..."
nm --defined-only ${F} | grep --color -n -r -A 2 -B 2 -e "$PATTERN"
done

#find $1 -name "$2" -exec "nm --defined-only" --print-file-name '{}' ';' | grep " [^U] ""$3"
