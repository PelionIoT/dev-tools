COLOR_BOLD="echo -ne '\E[1m'"
COLOR_RED="echo -ne '\E[31m'"
COLOR_MAGENTA="echo -ne '\E[35m'"
COLOR_YELLOW="echo -ne '\E[33m'"
COLOR_GREEN="echo -ne '\E[32m'"
COLOR_NORMAL="echo -ne '\E[0m'"

#UTILZ_BASE=$HOME/workspace/utilz-libs

#ADDCP=$UTILZ_BASE:$UTILZ_BASE/bin:$UTILZ_BASE/lib/log4j-1.2.15.jar
#JRE=/usr/lib/classpath

REPO_BASE="https://izuma.repositoryhosting.com/webdav/izuma_frzwebproj"
MANIFEST="manifest.lst"
MD5_FILENAME="checksum.lst"
EXP_DIR=`pwd`
SCRIPT_DIR=`dirname $0`
EXPORT_DIR="${EXP_DIR}/prereqs.new"
FINAL_DIR="${EXP_DIR}/prereqs"
WGET_CMD="wget "
WGET_CMD_QUIET="wget -nv "
GLOBAL_ERROR_FILE=`basename $0`.err
LINENUM=0

PREREQ_CFG="prereq-setup.cfg"




function print_usage () {
	echo "$0 [Options] [package-name] builds/expands the prerequisite libs for this project"
	echo " [package-name] is the package as referred to in manifest.lst on the right side of the ':'"
	echo " -m manifest-file (uses $MANIFEST as default)"
	echo " -c clean up old/failed builds"
	echo " -e export-dir (uses $FINAL_DIR as default)"
	echo "    Note: both USER and PASSWORD must be specified"
	echo " -p pretend, but do not expand/build"
	echo " -a [ARCH] force architecture (cross-build), where ARCH is the short-name defined in"
	echo "    prereq-setup.cfg. eg. \"arm-fsl-linux-gnueabi\" - if you don't have ARCH variables"        
	echo "    setup prereq-setup.cfg this will most definitely fail"
	echo " If 'package name' is given, then only this package's .SETUP will run"
}


function onexit() {
    local exit_status=${1:-$?}
    eval $COLOR_RED
    echo "Error - update did not complete."
    eval $COLOR_NORMAL
    exit $exit_status
}

function onerror() {
    eval $COLOR_RED
    echo "Error..."
    eval $COLOR_YELLOW
    echo "$@"
    eval $COLOR_NORMAL
    exit 1
}

function setup_pack() {
# $1 - .SETUP file
# $2 - ARCHIVE
# $3 - relative directory


    # TODO: add new archs here
    if [ "$FORCE_ARCH" != "" ]; then
	ARCH=$FORCE_ARCH
    else
	local UNAMEM=`uname -m`
	case $UNAMEM in
	    x86_64)
		ARCH="x64"
		;;
	    i686|i386)
		ARCH="x86"
		;;
	    arm*)   # armv5tel is the SLUG board
		ARCH="armel"
		;;
	    *)
		ARCH="unknown"
		;;
	esac
    fi

    local EXEC_DIR=`pwd`
    echo "Running SETUP for $ARCHIVE for architecture $ARCH"
    FIRST4=`echo $runme | sed -e 's/^\(.\{4\}\).*/\1/'`
    mkdir $EXP_DIR/$PREREQ_dir_TMP/$$.$FIRST4
    pushd $EXP_DIR/$PREREQ_dir_TMP/$$.$FIRST4
    if [ ! -z $FORCE_ARCH ]; then 
