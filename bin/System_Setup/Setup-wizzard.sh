#!/bin/bash
#this was one crazy script tst2
GUI=0;
ACTION=$1
#ACTION=testspace
#http://johnreid.it/2009/09/26/mount-a-webdav-folder-in-ubuntu-linux/
#WEBPATH=http://jira.framezcontrolz.com:7100/WigWag_build_environment
#REPO_BASE="https://izuma.repositoryhosting.com/webdav/izuma_frzwebproj"

#TODO
#  - remove cloning dev-tools from the user fix



toolchain_dir=/wigwag/toolchain/
git_credentials=x85446:mdtetdti123
#UPDATES-------------------------------------------------
#svn co https://izuma.repositoryhosting.com/svn/izuma_frzsoftware/dev-tools/bin/System_Setup/
#chmod 770 -R System_Setup/
#run this as root
#upload everything: sync_webdav -U https://izuma.repositoryhosting.com/webdav/izuma_frzwebproj/tools
#download everything: sync_webdav https://izuma.repositoryhosting.com/webdav/izuma_frzwebproj/tools

#command line scripts: http://mywiki.wooledge.org/BashFAQ/035#preview
function parse-cline {


    OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts "hvf:" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        v)  verbose=1
            ;;
        f)  output_file=$OPTARG
            ;;
        '?')
            show_help >&2
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.

printf 'verbose=<%s>\noutput_file=<%s>\nLeftovers:\n' "$verbose" "$output_file"
printf '<%s>\n' "$@"

}



wp-raytype() {
    title="${1}"
    mtype="${2}"
    mtype_desc="${3}"
 #   echo -e  "title: $title\nmtype: $mtype\nmtype_desc: $mtype_desc"
    eval `resize`
    wpstring="whiptail --title '$title' $mtype '$mtype_desc' $LINES $COLUMNS $(($LINES - 8))"
    wpstring=$(wp-rayadd "$wpstring" "$4")
    RESULT=$(wp-eval "$wpstring")   
    echo "$RESULT"
}

wp-rayadd(){
wpstring="$1"
name="$2[@]"
dataray=("${!name}")
#echo -e "$wpstring $name $dataray"

for i in "${dataray[@]}" ; do
    if [ "$i" != "ON" ] && [ "$i" != "OFF" ]; then
        wpstring="$wpstring '$i'";
    else
        wpstring="$wpstring $i"
    fi
done
echo "$wpstring"
}


wp-eval(){
RESULT2=$(eval $wpstring 3>&1 1>&2 2>&3)
echo "$RESULT2"
}


wp-radio () {
    RESULT=$(wp-raytype "${1}" "--radiolist" "$2" $3)
    echo "$RESULT"
}

wp-check () {
    RESULT=$(wp-raytype "${1}" "--checklist" "$2" $3)
    echo "$RESULT"
}

wp-menu () {
   RESULT=$(wp-raytype "${1}" "--menu" "$2" $3)
    echo "$RESULT"
}

wp-input () {
    eval `resize`
    wpstring="whiptail --title '$1' --inputbox '$2' $LINES $COLUMNS '$3'"
    RESULT=$(wp-eval "$wpstring")   
    echo "$RESULT"
}

wp-pass () {
    eval `resize`
    wpstring="whiptail --title '$1' --passwordbox '$2' $LINES $COLUMNS '$3'"
    RESULT=$(wp-eval "$wpstring")   
    echo "$RESULT"
}

wp-msg () {
    eval `resize`
    wpstring="whiptail --title '$1' --msgbox '$2' $LINES $COLUMNS "
    RESULT=$(wp-eval "$wpstring")   
    echo "DONE"
}

wp-file () {
    eval `resize`
    wpstring="whiptail --title '$1' --textbox $2 $LINES $COLUMNS"
    RESULT=$(wp-eval "$wpstring")   
    echo "DONE"
}

