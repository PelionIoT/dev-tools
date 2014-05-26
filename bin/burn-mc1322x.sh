#!/bin/bash

# tool for burning econotags and friends...

. $HOME/dev-tools/bin/commons.source

LOADER_PL="$HOME/workspace/frz-contiki/cpu/mc1322x/tools/mc1322x-load.pl"
FLASHER="$HOME/work/libmc1322x/tests/flasher_redbee-econotag.bin"
BBMC="$HOME/workspace/frz-contiki/cpu/mc1322x/tools/ftditools/bbmc"
HEX=""
PROFILE="redbee-econotag"
DEVPORT="/dev/ttyUSB1"

function print_usage() {
    echo "$0 {options} [.bin binary to burn to mc1322x]"
    echo "OPTIONS:"
    echo "-L {path}    Full path to 'mc1322x-load.pl' script."
    echo "-F {path}    Full path to flasher binary."
    echo "-B {path}    Full path to bbmc binary."
    echo "-P {profile} bbmc board profile (See libmc1322x docs)"
    echo "-D {dev}     serial device of mc1322x (default: $DEVPORT)"
    echo "-X {hex}     values in hex you want burned after the binary file."
    echo "-e Exit      when done / versus terminal."
    echo "                Default profile: $PROFILE"

}

while getopts "hL:F:B:X:P:D:" opt; do
    case $opt in
	h)
	    print_usage
	    exit
	;;
	L)
	    LOADER_PL=$OPTARG
	    ;;
	F)
	    FLASHER=$OPTARG
	    ;;
	B)
	    BBMC=$OPTARG
	    ;;
	X)  
	    HEX=$OPTARG
	    ;;
	P)  
	    PROFILE=$OPTARG
	    ;;
	D)
	    DEVPORT=$OPTARG
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

if [ $# -lt 1 ]; then
    print_usage
    exit
fi

if [ ! -e "$FLASHER" ]; then
    eval $COLOR_RED
    echo "could not find FLASHER at: $FLASHER"
    eval $COLOR_NORMAL
    exit
fi
if [ ! -e "$LOADER_PL" ]; then
    eval $COLOR_RED
    echo "could not find loader Perl script at: $LOADER_PL"
    eval $COLOR_NORMAL
    exit
fi
if [ ! -e "$BBMC" ]; then
    eval $COLOR_RED
    echo "could not find bbmc binary at: $BBMC"
    eval $COLOR_NORMAL
    exit
fi
if [ ! -e "$1" ]; then
    eval $COLOR_RED
    echo "could not burn file: $1"
    eval $COLOR_NORMAL
    exit
fi    

eval $COLOR_YELLOW
echo "FLASHER: $FLASHER"
echo "loader perl script: $LOADER_PL"
echo "bbmc: $BBMC (profile: $PROFILE)"
eval $COLOR_BOLD
echo "Flashing this: $1"
echo "Erasing..."
eval $COLOR_NORMAL
echo $BBMC -l $PROFILE erase
sudo $BBMC -l $PROFILE erase
sudo $BBMC -l $PROFILE reset
eval $COLOR_BOLD
echo "Flashing..."
eval $COLOR_NORMAL

if [ -z "$HEX" ]; then    
    BBMC_CMD="sudo $BBMC -l $PROFILE reset"
    echo "$LOADER_PL" -f "$FLASHER" -s "$1" -t $DEVPORT -c "'$BBMC_CMD'"
    sudo "$LOADER_PL" -f "$FLASHER" -s "$1" -t $DEVPORT -c '$BBMC_CMD'
else
    echo "FIXME"
fi
