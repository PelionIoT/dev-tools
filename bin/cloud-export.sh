#!/bin/bash

# Export Framez directories to cloud service server
# for cloud dev purposes

if [ ! -f $HOME/dev-tools/bin/commons.source ]; then
    echo "Error: where is your $HOME/dev-tools/bin directory. Can't find commons.source."
    echo "Set it up first: svn co https://izuma.repositoryhosting.com/svn/izuma_frzsoftware/dev-tools from your home dir"
    exit -1
fi

source $HOME/dev-tools/bin/commons.source


EXPORTF="export-bin.lst"
MANIFESTLST="manifest.lst"
UPDATE_PREREQS="update-prereqs.sh"
REMOTE_MD5="exports-remote.md5"
MD5_FILENAME="checksum.lst"
USER_NAME=$USER
SUMFILE=`basename $0`.sums.$$.tmp
TEMPREMOTESUM=`basename $0`.remote.md5.$$.tmp
LOOKUP_SCRIPT=`basename $0`.lookup.sh.$$.tmp
DIRFILE=`basename $0`.dirlist.$$.tmp
RSYNCLIST=`basename $0`.rsynclst.$$.tmp

function cleanup() {
#    set -o noglob
    set +o noglob
    rm -f *.$$.tmp
    # rm -f $SUMFILE
    # rm -f *.remote.md5
    # rm -f *.sums.tmp
    # rm -f $LOOKUP_SCRIPT
    # rm -f $DIRFILE
    # rm -f $RSYNCLIST
    eval $COLOR_NORMAL
}

function print_usage() {
    echo "$0 -k SSHKEYFILE USER@HOST REMOTEBASEDIR DIR [DIR2 ...]"
    echo "-k KEYFILE  - SSH private key file for login"
    echo "-V          - Verify: runs an MD5 checksum verification"
    echo "-W          - Without prereqs... otherwise the script will also"
    echo "              sync prereqs dir using manifest.lst"
#    echo "-u USER     - username to use, otherwise default is $USER"
    echo "REMOTEBASEDIR is absolute path directory to export everything on remote host"
    echo "... followed by list of local directories to sync with. "
    echo "LOCAL always takes precedence over REMOTE. "
    echo "Only directories listed in $EXPORTF are exported to remote end."
    echo "needs: ssh, scp, md5sum" 
}


