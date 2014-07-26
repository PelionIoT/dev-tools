#!/bin/bash

COLOR_BOLD="echo -ne '\E[1m'"
COLOR_RED="echo -ne '\E[31m'"
COLOR_MAGENTA="echo -ne '\E[35m'"
COLOR_YELLOW="echo -ne '\E[33m'"
COLOR_GREEN="echo -ne '\E[32m'"
COLOR_NORMAL="echo -ne '\E[0m'"

#UTILZ_BASE=$HOME/workspace/utilz-libs

#ADDCP=$UTILZ_BASE:$UTILZ_BASE/bin:$UTILZ_BASE/lib/log4j-1.2.15.jar
#JRE=/usr/lib/classpath

REPO_BASE="https://code.wigwag.com"
MANIFEST="manifest.lst"
MD5_FILENAME="checksum.lst"
MD5_CHKSUM_EXT=".$$.lst"
EXP_DIR=`pwd`
EXPORT_DIR="${EXP_DIR}/prereqs.new"
FINAL_DIR="${EXP_DIR}/prereqs"
PRE_META_DIR="${EXP_DIR}/.prereqs"
PRE_LAST_POSTFIX=".last"
WGET_CMD="wget --no-check-certificate "
WGET_CMD_QUIET="wget --no-check-certificate -nv "
WGET_CMD_QUIET_STDOUT="wget --no-check-certificate -qO- "
GLOBAL_ERROR_FILE=`basename $0`.err
GLOBAL_LOG_FILE=$EXP_DIR/`basename $0`.log.tmp

LINENUM=0

function print_usage () {
	echo "$0 gets the prerequisite libs for this project"
	echo " -b repo-base (uses $REPO_BASE as default)"
	echo " -m manifest-file (uses $MANIFEST as default)"
	echo " -e export-dir (uses $FINAL_DIR as default)"
	echo " -u USER (typically required, default - will not use a password)"
	echo " -p PASSWORD (typically required, default - will not use a password)"
	echo "    Note: both USER and PASSWORD must be specified"
}


# function iswhitespace()
# {
#     n=`printf "%d\n" "'$1'"`
#     if (( $n != "13" )) && (( $n != "10" )) && (( $n != "32" )) && (( $n != "92" )) && (( $n != "110" )) && (( $n != "114" )); then
#         return 0
#     fi
#     return 1
# }
# function trim()
# {
#     i=0
#     str="$@"
#     while (( i < ${#1} ))
#     do
#         char=${1:$i:1}
#         iswhitespace "$char"
#         if [ "$?" -eq "0" ]; then
#             str="${str:$i}"
#             i=${#1}
#         fi
#         (( i += 1 ))
#     done
#     i=${#str}
#     while (( i > "0" ))
#     do
#         (( i -= 1 ))
#         char=${str:$i:1}
#         iswhitespace "$char"
#         if [ "$?" -eq "0" ]; then
#             (( i += 1 ))
#             str="${str:0:$i}"
#             i=0
#         fi
#     done
#         echo "$str"
# }


function cleanuptmp() 
{
    rm -rf $EXPORT_DIR-temp
    rm -f $GLOBAL_LOG_FILE
#    rm -I "*$MD5_CHKSUM_EXT"
}