wp-yesno () {
    eval `resize`
    wpstring="whiptail --title '$1' --yesno '$2' $LINES $COLUMNS"
    RESULT2=$(eval $wpstring 3>&1 1>&2 2>&3)
    RESULT2=$?
    if [ $RESULT2 = 0 ]; then
        echo "YES"
    else
        echo "NO"
    fi
}



wp-getResults(){
RES=$("$@");
echo "$RES"
}

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-hv] [-f OUTFILE] [FILE]...
Do stuff with FILE and write the result to standard output. With no FILE
or when FILE is -, read standard input.
    
    -h          display this help and exit
    -f OUTFILE  write the result to OUTFILE instead of standard output.
    -v          verbose mode. Can be used multiple times for increased
                verbosity.
EOF
}                



testwp () {
menu_ray=("<-- Back" "Return to the main menu." "Add User" "Add a user to the system." "Modify User" "Modify an existing user." "List Users" "List all users on the system." "Add Group" "Add a user group to the system." "Modify Group" "Modify a group and its list of members." "List Groups" "List all groups on the system.")
radio_ray=("<-- Back" "Return to the main menu." ON "Add User" "Add a user to the system." OFF "Modify User" "Modify an existing user." OFF "List Users" "List all users on the system." OFF "Add Group" "Add a user group to the system." OFF "Modify Group" "Modify a group and its list of members." OFF "List Groups" "List all groups on the system." OFF)



echo -e "Testing Radio"
echo -e 'Result: '$(wp-getResults wp-radio "Radio test" "doit" radio_ray)'\n'

echo "Testing List"
echo -e 'Result:res1=$(wp-getResults wp-input "input test" "doit" "default value")
res2=$(wp-getResults wp-input "input test" "doit" "default value")
res3=$(wp-getResults wp-input "input test" "doit" "default value") '$(wp-getResults wp-check "List test" "doit" radio_ray)'\n'

echo "Testing Menu"
echo -e 'Result: '$(wp-getResults wp-menu "Menu test" "doit" menu_ray)'\n'

echo "Testing input"
echo -e 'Result: '$(wp-getResults wp-input "input test" "doit" "default value")'\n'

echo "Testing password"
echo -e 'Result: '$(wp-getResults wp-pass "pass test" "doit" "default value")'\n'

echo "Testing messagebox"
echo -e 'Result: '$(wp-getResults wp-msg "msg test" "doit now or else now hit ok")'\n'

echo "Testing file"
echo -e 'Result: '$(wp-getResults wp-file "file test tile menu" "/etc/passwd" )'\n'

echo "Testing yesno"
echo -e 'Result: '$(wp-getResults wp-yesno "yesno test text menu" "doit or not you decide")'\n'
}





#--------------------------
#-----OS Stuff-------------
#--------------------------


function testforroot {
	if [ `whoami` = "root" ]; then
		roottest=1;
        if [ $HOME = "/root" ]; then
            echo "Usage: sudo ./${0##*/}"
            echo "you are currently root, not sudo"
            exit
        fi
		else
			   echo "Usage: sudo ./${0##*/}"
			exit
		fi
}
function Update_and_Upgrade { #update and upgrade the entire os
    sudo add-apt-repository "deb http://archive.canonical.com/ natty partner" -y
    sudo add-apt-repository "ppa:webupd8team/sublime-text-3" -y
    sudo apt-get update -y
    sudo apt-get upgrade -y
}
#ia32-libs
function Apt-get-Typical-DeveloperUI { #WigWag required software for developer station
    sudo apt-get -y install cheese firefox meld sublime-text wireshark wmctrl
    if [[ $(getconf LONG_BIT) = "64" ]]
    then
        echo "64bit Detected" &&
        echo "Installing Google Chrome" &&
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&
        sudo dpkg -i google-chrome-stable_current_amd64.deb &&
        rm -f google-chrome-stable_current_amd64.deb
    else
        echo "32bit Detected" &&
        echo "Installing Google Chrome" &&
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_i386.deb &&
        sudo dpkg -i google-chrome-stable_current_i386.deb &&
        rm -f google-chrome-stable_current_i386.deb
    fi
    echo "Cleaning Up" &&
    sudo apt-get -f install &&
    sudo apt-get autoremove &&
    sudo apt-get -y autoclean &&
    sudo apt-get -y clean
}

