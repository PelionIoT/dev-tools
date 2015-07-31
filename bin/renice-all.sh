#!/bin/bash

if [ $# -lt 1 ]; then
    print_usage
fi

source $HOME/dev-tools/bin/commons.source
source $HOME/.backupToS3.config

AMOUNT="+1"

print_usage()
{
    echo "Usage: $0 process-name [process-name ... ]"
    echo " -a AMOUNT   where AMOUNT is a renice value like '-1' or '+5'"
}


while getopts "ha:" opt; do                                 
    case $opt in        
	a)  AMOUNT="$OPTARG"
	    ;;
	h)  
            print_usage
	    exit 1
	    ;;
	:)
	    echo "Option - $OPTARG - Uknown"
	    exit 1
	    ;;
    esac
done

shift $(($OPTIND - 1))

if [ $# -lt 1 ]; then
    print_usage
    exit
fi


for arg in "$@"
do
    PIDS=`pidof $1`
    echo "Renice process: $arg ($PIDS) by $AMOUNT"
    for pid in $PIDS
    do
	sudo renice $AMOUNT -p $pid
    done
    
done