function trim()
{
    trimmed="$@"
    trimmed=${trimmed%% }
    trimmed=${trimmed## }
    echo $trimmed
}

function onexit() {
    local exit_status=${1:-$?}
    eval $COLOR_RED
    echo "Error - update did not complete."
    eval $COLOR_NORMAL
    touch $EXP_DIR/$GLOBAL_ERROR_FILE
#    echo "Summary: "
#    cat $GLOBAL_LOG_FILE
    cleanuptmp || echo "some cleanup failed"
    exit $exit_status
}

function onerror() {
    eval $COLOR_RED
    echo "Error..."
    eval $COLOR_YELLOW
    echo "$@"
    eval $COLOR_NORMAL
    touch $EXP_DIR/$GLOBAL_ERROR_FILE
}

function onabort() {
    eval $COLOR_RED
    echo "Error..."
    eval $COLOR_YELLOW
    echo "$@"
    eval $COLOR_NORMAL
    touch $EXP_DIR/$GLOBAL_ERROR_FILE
    cleanuptmp
    exit 1
}


function get_remote_md5() {
# $1 URL
# $2 file
# $3 source-path (left side of colon in manifest.lst)
# outputs into REMOTE_MD5

#    cadaver $1 > $TEMPNAME << END
#get $MD5_FILENAME
#$MD5_FILENAME.remote
#END
    TEMP_SCRIPT=awks.$$.tmp
    pwd
    FAR_DIRNAME=`dirname $3`
    if [ -z $FAR_DIRNAME ]; then
	FAR_DIRNAME="ROOT"
    fi
    TMP_DIR_NAME=`echo "$FAR_DIRNAME" | sed 's/\//\-/g'`
    echo "$FAR_DIRNAME TMP_DIR_NAME=$TMP_DIR_NAME"
    LOCAL_MD5_NAME=$TMP_DIR_NAME.$MD5_CHKSUM_EXT
    if [ ! -e $LOCAL_MD5_NAME ]; then
	$WGET_CMD_QUIET_STDOUT $1/$MD5_FILENAME > $LOCAL_MD5_NAME
	echo "Grabbed far MD5 file for $FAR_DIRNAME"
    else
	echo "used cached far MD5 file for $FAR_DIRNAME"
    fi
    	cat > $TEMP_SCRIPT <<EOF
awk -vLOOKUPVAL="$2" '\$2 == LOOKUPVAL { print \$1 }' < \$1
EOF
#	LOCAL=`awk -vLOOKUPVAL="\"$NAME\"" "$EVALS" < $MD5_FILENAME.remote`
#	REMOTE=`awk -vLOOKUPVAL="$NAME" '"$NAME" == LOOKUPVAL { print $1 }' < $MD5_FILENAME.remote`
	if [ ! -f $LOCAL_MD5_NAME ]; then
	    eval $COLOR_MAGENTA
	    echo "Could not find a checksum entry for directory $FAR_DIRNAME"
	    echo "** NOTE: Could not find a checksum entry for directory $FAR_DIRNAME" >> $GLOBAL_LOG_FILE 
	    eval $COLOR_NORMAL
	else
            REMOTE_MD5=`source $TEMP_SCRIPT $LOCAL_MD5_NAME`
	    echo "Remote MD5: $REMOTE_MD5"
#	    rm -f $MD5_FILENAME
	fi
}




function process_line () {
    line="$@" # get entire line
    SRC=${line%%:*}    # left of colon
    DEST=${line##*:}   # right of colon
    LINK=${REPO_BASE}/${SRC}
    SRCBASE=`basename $SRC`
    DIRNAME=`dirname $EXPORT_DIR/$DEST`

    GETIT="1"
    LAST_TOUCH="$PRE_META_DIR/$SRCBASE$PRE_LAST_POSTFIX"
    echo "Look at: $FINAL_DIR/$DEST"

    if [ -f $FINAL_DIR/$DEST ]; then
	echo "$EXPORT_DIR/$DEST exists - checking checksum"
	URL=`echo $LINK | sed 's/^\(h.*\/\).*/\1/'`
	echo "URL: $URL"
	FILEN=`echo $LINK | sed 's/^h.*\/\(.*\)/\1/'`
	echo "FILEN: $FILEN"
	get_remote_md5 $URL $FILEN $SRC
	LOCAL_MD5=`md5sum $FINAL_DIR/$DEST | awk '{ print $1 }'`
	echo "Local MD5: $LOCAL_MD5"
	if [ "$LOCAL_MD5" == "$REMOTE_MD5" ]; then
	    eval $COLOR_BOLD
	    echo "Skipping $DEST - up to date."
	    echo "$DEST - up to date." >> $GLOBAL_LOG_FILE
	    eval $COLOR_NORMAL
	    GETIT=""
	    echo `pwd`"  cp -a $FINAL_DIR/$DEST $EXPORT_DIR/$DEST"
	    if [ ! -d $DIRNAME ]; then
		echo "Made directory: $DIRNAME" >> $GLOBAL_LOG_FILE
		mkdir -p $DIRNAME
	    fi
	    cp -a $FINAL_DIR/$DEST $EXPORT_DIR/$DEST || onerror "Copy failed from $FINAL_DIR/$DEST $EXPORT_DIR/$DEST"
	fi
    else
	echo "$FINAL_DIR/$DEST does not exist"
    fi
    
    if [ ! -z $GETIT ]; then
	eval $COLOR_BOLD
	echo "$LINK --> $FINAL_DIR/$DEST"
	eval $COLOR_NORMAL
	# download file, or report error. put it all in log file also
	$WGET_CMD $LINK && ( echo "Downloaded $LINK --> prereqs/$FILE_DIR/$DEST" >> $GLOBAL_LOG_FILE ) || ( onerror "Error downloading on line: $MANIFEST:$LINENUM - is file at: $LINK  (forget authentication??)" && ( echo "** ERROR:  downloading on line: $MANIFEST:$LINENUM - is file at: $LINK" >> $GLOBAL_LOG_FILE ) )
echo $WGET_CMD $LINK
		touch $LAST_TOUCH 
	if [ ! -d $DIRNAME ]; then
	    mkdir -p $DIRNAME
	fi
	echo 
	echo "Doing: cp -a $SRCBASE $EXPORT_DIR/$DEST "
	cp -a $SRCBASE $EXPORT_DIR/$DEST || ( onerror "Could not copy $SRCBASE to $EXPORT_DIR/$DEST" && echo "** ERROR: Failed to copy $SRCBASE to $EXPORT_DIR/#DEST" >> $GLOBAL_LOG_FILE )
	rm -f $SRCBASE
    fi
}

trap onexit 1 2 3 15 ERR
rm -rf $EXP_DIR/$GLOBAL_ERROR_FILE

while getopts "hm:b:p:u:e:" opt; do
    case $opt in
#	d)  
#	    if [ "$OPTARG" = "DBUS" ]; then
#		_DBUS_LIB=$_DBUS_DEBUG_LIB
#	    else
#		eval $COLOR_RED
#		echo "Unknown DEBUG option"
#		eval $COLOR_NORMAL
#		exit 1
#	    fi
#       shift
#	    shift
#      	;;
	h)
	    print_usage
	    exit
	;;
	m)
	    eval $COLOR_YELLOW
    	    MANIFEST=${OPTARG}
	    echo "using manifest list: $MANIFEST"
	    eval $COLOR_NORMAL
	;;
	p)
    	    PASSW=${OPTARG}
	;;
	u)
    	    USERN=${OPTARG}
	;;
	e)
    	    FINAL_DIR=${OPTARG}
	;;