#ia32-libs replaced by lib32z1 lib32ncurses5 lib32bz2-1.0


function detect_bits {
    echo `getconf LONG_BIT`
}

function Apt-get-typical64 { #WigWag required software for 64station
    echo "Installing the typical 64 bit apps"
    sudo apt-get -y install lib32z1 lib32ncurses5 lib32bz2-1.0

}

function Apt-get-typical32 { #WigWag required software for 64station
    echo "Installing the typical 64 bit apps"
    sudo apt-get -y install
}



function Apt-get-all-typical {
sudo apt-get -y install acl autoconf autotools-dev bison build-essential cmake davfs2 dpkg-dev emacs emacs-goodies-el flex fusedav g++ git gcc gnome-session-fallback libboost-all-dev libc6-dev libcurl3 libdevice-serialport-perl libexpat1-dev libftdi-dev libncurses5-dev libpcap0.8-dev libqt4-dev libterm-readkey-perl libsvn-java libssl-dev libssl-doc linux-headers-`uname -r` make nano openjdk-6-jdk patch qt4-qmake srecord ssh subversion texinfo tshark xterm
    system_type=$(detect_bits)
    if [ $(getconf LONG_BIT) = "64" ]; then
        Apt-get-typical64
    else
        Apt-get-typical32
    fi
    if [ $1 = "dev" ]; then
            Apt-get-Typical-DeveloperUI
    fi
}


function Add_developer_group { #Add wigwag develper group
echo "Vaidating that the system has the developer group"
egrep -i "^developer" /etc/group
if [ ! $? -eq 0 ]; then
groupadd developer
echo "added group"
fi
}

function add_virtual_tools {
    cd /tmp
     wget $REPO_BASE/tools/other/virtualbox-tools.tar.gz
     tar -xvzf virtualbox-tools.tar.gz
    cd New
    ./VBoxLinuxAdditions.run
}

function fix_ftdi_user { #fix ftdi group users
    if [ ! -f /etc/udev/rules.d/99-libftdi.rules ]; then
        cd /etc/udev/rules.d/
        wget $REPO_BASE/tools/other/99-libftdi.rules
    fi
}






#--------------------------------------------------------------------------------------
#-----USER Stuff-----------------------------------------------------------------------
#--------------------------------------------------------------------------------------
create_path_dir() {
    echo "create_path_dir($1)"
    if [ ! -d /home/$1/.paths ]; then #if it doesn't exist, 
        mkdir /home/$1/.paths
        echo "PATH=\$PATH:\$(find \$HOME/.paths/ | tr -s '\n' ':')">>/home/$1/.profile
    fi
}

test_for_path() {
    echo "test_for_path($1)"
    create_path_dir $1
    if [[ ! :$PATH: == *:".paths/":* ]] ; then
        source /home/$1/.profile
    fi
}
set_a_path() {
    echo "set_a_path($1,$2,$3)"
    user=$1
    uhome=/home/$1
    target=$2
    link=$3
    echo "RUNNING: Set a Path (FP) for $uhome on $target for $link"
    create_path_dir $1
    ln -s $target $uhome/.paths/$link
    echo ln -s $target $uhome/.paths/$link
    test_for_path $1
}

#fix groups for the user
function set_user_groups {
echo "RUNNING: Fix Group (FG) on $1"
sudo usermod -a -G adm,cdrom,sudo,dip,plugdev,lpadmin,sambashare,developer $1
}


#new OS account 
function new_user_account {	
echo "RUNNING: New OS Account (NOA) on $1 with password $2"
	ret=false
    getent passwd $1 >/dev/null 2>&1 && ret=true
    echo $ret "is"
    if [ "$ret" = false ]; then
        echo "I am: sudo useradd -m -s /bin/bash $1"
        sudo useradd -m -s /bin/bash $1
    fi
	echo -e "$2\n$2" | (sudo passwd $1)
	mv /tmp/.pwdfile /home/$1/
}