###############
##### cross-build setup 
#####   in cross build setup, we run 'pre-cross' and then 'cross-build' in the same directory 
#####   (this allows multi-build cross compiles, where you may need to build host tools)
###############
	aname=$FORCE_ARCH
	eval $COLOR_BOLD
	echo "Setup is for \"$ARCH\" which is GNU name: "$(eval "echo \${${aname}_GNU_ARCH_NAME}")
	echo "Pre-cross..."
	eval $COLOR_NORMAL
	
	source $EXEC_DIR/$1 pre-cross $EXP_DIR $FINAL_DIR/$3/$ARCHIVE $EXP_DIR/$PREREQ_dir_TMP/$$.`echo $runme | sed -e 's/^\(.\{4\}\).*/\1/'` $ARCH $(eval "echo \${${FORCE_ARCH}_EXPANDED_BASE}")
	
	eval $COLOR_BOLD
	echo "Cross-build"
	eval $COLOR_NORMAL

	GNU_ARCH_NAME=$(eval "echo \${${aname}_GNU_ARCH_NAME}")
	CROSS_BASE=$(eval "echo \${${aname}_CROSS_BASE}")
	CROSS_BIN_PREFIX=$(eval "echo \${${aname}_CROSS_BIN_PREFIX}")
	CROSS_INCLUDE=$(eval "echo \${${aname}_CROSS_INCLUDE}")
	CROSS_CC=$(eval "echo \${${aname}_CROSS_CC}")
	CSTOOLS=$(eval "echo \${${aname}_CS_TOOLS}")
	
	CSTOOLS_LIB=$(eval "echo \${${aname}_CSTOOLS_LIB}")
	CSTOOLS_USR_LIB=$(eval "echo \${${aname}_CSTOOLS_USR_LIB}")
	CSTOOLS_USR_INC=$(eval "echo \${${aname}_CSTOOLS_USR_INC}")
# libc & system headers:
	CSTOOLS_INC=$(eval "echo \${${aname}_CSTOOLS_INC}")
	TARGET_ARCH=$(eval "echo \${${aname}_TARGET_ARCH}")
	TARGET_TUNE=$(eval "echo \${${aname}_TARGET_TUNE}")
	TOOL_PREFIX=$CROSS_BIN_PREFIX

	SETUP_FOR_ARCH=$FORCE_ARCH
	source $EXEC_DIR/$1 cross-build $EXP_DIR $FINAL_DIR/$3/$ARCHIVE $EXP_DIR/$PREREQ_dir_TMP/$$.`echo $runme | sed -e 's/^\(.\{4\}\).*/\1/'` $ARCH $(eval "echo \${${FORCE_ARCH}_EXPANDED_BASE}")
    else
	if [ -z $PRETEND_MODE ]; then
#	chmod a+x $EXEC_DIR/$1
	    source $EXEC_DIR/$1 build $EXP_DIR $FINAL_DIR/$3/$ARCHIVE $EXP_DIR/$PREREQ_dir_TMP/$$.`echo $runme | sed -e 's/^\(.\{4\}\).*/\1/'` $ARCH
	else
#	chmod a+x $EXEC_DIR/$1
	    source $EXEC_DIR/$1 pretend $EXP_DIR $FINAL_DIR/$3/$ARCHIVE $EXP_DIR/$PREREQ_dir_TMP/$$.`echo $runme | sed -e 's/^\(.\{4\}\).*/\1/'` $ARCH
	fi
	eval $COLOR_NORMAL # just to clenup from script run...
    fi
    popd
    rm -rf $EXP_DIR/$PREREQ_dir_TMP/$$.$FIRST4
}

function find_and_prepare_dir() {
    # this goes into the directory, find .SETUP scripts - and executes them
    # $1 directory
    
    pushd $1
    LOCALSETUP=`ls -l --time-style=+ | grep ^- | awk '{print $6}' | sed -n /.*\.SETUP/p`

#    LOCALSETUP=`ls -l *.SETUP | grep ^- | awk '{print $8}'`

    for runme in $LOCALSETUP
    do
	ARCHIVE=`echo $runme | sed -e 's/\(.*\)\.SETUP/\1/'`
	if [ -z $SINGLE_PACK ]; then
	    setup_pack $runme $ARCHIVE $1
	else
	    
	    if [ "$SINGLE_PACK" == "$ARCHIVE" ]; then
		echo "Found archive $ARCHIVE"
		setup_pack $runme $ARCHIVE $1
	    fi
	fi
    done

    LOCALDIRS=`ls -l --time-style=+ | grep ^d | awk '{print $6}' | sed ':a;N;$!ba;s/\n/ /g'` 
    for dirs in $LOCALDIRS
    do
	find_and_prepare_dir $dirs
    done
    popd
}



trap onexit 1 2 3 15 ERR


