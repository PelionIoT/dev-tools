#!/bin/bash

if [ ! -f $HOME/dev-tools/bin/commons.source ]; then
    echo "Error: where is your $HOME/dev-tools/bin directory. Can't find commons.source."
    echo "Set it up first: svn co https://izuma.repositoryhosting.com/svn/izuma_frzsoftware/dev-tools from your home dir"
    exit -1
fi

source $HOME/dev-tools/bin/commons.source
source $HOME/dev-tools/bin/html-logger.sh

# workspace dir
WSPACE_DIR="$HOME/workspace"
BLD_CFG="builder.cfg"

# the manifest should be in the top of your workspace directory
BUILDER_MANIFEST="autobuilder.lst"
BUILDER_USER_FILE=".auto-builder"
# out main output file
ANT_OUTFILE="builder.xml"

THIS_OUTPUT_DIRS=""

LOG_DIR="$HOME/tmp"

LOG_FILE="$LOG_DIR/builder-output.html"
THIS_DIR=""

BUILD_HTMLOUT=""



function print_usage () {
	echo "$0 [Options] project-name target:{compile|clean|rebuild}"
	echo "   -w [dir]    Set workspace directory to [dir] (Default: $WSPACE_DIR)"
	echo "   -H [file]   Output results as HTML to [file]"
	echo "   defaut: no target = compile"
}


function fail_politely () {
    eval $COLOR_RED
    echo "Failure: $1"
    eval $COLOR_NORMAL
    exit 255
}


while getopts "hw:l:H:" opt; do
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
	w)
	    WSPACE_DIR="$OPTARG"
	    ;;
	H)
	    BUILD_HTMLOUT="$OPTARG"
	    # make the file, in case its not there...
	    touch $BUILD_HTMLOUT
	    ;;
	\?) 
	    eval $COLOR_RED
	    echo "Unknown option. $OPTARG"
	    eval $COLOR_NORMAL
	    exit 1
	    ;;
	:)
	    eval $COLOR_RED
	    echo "Option -$OPTARG requires an argument"
	    eval $COLOR_NORMAL
	    exit 1
	    ;;
    esac
done

shift $(($OPTIND - 1))

if [ $# -gt 0 ]; then
    eval $COLOR_BOLD
    echo "Build package: $1"
    BUILD_ONLY="$1"
    eval $COLOR_NORMAL
else
    eval $COLOR_BOLD
    echo "Build all packages."
    eval $COLOR_NORMAL
fi

if [ ! -z "$BUILD_HTMLOUT" ]; then
    eval $COLOR_BOLD
    echo "Logging output to $BUILD_HTMLOUT"
    eval $COLOR_NORMAL
    if [ -f "$BUILD_HTMLOUT" ]; then
	rm -f "$BUILD_HTMLOUT" 
	eval $COLOR_YELLOW
	echo "Removed old $BUILD_HTMLOUT  ."
	eval $COLOR_NORMAL
	touch "$BUILD_HTMLOUT"
    fi
    HTML_LOGGER_FILE="$BUILD_HTMLOUT"
fi


if [ ! -f "$WSPACE_DIR/$BUILDER_MANIFEST" ]; then
    log_error "Could not find $WSPACE_DIR/$BUILDER_MANIFEST - check your settings / workspace directory."
    exit 255
fi

CHK_DIR=`basename $LOG_FILE`
if [ -d "$CHK_DIR" ]; then
    mkdir -p "$CHK_DIR"
fi

if [ -e "$LOG_FILE" ]; then
    log_warning "Removing old $LOG_FILE"
    rm -f "$LOG_FILE"
    touch "$LOG_FILE"
fi

if [ ! -f "$HOME/$BUILDER_USER_FILE" ]; then
    log_error "Could not find $HOME/$BUILDER_USER_FILE - check your settings / workspace directory."
    exit 255
fi


source "$HOME/$BUILDER_USER_FILE"
source "$WSPACE_DIR/$BUILDER_MANIFEST"

if [ -z "$MANIFEST" ]; then
    log_error "$WSPACE_DIR/$BUILDER_MANIFEST did not have a MANIFEST variable defined. That's not gonna work..."
fi

# check out each project
pushd $WSPACE_DIR

for PROJ in $MANIFEST; do 
    log_sectionhead "Processing directory $(eval "echo \$DIRNAME_${PROJ}") ($PROJ)"
    if [ ! -z "$(eval "echo \$DIRNAME_${PROJ}")" ] && [ ! -z "$(eval "echo \$PROJURL_${PROJ}")" ]; then
	echo "processing..."
	PRJDIR_NAME="$WSPACE_DIR/$(eval "echo \$DIRNAME_${PROJ}")"
	if [ -d "$(eval "echo \$DIRNAME_${PROJ}")" ]; then
	    log_important "Updating..."
	    pushd "$(eval "echo \$DIRNAME_${PROJ}")"
	    if [ -z "$BUILD_HTMLOUT" ]; then
		svn --username $SVN_USER --password $SVN_PASS update
	    else
		svn --username $SVN_USER --password $SVN_PASS update 2>&1 | html-expandoutput.pl >> "$BUILD_HTMLOUT"
	    fi
	    popd
	else
	    log_important "Initial checkout..."
	    if [ -z "$BUILD_HTMLOUT" ]; then
		svn --username $SVN_USER --password $SVN_PASS co $(eval "echo \$PROJURL_${PROJ}") $(eval "echo \$DIRNAME_${PROJ}")
	    else
		svn --username $SVN_USER --password $SVN_PASS co $(eval "echo \$PROJURL_${PROJ}") $(eval "echo \$DIRNAME_${PROJ}") 2>&1 | html-expandoutput.pl >> "$BUILD_HTMLOUT"
	    fi
	fi
	pushd "$(eval "echo \$DIRNAME_${PROJ}")"
	if [ -f "$FRZ_MANIFEST_LST" ]; then
	    if [ -z "$BUILD_HTMLOUT" ]; then
		update-prereqs.sh
	    else
		update-prereqs.sh 2>&1 | html-expandoutput.pl >> "$BUILD_HTMLOUT"
	    fi
	fi
	if [ -f "$FRZ_EXPAND_CFG" ]; then
	    if [ -z "$BUILD_HTMLOUT" ]; then
		expand-prereqs.sh
	    else
		expand-prereqs.sh 2>&1 | html-expandoutput.pl >> "$BUILD_HTMLOUT"
	    fi
	fi
	if [ -z "$NO_BUILD" ]; then
	    if [ -f "$PRJDIR_NAME/$BLD_CFG" ]; then
		source "$PRJDIR_NAME/$BLD_CFG"
		if [ "$PROJ_TYPE" == "java" ]; then
		    log_important "Project is a java project..."
		    log_sectionhead "BUILDING: $MY_NAME"
		    if [ -z "$BUILD_HTMLOUT" ]; then
			builder-java.sh $MY_NAME clean
			builder-java.sh $MY_NAME compile
		    else
			builder-java.sh -H "$BUILD_HTMLOUT" $MY_NAME clean
			builder-java.sh -H "$BUILD_HTMLOUT" $MY_NAME compile
		    fi
		fi
	    else
		log_error "Project in dir $PRJDIR_NAME is missing a $BLD_CFG file."
	    fi
	fi
	popd
    else
        log_error "Project entry $PROJ is missing a DIRNAME or PROJURL var. Check $WSPACE_DIR/$BUILDER_MANIFEST."
    fi
done



popd

