#!/bin/bash

function print_usage () {
	echo "generate JNI headers"
	echo "$0 [-p JAVAP-path] [-j JAVAH-path] [-c CLASSPATH] LIST"
	echo "format of LIST should be:"
	echo "\"header-Class1.h:package.here.there.Class1 header-Class2.h:package.here.there2.Class2\"" 
	echo "will make headers: JNI_header-Class1.h & JNI_header-Class2.h"
}

SYSTYPE="$(eval "uname | cut -c 1-4")"

case "$SYSTYPE" in 
    Darw)
# OS X seems to not like this anymore
#	COLOR_BOLD="echo -n '\\[1m'"
#	COLOR_RED="echo -n '\\[31m'"
#	COLOR_MAGENTA="echo -n '\\[35m;'"
#	COLOR_YELLOW="echo -n '\\[33m'"
#	COLOR_GREEN="echo -n '\\[32m'"
#	COLOR_NORMAL="echo -n '\\[0m'"
	;;
    Linu|CYGW)   
	COLOR_BOLD="echo -ne '\E[1m'"
	COLOR_RED="echo -ne '\E[31m'"
	COLOR_MAGENTA="echo -ne '\E[35m'"
	COLOR_YELLOW="echo -ne '\E[33m'"
	COLOR_GREEN="echo -ne '\E[32m'"
	COLOR_NORMAL="echo -ne '\E[0m'"
	;;
esac

JAVAH="/usr/bin/javah"
JAVAP="/usr/bin/javap"

if [ $# == 0 ]; then
    print_usage
    exit
fi

####### ENTRY POINT ######
while getopts  "c:j:p:" flag 
do
	case "${flag}" in
		c)
			CLASSPATH=${OPTARG} 
			;;
		j)
			JAVAH=${OPTARG} 
			;;
		p)
			JAVAP=${OPTARG} 
			;;
        *)
			print_usage
			exit
			;;
	esac
done            

shift $(($OPTIND - 1))


# for regular expression in bash, refer http://tldp.org/LDP/abs/html/string-manipulation.html
if [ ! -z $CLASSPATH ]; then
	echo "CLASSPATH = ${CLASSPATH}"
fi

LIST=$@
eval $COLOR_BOLD
echo "Generating headers with javah(${JAVAH})"
eval $COLOR_NORMAL

JAVATOHEADER=`dirname $0`
JAVAPARSE="perl -w $JAVATOHEADER/findclassjavap.pl"
JAVATOHEADER="perl -w $JAVATOHEADER/javahtoheader.pl"


for pair in $LIST
do
    # if we have a classpath - do some extra work...
	if [ ! -z $CLASSPATH ]; then
	    SKIP=""
	    HDRFILE=JNI_${pair%%:*}
	    CLSFILE=${pair##*:}
	    CLSFILE=$CLASSPATH/${CLSFILE//\./\/}.class
	    # compare file dates..
	    if [ -e $CLSFILE ] && [ -e $HDRFILE ]; then
		DATECLS=$(stat --printf=%Y $CLSFILE)
		DATEHDR=$(stat --printf=%Y $HDRFILE)
		if (( DATECLS > DATEHDR ))
		then
		    echo "generating $HDRFILE"
		else
		    echo "skipping $HDRFILE, up to date"
		    SKIP="1"
		fi
	    else
		echo "Existing header $HDRFILE or .class could not be found. Generating..."
	    fi
	    # done with date compare
	    if [ -z $SKIP ]; then
	    ${JAVAH} -jni -classpath ${CLASSPATH} -o JNI_${pair%%:*} ${pair##*:}
	    # this just deletes the last line (to get rid of the final #endif)
	    sed '$d' < JNI_${pair%%:*} > JNI_${pair%%:*}.tmp ; mv JNI_${pair%%:*}.tmp JNI_${pair%%:*}
	    for clz in `cat JNI_${pair%%:*} | $JAVAPARSE`
	    do
		eval $COLOR_BOLD
		echo "Found class: $clz"
		eval $COLOR_NORMAL
		echo "// ********* javatoheader.pl output *********" >> JNI_${pair%%:*}
		${JAVAP} -s -private -classpath ${CLASSPATH} $clz | $JAVATOHEADER >> JNI_${pair%%:*}
	    done
	    echo "#endif" >>  JNI_${pair%%:*}
	    fi
	else
	    # if we don't have a classpath - then generate all files irregardless
	    ${JAVAH} -jni -o JNI_${pair%%:*} ${pair##*:}
	    # this just deletes the last line (to get rid of the final #endif)
	    sed '$d' < JNI_${pair%%:*} > JNI_${pair%%:*}.tmp ; mv JNI_${pair%%:*}.tmp JNI_${pair%%:*}
	    for clz in `cat JNI_${pair%%:*} | $JAVAPARSE`
	    do
		eval $COLOR_BOLD
		echo "Found class: $clz"
		eval $COLOR_NORMAL
		echo "// ********* javatoheader.pl output *********" >> JNI_${pair%%:*}
		${JAVAP} -s -private $clz | $JAVATOHEADER >> JNI_${pair%%:*}		    
	    done
	    echo "#endif" >>  JNI_${pair%%:*}
	fi
done