#    	shift
#    	shift
   	b)
	    eval $COLOR_YELLOW
    	    REPO_BASE=${OPTARG}
	    echo "using repo base of: $REPO_BASE"
	    eval $COLOR_NORMAL
#    	shift
#    	shift
    	;;
	\?) 
	    echo "Unknown option: -$OPTARG"
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument"
	    exit 1
	    ;;
    esac
done

#if [ $# = 0 ]; then
#    print_usage
#    exit
#fi

shift $(($OPTIND - 1))


if [ "$USERN" != "" ]; then
    if [ "$PASSW" == "" ]; then
	eval $COLOR_RED
	echo "User name specified without password"
	eval $COLOR_NORMAL
	exit
    fi
    WGET_CMD="$WGET_CMD --user=$USERN --password=$PASSW"
    WGET_CMD_QUIET="$WGET_CMD_QUIET --user=$USERN --password=$PASSW"
fi

if [ ! -e $MANIFEST ]; then
    eval $COLOR_RED
    echo "Manifest file $MANIFEST can't be found"
    eval $COLOR_NORMAL
    exit
fi

if [ ! -e $FINAL_DIR ]; then
    eval $COLOR_YELLOW
    echo "$FINAL_DIR does not exist. Creating..."
    eval $COLOR_NORMAL
    mkdir $FINAL_DIR
fi

if [ ! -d $FINAL_DIR ]; then
    eval $COLOR_RED
    echo "$FINAL_DIR is not a directory!"
    eval $COLOR_NORMAL
    exit
fi

mkdir -p $PRE_META_DIR

eval $COLOR_BOLD
echo "exporting to $FINAL_DIR"
eval $COLOR_NORMAL

FILE_LIST=`cat $MANIFEST`

#for name in $FILE_LIST
#do
#done

USE_URL_REGEX="#+\s+USE_URL=(.*)"

rm -rf $EXPORT_DIR-temp
mkdir $EXPORT_DIR-temp
cd $EXPORT_DIR-temp
if [ -e $GLOBAL_LOG_FILE ]; then
    rm $GLOBAL_LOG_FILE
fi
touch $GLOBAL_LOG_FILE


cat ../$MANIFEST | while read name; do
#    echo "line: ${name}"
    LINENUM=$(( $LINENUM + 1 ))
    P=$(trim $name)

    if [[ $P =~ $USE_URL_REGEX ]]; then
	i=1
	n=${#BASH_REMATCH[*]}
	if [[ $i -lt $n ]]; then
	    REPO_BASE=${BASH_REMATCH[$i]}
	    eval $COLOR_BOLD
	    echo "Using repo: $REPO_BASE"
	    eval $COLOR_NORMAL
	fi
    fi
	
    P=${P/#\#*/"-"}    
    if [ "${P}" == "-" ]; then   # skip comments
	continue
    fi
    if [ "${P}" == "" ]; then    # skip blank lines
	continue
    fi
#    echo "line: ${P}"
    process_line ${P}
#    if [ -f $EXP_DIR/$GLOBAL_ERROR_FILE ]; then
#	break
#    fi
done



if [ -f $EXP_DIR/$GLOBAL_ERROR_FILE ]; then
    rm -rf $EXP_DIR/$GLOBAL_ERROR_FILE
    eval $COLOR_RED
    echo "Some errors occurred. NOT UPDATED. New files placed in $EXPORT_DIR:"
    eval $COLOR_NORMAL
    echo "Summary: "
# show log file stating what we did
    cat $GLOBAL_LOG_FILE
    cleanuptmp
else
    eval $COLOR_BOLD
    echo "Complete!"
    eval $COLOR_NORMAL
    echo "Summary: "
# show log file stating what we did
    cat $GLOBAL_LOG_FILE

    cd ..
    
    cleanuptmp
    
    
# do this at the very end, so if errors were made the old $FINAL_DIR is still there
    rm -rf $FINAL_DIR
    mv $EXPORT_DIR $FINAL_DIR    
fi



