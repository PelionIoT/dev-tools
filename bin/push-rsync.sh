#!/bin/bash

# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SELF="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$SELF/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

MYDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"


if [ -e $MYDIR/commons.source ]; then
    source $MYDIR/commons.source
    setup_colors
else
    echo "Where is your $MYDIR/commons.source ?"
fi


function print_usage () {
    echo "Usage $0 local remote"
    echo "-p pretend (just show what you would do)"
    echo "-S source only (don't copy the build of the module)"
}

while getopts "Sp" opt; do
  case $opt in
     S)
        SOURCE_ONLY=1
        shift
        ;;
     p)
       PRETEND=yes
       shift
       ;;
    # G)
    #   debug=yes
    #   shift
    #   ;;
  esac
done

if [ "$#" -lt 2 ]; then
    print_usage
    exit 1
else
    SRC=$1
    DST=$2
fi


if [ ! -z $PRETEND ]; then
    SYNC_OPTS="--dry-run"
else
    SYNC_OPTS=""
fi

eval $COLOR_BOLD
echo rsync -rlcIvz $SYNC_OPTS $SRC $DST
eval $COLOR_NORMAL
rsync --progress -rlcIvz $SYNC_OPTS \
--exclude 'node_modules' \
--exclude 'build' \
--exclude '.git' \
--exclude '.gitignore' \
--exclude '.gitmodules' \
--exclude '.prereqs/*' \
--exclude '*.a' \
--exclude '*.o' \
--exclude '*.Po' \
--exclude '*.so' \
--exclude '*.node' \
--exclude '.DS_Store' \
$SRC $DST