while getopts "ca:hm:e:p" opt; do
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
#    	shift
#    	shift
	c)
	    echo "Cleaning..."
 	    . $PREREQ_CFG
	    if [ "${PREREQ_dir_TMP}" = "" ]; then
		echo "PREREQ_dir_TMP not set?"
		exit
	    fi
	    if [ -d ${PREREQ_dir_TMP} ]; then
		echo "rm -rf ${PREREQ_dir_TMP}/*"
		rm -rf ${PREREQ_dir_TMP}/*
	    else
		eval $COLOR_RED
		echo "Can't find ${PREREQ_dir_TMP}"
		eval $COLOR_NORMAL
	    fi
	    exit
	    ;;
   	b)
	    eval $COLOR_YELLOW
    	    REPO_BASE=${OPTARG}
	    echo "using repo base of: $REPO_BASE"
	    eval $COLOR_NORMAL
#    	shift
#    	shift
    	;;
	a) 
	    eval $COLOR_YELLOW
	    echo "Cross-build for architecture: $OPTARG"
	    eval $COLOR_NORMAL
	    FORCE_ARCH=$OPTARG
	    ;;
	p)
	    eval $COLOR_YELLOW
	    echo "PRETEND MODE..."
	    eval $COLOR_NORMAL
	    PRETEND_MODE="1"
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

shift $(($OPTIND - 1))

if [ $# -gt 0 ]; then
    eval $COLOR_YELLOW
    echo "Install package $1"
    eval $COLOR_NORMAL
    SINGLE_PACK="$1"
fi


# ensure setup of environment dirs
if [ ! -f $PREREQ_CFG ]; then
    eval $COLOR_RED
    echo "The setup file: $PREREQ_CFG is missing"
    echo "Make sure you are running the script from the top level directory of the project"
    eval $COLOR_NORMAL
    exit 1
fi

# bring in directory/setup variables..
. $PREREQ_CFG


if [ ! -z $FORCE_ARCH ]; then

    for x in $VALID_ARCHS; do
	if [ "$x" = "$FORCE_ARCH" ]; then
	    CHECK_2="1"
	fi
    done
    if [ -z $CHECK_2 ]; then
	eval $COLOR_RED
	echo "Arch: $FORCE_ARCH not listed in VALID_ARCHs"
	eval $COLOR_NORMAL
	exit 1
    fi
    CHECK_1=$(eval "echo \${${FORCE_ARCH}_EXPANDED_BASE}")
    if [ "$CHECK_1" = "" ]; then
	eval $COLOR_RED
	echo "Can't created directories. "echo \${${FORCE_ARCH}_EXPANDED_BASE}" is not set in $PREREQ_CFG"
	eval $COLOR_NORMAL
	exit 1
    fi
    for var in $PREREQ_DIRS
    do
	if [ ! -d $(eval "echo \${${FORCE_ARCH}_EXPANDED_BASE}")/$(eval "echo \${PREREQ_dir_${var}}") ]; then
	    eval $COLOR_BOLD 
	    echo "creating directory "$(eval "echo \${${FORCE_ARCH}_EXPANDED_BASE}")/$(eval "echo \${PREREQ_dir_${var}}")
	    eval $COLOR_NORMAL
	    mkdir -p $(eval "echo \${${FORCE_ARCH}_EXPANDED_BASE}")/$(eval "echo \${PREREQ_dir_${var}}")
	fi
    done
fi

for var in $PREREQ_DIRS
do
    if [ ! -d $(eval "echo \${PREREQ_dir_${var}}") ]; then
	eval $COLOR_BOLD 
	echo "creating directory "$(eval "echo \${PREREQ_dir_${var}}")
	eval $COLOR_NORMAL
	mkdir -p $(eval "echo \${PREREQ_dir_${var}}")
    fi
done


if [ -d `pwd`/$ARCHIVE_BASE ]; then
    find_and_prepare_dir `pwd`/$ARCHIVE_BASE
else
    eval $COLOR_RED
    echo "The setup file: $PREREQ_CFG is missing"
    echo "Make sure you are running the script from the top level directory of the project"
    eval $COLOR_NORMAL
    onerror "Can't find the base archive directory: $ARCHIVE_BASE"
fi

