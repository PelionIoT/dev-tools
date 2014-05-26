#!/bin/bash


COLOR_BOLD="echo -ne '\E[1m'"
COLOR_RED="echo -ne '\E[31m'"
COLOR_MAGENTA="echo -ne '\E[35m'"
COLOR_YELLOW="echo -ne '\E[33m'"
COLOR_GREEN="echo -ne '\E[32m'"
COLOR_NORMAL="echo -ne '\E[0m'"

LOCAL=`pwd`

SETUPFILE=prereq-setup.cfg

eval $COLOR_BOLD
echo "Exporting env vars to run project in dev mode. Looking for $SETUPFILE..."
eval $COLOR_NORMAL

SOURCE_EXPORT_NAME="source-this.sh"


SCRIPT_PATH=`readlink -f $0`
CONFIG_PATH=`dirname $SCRIPT_PATH`/$SETUPFILE

if [ ! -f $CONFIG_PATH ]; then
    echo "$SETUPFILE not in current directory"
    CONFIG_PATH=$LOCAL/$SETUPFILE
    if [ ! -f $CONFIG_PATH ]; then
	echo "$SETUPFILE not in $CONFIG_PATH either. Failing.."
	exit
    fi
fi

echo "Found $CONFIG_PATH"

#SCRIPT=`readlink -f $0`

#if [ ! -f "$CONFIG_PATH" ]; then
#    echo "prereq-setup.cfg not at $CONFIG_PATH either. Run expand-prereqs."
#    exit
#else
    echo "prereq-setup.cfg found in $CONFIG_PATH"
    PUSHD="1"
    BASE_DIR=`dirname $CONFIG_PATH`
    pushd $BASE_DIR
#fi

. $CONFIG_PATH

if [ -z $PREREQ_dir_BIN ] ; then
    echo "PREREQ_dir_BIN not set - is \"$PREREQ_dir_BIN\""
fi
if [ -z $PREREQ_dir_LIB ] ; then
    echo "PREREQ_dir_LIB not set - is \"$PREREQ_dir_LIB\""
fi


if [ "$PUSHD" == "1" ]; then
    if [ ! -z $PREREQ_dir_BIN ] ; then
	PREREQ_dir_BIN=$BASE_DIR/$PREREQ_dir_BIN
    fi
    if [ ! -z $PREREQ_dir_LIB ] ; then
	PREREQ_dir_LIB=$BASE_DIR/$PREREQ_dir_LIB
    fi
fi

if [ -f $LOCAL/$SOURCE_EXPORT_NAME ]; then
    eval $COLOR_YELLOW
    echo "old $SOURCE_EXPORT_NAME found - renaming to $SOURCE_EXPORT_NAME.old"
    eval $COLOR_NORMAL
    mv $SOURCE_EXPORT_NAME $SOURCE_EXPORT_NAME.old
fi
touch $SOURCE_EXPORT_NAME


if [ -d "$PREREQ_dir_BIN" ] ; then
    echo "Adding $PREREQ_dir_BIN to PATH"
    echo "export PATH=\"$PREREQ_dir_BIN:$PATH\"" >> $LOCAL/$SOURCE_EXPORT_NAME
else
    eval $COLOR_RED
    echo "$PREREQ_dir_BIN not found."
    eval $COLOR_NORMAL
fi

if [ -d "$PREREQ_dir_LIB" ] ; then
    echo "Adding $PREREQ_dir_LIB to LD_LIBRARY_PATH"
    echo "Adding $LOCAL to LD_LIBRARY_PATH"
    echo "export LD_LIBRARY_PATH=\"$LOCAL\":\"$PREREQ_dir_LIB:$LD_LIBRARY_PATH\"" >> $LOCAL/$SOURCE_EXPORT_NAME
else
    eval $COLOR_RED
    echo "$PRERQ_dir_BIN not found."
    eval $COLOR_NORMAL
fi

if [ "$PUSHD" == "1" ]; then
    popd
fi
eval $COLOR_BOLD
echo "Type: source $SOURCE_EXPORT_NAME to set run env vars."
eval $COLOR_NORMAL