#set netrc file
function set_netrc_file {
echo "RUNNING: Set Netrc File (SNF) on user $1 with $2:$3"
#	sudo echo -e "machine izuma.repositoryhosting.com\nlogin $2\npassword $3\n">/home/$1/.netrc
	sudo echo -e "machine code.wigwag.com\nlogin $2\npassword $3\n">/home/$1/.netrc
}	

#fix permisions
function fix_user_permissions() {
echo "RUNNING: Fix Permisions (FPM) on $1"
echo "COMMAND: chown -R $1:$1 /home/$1/"
	#acmd="chown -R $1:$1 /home/$1/*;chown -R $1:$1 /home/$1/\\.*"
    acmd="sudo chown -R $1:$1 /home/$1/"
    eval $acmd
}

#checkout any git project
function checkout_git(){
    echo "checkout_git($1,$2,$3,$4,$5)"
    gitline="$1:$2@github.com"
    proj=$4
    newhome=$3
    path=$5
    mkdir -p $path
echo "RUNNING: Checkout $4 project at $newhome using $1:$2@github.com"
  cd $mhome
    if [ -d $path  ]; then
        cd $path
	echo 	git clone https://$gitline/WigWagCo/$proj
	git clone https://$gitline/WigWagCo/$proj
	fix_user_permissions $3
    else
        echo "Failed: could not find directory $path"
    fi
}

function process_prereqs(){
user=$1
path=$2
su $user <<EOF
source ~/.profile
cd $path
echo $path
update-prereqs.sh
expand-prereqs.sh
EOF
}
function checkout_git_generic(){
    gituser=$1
    gitpass=$2
    sysuser=$3
    gitproj=$4
    checkoutpath=/home/$sysuser/workspace/

    checkout_git $gituser $gitpass $sysuser $gitproj $checkoutpath
    process_prereqs $sysuser $checkoutpath$gitproj
}







#checkout dev tools
#$1: username to SVN
#$2: password to SVN
function checkout_dev_tools {
    echo "checkout_dev_tools($1,$2,$3)"
    sysuser=$1
    gituser=$2
    gitpass=$3
    mhome=/home/$sysuser
echo "RUNNING: Checkout Dev Tools (CKD) at $mhome using $2:$3"
  cd $mhome
    if [ -d $mhome  ]; then
        cd $mhome
	if [ ! -d $mhome/workspace/dev-tools/ ]; then
        #svn co --username $2 --password $3 https://izuma.repositoryhosting.com/svn/izuma_frzsoftware/dev-tools/
        checkout_git $gituser $gitpass $sysuser "dev-tools" $mhome
	checkout_git $gituser $gitpass $sysuser "cadaver" $mhome
	cd /$mhome/workspace/cadaver/
	./configure --with-ssl=openssl
	make
	make install
	fi;
	set_a_path $sysuser $mhome/dev-tools/bin/ devtools
    else
        echo "Failed: could not find directory $mhome"
    fi
 }


function rebootsystem {
    sudo reboot
}


