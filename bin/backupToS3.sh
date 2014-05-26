#!/bin/bash
#
# Backup Script
#

print_usage()
{
    echo "Usage: $0 DIR[ DIR2 DIR3 ...]"
    echo "backups DIR(s) to an S3 bucket"
    echo " -L : log all ops to files (setup in .backupToS3.config)"
}

if [ ! -f $HOME/dev-tools/bin/commons.source ]; then
    echo "Error: where is your $HOME/dev-tools/bin directory. Can't find commons.source."
    echo "Set it up first: svn co https://izuma.repositoryhosting.com/svn/izuma_frzsoftware/dev-tools from your home dir"
    exit -1
fi

if [ ! -f $HOME/.backupToS3.config ]; then
    echo "Error: .backupToS3.config is not in $HOME"
    exit -1
fi

if [ $# -lt 1 ]; then
    print_usage
fi

source $HOME/dev-tools/bin/commons.source
source $HOME/.backupToS3.config


while getopts "hk:u:VW" opt; do                                 
    case $opt in        
	h)  
            print_usage
	    exit 1
	    ;;
	L)
	    LOG_ALL="1"
	    ;;
	:)
	    echo "Option - $OPTARG - Uknown"
	    exit 1
	    ;;
    esac
done


PATH=/usr/local/bin:/usr/bin:/bin:
DATE=`date +%Y-%m-%d_%Hh%Mm`                            # Datestamp e.g 2002-09-21
DOW=`date +%A`                                          # Day of the week e.g. Monday
DNOW=`date +%u`                                         # Day number of the week 1 to 7 where 1 represents Monday
DOM=`date +%d`                                          # Date of the Month e.g. 27
M=`date +%B`                                            # Month e.g January
W=`date +%V`                                            # Week Number e.g 37
VER=0.1                                                 # Version Number
HOST=`hostname`                                         # Hostname for LOG information
LOGFILE=$BACKUPDIR/$HOST-`date +%N`.log                 # Logfile Name
LOGERR=$BACKUPDIR/ERRORS_$HOST-`date +%N`.log           # Error log Name
BACKUPFILES=""

# Create required directories
if [ ! -e "$BACKUPDIR" ]                # Check Backup Directory exists.
then
mkdir -p "$BACKUPDIR"
fi


if [ ! -z $LOG_ALL ]; then
# IO redirection for logging.
    touch $LOGFILE
    exec 6>&1           # Link file descriptor #6 with stdout.
# Saves stdout.
    exec > $LOGFILE     # stdout replaced with file $LOGFILE.
    touch $LOGERR
    exec 7>&2           # Link file descriptor #7 with stderr.
# Saves stderr.
    exec 2> $LOGERR     # stderr replaced with file $LOGERR.
fi
# Functions

# Backup function: removes last weeks archive from S3, creates new tar.gz and sends to S3
SUFFIX=""
dobackup () {
#deletes the old backup
    OLD_FILE=`$S3CMD ls s3://"$S3BUCKET" | grep s3 | sed "s/.*s3:\/\/$S3BUCKET\//s3:\/\/$S3BUCKET\//" | grep "$DOW.$BASIC_NAME.tar.gz"`
    if [ "$OLD_FILE" != "" ]; then
	echo "Found old file: $OLD_FILE  Removing..."
	$S3CMD del $OLD_FILE
    fi
    tar cfz "$1" "$2"
    echo
    echo Backup Information for "$1"
    gzip -l "$1"
    echo
    $S3CMD put "$1" s3://"$S3BUCKET"
    return 0
}

# Run command before we begin
if [ "$PREBACKUP" ]
then
echo ======================================================================
echo "Prebackup command output."
echo
eval $PREBACKUP
echo
echo ======================================================================
echo
fi

echo ======================================================================
echo "All data enclosed in backup is confidential"
echo
echo Backup of Server - $HOST
echo ======================================================================

echo Backup Start Time: `date`
echo =================================================================

for DO_DIR in "$@"; do 
# Daily Backup
    BASIC_NAME=`basename $DO_DIR`
    TAR_FILE="$DATE.$DOW.$BASIC_NAME.tar.gz"
    echo "Daily Backup of Directory ( $DO_DIR ) --> $TAR_FILE"
    echo
    echo "Rotating last weeks Backup... ($BACKUPDIR/*.$DOW.$BASIC_NAME.tar.gz)"
    eval rm -fv "$BACKUPDIR/*.$DOW.$BASIC_NAME.tar.gz"
    echo
    dobackup "$BACKUPDIR/$TAR_FILE" "$DO_DIR" "$BASIC_NAME"
    BACKUPFILES="$BACKUPFILES $BACKUPDIR/$TAR_FILE"
    echo
    echo ----------------------------------------------------------------------
    echo Backup End Time: `date`
    echo ======================================================================
    echo Total disk space used for backup storage..
    echo Size - Location
    echo `du -hs "$BACKUPDIR"`
    echo
    echo ======================================================================
    echo ======================================================================
done

# Run command when we're done
if [ "$POSTBACKUP" ]
then
echo ======================================================================
echo "Postbackup command output."
echo
eval $POSTBACKUP
echo
echo ======================================================================
fi

if [ ! -z $LOG_ALL ]; then
#Clean up IO redirection
    exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
    exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.
fi

if [ "$MAILCONTENT" = "files" ]
then
    if [ -s "$LOGERR" ]
    then
# Include error log if is larger than zero.
	BACKUPFILES="$BACKUPFILES $LOGERR"
	ERRORNOTE="WARNING: Error Reported - "
    fi
#Get backup size
    ATTSIZE=`du -c $BACKUPFILES | grep "[[:digit:][:space:]]total$" |sed s/\s*total//`
    if [ $MAXATTSIZE -ge $ATTSIZE ]
    then
	BACKUPFILES=`echo "$BACKUPFILES" | sed -e "s# # -a #g"` #enable multiple attachments
	mutt -s "$ERRORNOTE MySQL Backup Log and SQL Files for $HOST - $DATE" $BACKUPFILES $MAILADDR < $LOGFILE       #send via mutt
    else
	cat "$LOGFILE" | mail -s "WARNING! - Backup exceeds set maximum attachment size on $HOST - $DATE" $MAILADDR
    fi
elif [ "$MAILCONTENT" = "log" ]
then
    cat "$LOGFILE" | mail -s "Backup Log for $HOST - $DATE" $MAILADDR
    if [ -s "$LOGERR" ]
    then
	cat "$LOGERR" | mail -s "ERRORS REPORTED: MySQL Backup error Log for $HOST - $DATE" $MAILADDR
    fi
elif [ "$MAILCONTENT" = "quiet" ]
then
    if [ -s "$LOGERR" ]
    then
	cat "$LOGERR" | mail -s "ERRORS REPORTED: Backup error Log for $HOST - $DATE" $MAILADDR
	cat "$LOGFILE" | mail -s "Backup Log for $HOST - $DATE" $MAILADDR
    fi
else
    if [ -s "$LOGERR" ]
    then
	cat "$LOGFILE"
	echo
	echo "###### WARNING ######"
	echo "Errors reported during Backup execution.. Backup failed"
	echo "Error log below.."
	cat "$LOGERR"
    else
	cat "$LOGFILE"
    fi
fi

if [ -s "$LOGERR" ]
then
    STATUS=1
else
    STATUS=0
fi

# Clean up Logfile
eval rm -f "$LOGFILE"
eval rm -f "$LOGERR"

exit $STATUS