function trim()
{
    trimmed="$@"
    trimmed=${trimmed%% }
    trimmed=${trimmed## }

    echo $trimmed
}

function warn_on_file()
{
    eval $COLOR_RED
    echo "Failed on file: $1"
    eval $COLOR_NORMAL
}

# function produce_md5_file() {
#     if [ -f $MD5_FILENAME ]; then
# 	rm -f $MD5_FILENAME || onerror "Could not remove $MD5_FILENAME"
# 	touch $MD5_FILENAME
#     fi
    
#     for F in  `ls -l | grep ^- | awk '{print $8}'` 
#     do
# 	if [ "$F" != "$MD5_FILENAME" ]; then
# 	    md5sum $F >> $MD5_FILENAME
# 	fi
#     done
    
# }

# parameters: DIR WILDCARD OUTFILE 
function find_export_files() {
#    echo "find $1 -name \\$2 -exec md5sum {} >> $3 \\;"

    if [ ! -d "$1/$2" ]; then
	if [ -f "$1/$2" ]; then
	    echo "$1/$2 is not a dir, but is a file."
	    md5sum $1/$2 >> $3
	else
	    echo "Skipping $1/$2 - its not a dir or file"
	fi
    else

	LIST=$3

# Add a trailing comma to the list variable
	LOOPVAR=${LIST},


# go through a comma separated list of values (wildcard values)
# Loop as long as there is a comma in the variable 
	while echo $LOOPVAR | grep \, &> /dev/null
	do
	    
# Grab one item out of the list
	    
	    LOOPTEMP=${LOOPVAR%%\,*}
	    
#    echo "find $1/$2 -name \\$LOOPTEMP -exec md5sum {} >> $4 \\;"
	    echo "Looking in $1/$2 for $LOOPTEMP"
	    find $1/$2 -name $LOOPTEMP -exec md5sum {} >> $4 \; 2>/dev/null
#    find $1/$2 -name \\$LOOPTEMP -print -exec md5sum \;
	    
# Remove the item we just grabbed from the list,
# as well as the trailing comma
	    LOOPVAR=${LOOPVAR#*\,}
	    
# some action with your variable
#
# echo $LOOPTEMP
#
# for example
	
	done
	
    fi
}

function find_remote_files() {
    # make sure file exists...

    if [ ! -d "$1/$2" ]; then
	if [ -f "$1/$2" ]; then
	    echo "$1/$2 is not a dir, but is a file."
	    ssh -n -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE && touch $3 && md5sum $1/$2 >> $3"
	else
	    echo "Skipping $1/$2 - its not a dir or file. Or its missing on local."
	fi
    else
    ssh -n -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE && touch $4"
#    echo "find $1 -name \\$2 -exec md5sum {} >> $3 \\;"


    LIST=$3

# Add a trailing comma to the list variable
    LOOPVAR=${LIST},


# go through a comma separated list of values (wildcard values)
# Loop as long as there is a comma in the variable 
    while echo $LOOPVAR | grep \, &> /dev/null
    do
	
# Grab one item out of the list

	LOOPTEMP=${LOOPVAR%%\,*}
	
#    echo "find $1/$2 -name \\$LOOPTEMP -exec md5sum {} >> $4 \\;"
    echo "Looking in $1/$2 for $LOOPTEMP on REMOTE"
#    find $1/$2 -name $LOOPTEMP -exec md5sum {} >> $4 \;

#    echo "ssh -i $KEY_FILE $REMOTE_HOST \"cd $REMOTE_BASE && find $1/$2 -name $LOOPTEMP -exec md5sum {} >> $4 \;\""
    ssh -n -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE && find $1/$2 -name $LOOPTEMP -exec md5sum {} >> $4 \;" || bold_echo "Failed on remote find for $1/$2"

#    find $1/$2 -name \\$LOOPTEMP -print -exec md5sum \;
    
# Remove the item we just grabbed from the list,
# as well as the trailing comma
	LOOPVAR=${LOOPVAR#*\,}
	
# some action with your variable
#
# echo $LOOPTEMP
#
# for example
	
    done
    fi
}



#parameter $1 -> DIR
function verify_sums()
{
   cat $1.$SUMFILE | while read lne; do

	NAME=`echo "$lne" | awk '{print $2}'`
	D_NAME=`dirname $NAME`
#	echo $NAME
	
	

	cat > $LOOKUP_SCRIPT <<EOF
awk -vLOOKUPVAL='$NAME' '\$2 == LOOKUPVAL { print \$1 }' < \$1
EOF

        LOCAL=`source $LOOKUP_SCRIPT $1.$SUMFILE`
	REMOTE=`source $LOOKUP_SCRIPT $1.$TEMPREMOTESUM`

	if [ -z $REMOTE ]; then
	    eval $COLOR_MAGENTA
	    echo "MISSING on remote: `basename $NAME`"
	    eval $COLOR_NORMAL
#	    echo "      --> REMOTE:$REMOTE_BASE/$NAME"
#	    eval $COLOR_NORMAL	

#	    echo "cat $NAME | ssh -i $KEY_FILE $REMOTE_HOST \"cd $REMOTE_BASE && mkdir -p $D_NAME && cat >> $NAME\""

#	    cat $NAME | ssh -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE && mkdir -p $D_NAME && cat >> $NAME" || warn_on_file $NAME
	else 
	    if [ $LOCAL != $REMOTE ]; then
		eval $COLOR_MAGENTA
		echo "DIFFERS: $NAME --> REMOTE:$REMOTE_BASE/$NAME"
		eval $COLOR_NORMAL
#		scp -i $KEY_FILE $NAME $REMOTE_HOST:$REMOTE_BASE/$NAME || warn_on_file $NAME
	    else
		echo "ok: $NAME"
	    fi
	fi

    done

}


#parameters: relative-dir wildcard,wilcard,wildcard...
#            $1           $2
# creates file called $RSYNCLIST
function prep_includelist()
{
    # prep list - don't include junk...
    cat > $RSYNCLIST <<EOF
- .*
- *.log
- *.tmp
EOF

    LIST=$2
    # Add a trailing comma to the list variable
    LOOPVAR=${LIST},
# go through a comma separated list of values (wildcard values)
# Loop as long as there is a comma in the variable 
    while echo $LOOPVAR | grep \, &> /dev/null
    do
# Grab one item out of the list
	LOOPTEMP=${LOOPVAR%%\,*}
	echo "Looking in $1 for $LOOPTEMP"
	echo "+ $LOOPTEMP" >> $RSYNCLIST

	
#	find $1/$2 -name $LOOPTEMP -exec md5sum {} >> $4 \;
# Remove the item we just grabbed from the list,
# as well as the trailing comma
	LOOPVAR=${LOOPVAR#*\,}
    done
#    echo "- *" >> $RSYNCLIST
    echo "- .*" >> $RSYNCLIST
    echo "- *~" >> $RSYNCLIST

#    rm $RSYNCLIST
}


trap onexit 1 2 3 15 ERR

while getopts "hk:u:VW" opt; do
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
	V)
	    VERIFY="1"
	    ;;
	W)
	    NOPREREQS="1"
	    ;;
	k)
	    KEY_FILE=$OPTARG
	    ;;
	u)  
	    USER_NAME=$OPTARG
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