#ECLIPSE------------------------------------------------
#Do Eclipse
function DE() {
echo "RUNNING: Do Eclipse (DE) on $1"
default_eclipse_path="/opt"
read -p "Use default eclipse path $default_eclipse_path? y/n " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
echo "What is your desired path"
    read default_eclipse_path
fi    
if [ ! -d "$default_eclipse_path/eclipse" ]; then
    if [ ! -d "$default_eclipse_path" ]; then
	mkdir -p $default_eclipse_path
    fi
	cd /tmp
		if [ `uname -m` = "x86_64" ]; then
		       if [ ! -e /tmp/eclipse-java-indigo-SR2-linux-gtk-x86_64.tar.gz ]; then
			wget $REPO_BASE/tools/other/eclipse-java-indigo-SR2-linux-gtk-x86_64.tar.gz
		    fi
		    chmod 755 eclipse-java-indigo-SR2-linux-gtk-x86_64.tar.gz
		    sudo tar -xvzf eclipse-java-indigo-SR2-linux-gtk-x86_64.tar.gz -C $default_eclipse_path/

		else
		    if [ ! -e /tmp/eclipse-java-indigo-SR2-linux-gtk.tar.tar.gz ]; then
			wget $REPO_BASE/tools/other/eclipse-java-indigo-SR2-linux-gtk.tar.tar.gz
		    fi
		    chmod 755 eclipse-java-indigo-SR2-linux-gtk.tar.tar.gz
		    sudo tar -xvzf eclipse-java-indigo-SR2-linux-gtk.tar.tar.gz -C $default_eclipse_path/
		fi
fi
sudo $default_eclipse_path/eclipse/eclipse -nosplash -application org.eclipse.equinox.p2.director -repository http://download.eclipse.org/releases/indigo/,http://download.eclipse.org/tools/cdt/releases/indigo/ \
-destination $default_eclipse_path/eclipse \
-installIU org.eclipse.cdt.feature.group
 
    sudo $default_eclipse_path/eclipse/eclipse -nosplash -application org.eclipse.equinox.p2.director -repository http://subclipse.tigris.org/update_1.6.x \
	-destination $default_eclipse_path/eclipse \
	-installIU com.collabnet.subversion.merge.feature.feature.group \
	-installIU org.tigris.subversion.subclipse.feature.group \
	-installIU org.tigris.subversion.subclipse.mylyn.feature.group \
	-installIU org.tigris.subversion.clientadapter.feature.feature.group \
	-installIU org.tigris.subversion.clientadapter.javahl.feature.feature.group \
	-installIU org.tigris.subversion.subclipse.graph.feature.feature.group \
	-installIU org.tigris.subversion.clientadapter.svnkit.feature.feature.group

    sudo $default_eclipse_path/eclipse/eclipse -nosplash -application org.eclipse.equinox.p2.director -repository "https://downloads.sourceforge.net/project/shelled/shelled/ShellEd 2.0.2/update",http://download.eclipse.org/technology/dltk/updates-dev/4.0-nightly/,http://download.eclipse.org/modeling/emf/updates/releases/ \
	-destination $default_eclipse_path/eclipse \
        -installIU net.sourceforge.shelled.feature.group 

    sudo chown -R root:developer $default_eclipse_path/eclipse
    sudo chmod -R g+w $default_eclipse_path/eclipse
    sudo chmod g+s $default_eclipse_path/eclipse/plugins #     (this will let new plugins we install get the permissions we pushed on the directory)
    sudo setfacl -Rm g:developer:rwX,d:g:developer:rwX $default_eclipse_path/eclipse #   (will provide recursive access to directory and new subdirectories)


echo "Building icon for eclipse"
FILE=/usr/share/applications/eclipse.desktop
echo -e "[Desktop Entry]\nVersion=1.0\nName=Eclipse\nTryExec=$default_eclipse_path/eclipse/eclipse\nExec=$default_eclipse_path/eclipse/eclipse\nTerminal=false\nIcon=$default_eclipse_path/eclipse/icon.xpm\nType=Application\nTerminal=false\nCategories=Utility;Development;TextEditor;">$FILE
}

function yn() {
read -p "$1 " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
    eval "$2"
fi    
}



function WigWag-settings {
    Add_developer_group
    set_user_groups $1
    fix_ftdi_user 
}



function setup_repair_user {
    echo "setup_repair_user($1 $2 $3 $4 $5 $6)"
    OSuser=$1
    OSuserp=$2
    netrcuser=$3
    netrcuserp=$4
    gituser=$5
    gituserp=$6
    
    new_user_account $OSuser $OSuserp
    set_user_groups $OSuser
    set_netrc_file $OSuser $netrcuser $netrcuserp
    test_for_path $OSuser
    checkout_dev_tools $OSuser $gituser $gituserp
    fix_user_permissions $OSuser

}