if [ $# -lt 3 ]; then
    print_usage
    exit
fi

REMOTE_HOST=$1
REMOTE_BASE=$2

shift
shift

if [ -z $KEY_FILE ]; then
    onexit -1 "Must have a KEYFILE"
fi

if [ ! -f "$KEY_FILE" ]; then
    onexit -1 "Can't find $KEY_FILE"
fi


touch $SUMFILE
touch $DIRFILE
# generate one file with all the md5sums for everything we are exporting
for D in "$@"
do
    if [ ! -f "$D/$EXPORTF" ]; then
	cleanup
	onexit -1 "Can't find the $EXPORTF file for $D directory. Failing."
    fi
    
    # read each line, add the files in for this line

    set -o noglob

    cat $D/$EXPORTF | while read name; do
#    echo "line: ${name}"
#	LINENUM=$(( $LINENUM + 1 ))
	P=$(trim $name)
#	echo "****** P= $P"
	P=${P/#\#*/"-"}    
	if [ "${P}" == "-" ]; then   # skip comments
	    continue
	fi
	if [ "${P}" == "" ]; then    # skip blank lines
	    continue
	fi
#    echo "line: ${P}"

    
    find_export_files $D ${P} $D.$SUMFILE

    if [ ! -z $VERIFY ]; then
    # create a checksum file on the remote side...
	find_remote_files $D ${P} $D.$TEMPREMOTESUM
    fi

    # add it to the DIRFILE also
    # DIRFILE is formatted:
    #  dir-name/some/path wildcard,wildcard,...
    echo "$D/${P}" >> $DIRFILE
	
#	if [ -f $EXP_DIR/$GLOBAL_ERROR_FILE ]; then
#	    break
#	fi
    done
    
done





#scp -i $KEY_FILE $REMOTE_HOST:$REMOTE_BASE/$REMOTE_MD5 $TEMPREMOTESUM || echo "No remote checksum."



if [ ! -z $VERIFY ]; then
    for D in "$@"
    do
	scp -C -i $KEY_FILE $REMOTE_HOST:$REMOTE_BASE/$D.$TEMPREMOTESUM $D.$TEMPREMOTESUM && FOUNDCHECKSUM="1" || bold_echo "No remote checksums for $D."
    # remove file on far-end
	ssh -n -i $KEY_FILE $REMOTE_HOST "rm $REMOTE_BASE/$D.$TEMPREMOTESUM" || bold_echo "Failed to remove remote $D.$TEMPREMOTESUM"
	
	eval $COLOR_BOLD
	echo "Verification on $D..."
	eval $COLOR_NORMAL
	verify_sums $D
	
    done
    
    cleanup
    
    exit
else
    for D in "$@"
    do
	scp -C -i $KEY_FILE $REMOTE_HOST:$REMOTE_BASE/$D.$REMOTE_MD5 $D.$TEMPREMOTESUM && FOUNDCHECKSUM="1" || bold_echo "No remote checksums for $D."
    done
fi


if [ ! -z $FOUNDCHECKSUM ]; then
    eval $COLOR_BOLD
    echo "Found remote checksums. Syncing files..."
    eval $COLOR_NORMAL

#    NAME=`echo "$lne" | awk '{print $2}'`
#    echo $NAME

    cat $DIRFILE | while read lne; do
	P=$(trim $lne)
	LNE=(${P// / })
	D_NAME="${LNE[0]}"
#	echo "******** LINE $lne  -> $D_NAME"
	if [ ! -d $D_NAME ]; then
	    eval $COLOR_BOLD
	    echo "COPY: $REMOTE_BASE/$D_NAME --> REMOTE"
	    eval $COLOR_NORMAL
	    
#    This breaks 'read': cat $D_NAME | ssh -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE && mkdir -p `dirname $D_NAME` && cat >> $D_NAME" || warn_on_file $NAME
# This is b/c ssh without -n will try to read from stdin - which is already being used in the read loop

	    ssh -n -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE && mkdir -p `dirname $D_NAME`" || warn_on_file $NAME
	    scp -C -p -i $KEY_FILE $D_NAME $REMOTE_HOST:$REMOTE_BASE/$D_NAME || warn_on_file $NAME
	else
            # run rsync:
	    prep_includelist $P
#	    echo "rsync -avPc --exclude-from $RSYNCLIST -e ssh -i $KEY_FILE $D_NAME/ $REMOTE_HOST:$REMOTE_BASE/`dirname $D_NAME`"
	    echo "REMOTE: mkdir $REMOTE_BASE/$D_NAME"
	    ssh -n -i $KEY_FILE $REMOTE_HOST "mkdir -p $REMOTE_BASE/$D_NAME" 
	    eval $COLOR_BOLD
	    echo "Syncing dir: $D_NAME"
	    eval $COLOR_NORMAL
	#    echo "rsync $REMOTE_BASE/$D_NAME --> REMOTE"
	    rsync -avPc --recursive --exclude-from $RSYNCLIST -e "ssh -i $KEY_FILE" $D_NAME/ $REMOTE_HOST:$REMOTE_BASE/$D_NAME
	fi	

    done




#     cat $DIRFILE | while read lne; do
# 	P=$(trim $lne)
# 	LNE=(${P// / })
# 	D_NAME="${LNE[0]}"
# 	if [ ! -d $D_NAME ]; then
# 	    echo "COPY: $REMOTE_BASE/$D_NAME --> REMOTE"
		
# 	    ssh -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE && mkdir -p `dirname $D_NAME`" || warn_on_file $NAME
# 	    scp -i $KEY_FILE $D_NAME $REMOTE_HOST:$REMOTE_BASE/$D_NAME  || warn_on_file $NAME
# 	else
# 	    prep_includelist $lne
# #	cat $RSYNCLIST
	    
#             # run rsync:
	    
# 	    echo "REMOTE: mkdir $REMOTE_BASE/$D_NAME"
# 	    ssh -i $KEY_FILE $REMOTE_HOST "mkdir -p $REMOTE_BASE/$D_NAME" 
# 	    echo "rsync $REMOTE_BASE/$D_NAME --> REMOTE"
# 	    eval $COLOR_BOLD
# 	    echo "Syncing DIR: $D_NAME"
# 	    eval $COLOR_NORMAL
# 	    rsync -avPc --recursive --exclude-from $RSYNCLIST -e "ssh -i $KEY_FILE" $D_NAME/ $REMOTE_HOST:$REMOTE_BASE/$D_NAME
	    
	    
# 	fi
#     done
    
    
else
    eval $COLOR_BOLD
    echo "Did not retrieve remote checksum file: $REMOTE_HOST:$REMOTE_BASE/$REMOTE_MD5"
    eval $COLOR_YELLOW
    echo "Verify your are in the right directory. Your are in `pwd`"
    echo "Upload all? (y/n)"
    read YN
    case $YN in
	[yY]*) 
	    echo "OK. Uploading all..."
	    eval $COLOR_NORMAL

# 	    cat $SUMFILE | while read lne; do

# 		NAME=`echo "$lne" | awk '{print $2}'`
# 		D_NAME=`dirname $NAME`
		
# 		echo "Uploading `basename $NAME` --> REMOTE:$REMOTE_BASE/$NAME" 
		
# #		echo "cat $NAME | ssh -i $KEY_FILE $REMOTE_HOST \"cd $REMOTE_BASE && mkdir -p $D_NAME && cat >> $NAME\""

# 		cat $NAME | ssh -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE && mkdir -p $D_NAME && cat >> $NAME" || warn_on_file $NAME
		
# #		echo rsync -avce "ssh -i $KEY_FILE "

# #		echo scp -i $KEY_FILE $NAME $REMOTE_HOST:$REMOTE_BASE/$NAME 
# 	    done	    
	    echo


	    ;;
	[nN]*) 	    
	    echo "OK. Failing."
	    cleanup
	    exit
	    ;;
    esac
    eval $COLOR_NORMAL

    while read lne; do
	P=$(trim $lne)
	LNE=(${P// / })
	D_NAME="${LNE[0]}"
#	echo "******** LINE $lne  -> $D_NAME"
	if [ ! -d $D_NAME ]; then
	    echo "COPY: $REMOTE_BASE/$D_NAME --> REMOTE"
	    
#    This breaks 'read': cat $D_NAME | ssh -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE && mkdir -p `dirname $D_NAME` && cat >> $D_NAME" || warn_on_file $NAME
# who knows why... b/c bash sucks.
	    ssh -n -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE && mkdir -p `dirname $D_NAME`" || warn_on_file $NAME
	    scp -C -p -i $KEY_FILE $D_NAME $REMOTE_HOST:$REMOTE_BASE/$D_NAME  || warn_on_file $NAME
	else
            # run rsync:
	    prep_includelist $P
#	    echo "rsync -avPc --exclude-from $RSYNCLIST -e ssh -i $KEY_FILE $D_NAME/ $REMOTE_HOST:$REMOTE_BASE/`dirname $D_NAME`"
	    echo "REMOTE: mkdir $REMOTE_BASE/$D_NAME"
	    ssh -n -i $KEY_FILE $REMOTE_HOST "mkdir -p $REMOTE_BASE/$D_NAME" 
	    echo "rsync $REMOTE_BASE/$D_NAME --> REMOTE"
	    rsync -avPc --recursive --exclude-from $RSYNCLIST -e "ssh -i $KEY_FILE" $D_NAME/ $REMOTE_HOST:$REMOTE_BASE/$D_NAME
	fi	

    done <$DIRFILE

fi


echo "Uploading new checksums."
#echo scp -C -i $KEY_FILE $SUMFILE $REMOTE_HOST:$REMOTE_BASE/$REMOTE_MD5

for D in "$@"
do
    scp -C -i $KEY_FILE $D.$SUMFILE $REMOTE_HOST:$REMOTE_BASE/$D.$REMOTE_MD5
done

if [ -z $NOPREREQS ]; then

    for D in "$@"
    do
	if [ -e "$D/$MANIFESTLST" ]; then
	    scp -C -p -i $KEY_FILE $D/$MANIFESTLST $REMOTE_HOST:$REMOTE_BASE/$D 
	    ssh -n -i $KEY_FILE $REMOTE_HOST "cd $REMOTE_BASE/$D && $UPDATE_PREREQS" || bold_echo "Failed to run REMOTE $UPDATE_PREREQS for dir $D"
	else
	    echo "No prereqs $MANIFESTLST for $D"
	fi
    done
fi

cleanup
echo "Done."