create_toolchain_path () {
    if [ ! -d $toolchain_dir ]; then
        mkdir -p $toolchain_dir
        base=$(echo $toolchain_dir | sed 's?^\(/[^/]*\)/.*$?\1?')  #grabs the base directory
        chown root:developer -R "$base"
        chmod 770 -R "$base"
    fi
}


setup_toolchain_postreq() {
    fix_toolchain_path
}

setup_mc13224_toolchain() {
    create_toolchain_path
    mctool_path=$toolchain_dir/mc13224-contiki/
    echo "mkdir $mctool_path"
    mkdir "$mctool_path"
    cd /tmp
    #git clone https://$git_credentials@github.com/WigWagCo/contiki-main
    cd /tmp/contiki-main/
    #update-prereqs.sh
    expand-prereqs.sh -e "$mctool_path"
}


blow_away() {
    rm -rf /wigwag
    #rm -rf /tmp/contiki-main
}







#--------------------------------------------------------------------------------------
#-----Menu-----------------------------------------------------------------------
#--------------------------------------------------------------------------------------

get_install_type () {
radio_ray=("Developer System Setup" "Setup a new developer system" ON "Jenkins System Setup" "Setup a Jenkins System" OFF)
Result=$(wp-getResults wp-radio "Radio test" "Select the desired operation" radio_ray)
echo "$Result"
}

jenkins_task_menu () {
radio_ray=("update" "update the OS (comlete ubuntu update" OFF "install" "Install all needed building / compiling system things that are avaiable via apt-get" ON "group" "add in developer group and fix permissions for wigwag developers" ON "MC1322x-toolchain" "Install toolchain for the mc13224" ON)
  radio_ray=("update" "update the OS (comlete ubuntu update" OFF "install" "Install all needed building / compiling system things that are avaiable via apt-get" OFF "MC1322x-toolchain" "Install toolchain for the mc13224" ON)   
        Result=$(wp-getResults wp-check "List test" "Selection for a Jenkins System " radio_ray)
        echo "$Result"
}

develop_task_menu () {
 radio_ray=("update" "update the OS (comlete ubuntu update)" OFF "install" "Install all apt-get things" OFF "WigWag-properties" "Setup WigWag groups, fix FTDI etc.." OFF "Setup/Repair-User" "Setup or repair a WigWag User" OFF "Clone_contiki-main" "Clone contiki-main" OFF "Clone_contiki-LEDE" "Clone contiki-LEDE" OFF)
        Result=$(wp-getResults wp-check "List test" "Selection for a Developer System" radio_ray)
        echo "$Result"
}



OS_un=""
OS_unp=""
OS_tt=""
svn_un=""
svn_unp=""
svn_tt=""
git_un=""
git_unp=""
git_tt=""
code_un=""
code_unp=""
code_tt=""

user_info_load(){
    echo "user_info_load($1)"
    uil=$1
    tfile=/home/$uil/.pwdfile
    testv=0;
    if [ -e $tfile ]; then
	while read line
	do
	    echo "reading $testv) $line"
	    case $testv in
		1)
		    OS_unp=$line
		    ;;
		2)
		    svn_un=$line
		    ;;
		3)
		    svn_unp=$line
		    ;;
		4)
		    git_un=$line
		    ;;
		5)
		    git_unp=$line
		    ;;
		6)
		    code_un=$line
		    ;;
		7)
		    code_unp=$line
		    ;;		
	    esac
	    ((testv++))
	done < $tfile
    fi
#exit
}
		    
	    

user_info_svn(){
if [ "$svn_tt" !=1  ]; then
     if [ "$OS_un" = "" ]; then
	user_info_load $SUDO_USER
    fi
    svn_un=$(wp-getResults wp-input "SVN username" "User: $un izuma.repositoryhosting.com username?" "$svn_un")
    svn_unp=$(wp-getResults wp-pass "$svn_un password" "User: $svn_un @izuma.repositoryhosting.com  password?" "$svn_unp")
svn_tt=1;
fi
}

user_info_code(){
if [ "$code_tt" != 1 ]; then
     if [ "$OS_un" = "" ]; then
	user_info_load $SUDO_USER
    fi
    code_un=$(wp-getResults wp-input "Code username" "User: $OS_un code.wgiwag.com username?" "$code_un")
    code_unp=$(wp-getResults wp-pass "$code_un password" "User: $code_un @code.wigwag.com  password?" "$code_unp")
fi
code_tt=1;
}

user_info_system(){
if [ "$OS_tt" != 1 ]; then
    OS_un=$(wp-getResults wp-input "System username" "What username do you want for this System? (caps count!)" "$SUDO_USER")
    user_info_load $OS_un
    OS_unp=$(wp-getResults wp-pass "$un password" "User: $OS_un password?" "$OS_unp")
OS_tt=1;
fi
}

user_info_git(){
if [ "$git_tt" != 1 ]; then
    if [ "$OS_un" = "" ]; then
	user_info_load $SUDO_USER
    fi
    git_un=$(wp-getResults wp-input "github username" "User $OS_un github username?" "$git_un")
    git_unp=$(wp-getResults wp-pass "$git_un password" "User: $git_un @github.com password?" "$git_unp")
git_tt=1;
fi
}


user_info_ALL() {
    echo "user_info_All()"
    user_info_system
    #user_info_svn
    user_info_code
    user_info_git
    echo -e "$OS_un\n$OS_unp\n$svn_un\n$svn_unp\n$git_un\n$git_unp\n$code_un\n$code_unp" > /tmp/.pwdfile
}






#main execution with menus and calls
main () {
cmd="whoami"
cputype=$(get_install_type)
case "$cputype" in
    "Developer System Setup")
        echo "Using Developer System"
        develop=$(develop_task_menu)
        #echo $develop
        for mychoice in $develop
        do   
            mychoice="${mychoice%\"}"  #stripping front and back quotes
            mychoice="${mychoice#\"}"
            echo "$mychoice"
            case "$mychoice" in
                "update") 
                    echo "Updating the system"
                    cmd="$cmd;Update_and_Upgrade"
                ;;
                "install")
                    echo "install the system"
                    cmd="$cmd;Apt-get-all-typical dev"
                ;;
                "WigWag-properties")
                    cmd="$cmd;WigWag-settings $SUDO_USER"
                ;;
                "Setup/Repair-User")
                    user_info_ALL
                    cmd="$cmd;setup_repair_user $OS_un $OS_unp $code_un $code_unp $git_un $git_unp"
                ;;
		"Clone_contiki-main")
		    user_info_git
		    cmd="$cmd;checkout_git_generic $git_un $git_unp $SUDO_USER contiki-main"
		;;
		"Clone_contiki-LEDE")
		    user_info_git
		    cmd="$cmd;checkout_git_generic $git_un $git_unp $SUDO_USER conitki-LEDE"
		    ;;
            esac
        done
    ;;
    "Jenkins System Setup")
        echo "Using Jenkins System"
        jenkins=$(jenkins_task_menu)
        for myc in $jenkins
        do
            myc="${myc%\"}"  #stripping front and back quotes
            myc="${myc#\"}"
            case "$myc" in
                "update")
                    echo "Updating the system"
                    Update_and_Upgrade
                ;;
                "install")
                    echo "install the system"
                    Apt-get-typical64
                    Apt-get-all-typical
                    apt-get install jenkins
                ;;
                "MC1322x-toolchain")
                    echo "mc1322x the system"
                    WigWag-settings $SUDO_USER
                    setup_mc13224_toolchain

                ;;
            esac
        done
    ;;
esac
eval $cmd
}


always_run () {
    testforroot
    blow_away   
    test_for_path $SUDO_USER
    main
}



always_run






