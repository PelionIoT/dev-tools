l#!/bin/bash
ACTION=$1
#ACTION=testspace
#WEBPATH=http://jira.framezcontrolz.com:7100/WigWag_build_environment
REPO_BASE="https://izuma.repositoryhosting.com/webdav/izuma_frzwebproj"
#sync_webdav -U https://izuma.repositoryhosting.com/webdav/izuma_frzwebproj/tools

#UPDATES-------------------------------------------------
#svn co https://izuma.repositoryhosting.com/svn/izuma_frzsoftware/dev-tools/bin/System_Setup/
#chmod 770 -R System_Setup/

function testforroot {
	if [ `whoami` = "root" ]; then
		roottest=1;
		else
			echo "you must be root to use this script"
			exit
		fi
}

function set_netrc_file {
	echo "Building the .netrc file.  Need credentials for izumarepositiory"
	echo "username:"
	read username
	echo "password:"
	read password
	sudo echo -e "machine izuma.repositoryhosting.com\nlogin $username\npassword $password">~/.netrc
}	


testforroot
if [ $ACTION = "NETRC" ] || [ $ACTION = "ALL" ]; then
    set_netrc_file
fi

if [ $ACTION = "UPDATES" ] || [ $ACTION = "ALL" ]; then
    sudo add-apt-repository "deb http://archive.canonical.com/ natty partner"
    sudo apt-get update -y
    sudo apt-get upgrade -y
    	#required to install virtual box guest tools
    sudo apt-get -y install acl acroread autoconf autotools-dev bison build-essential cadaver cheese dpkg-dev  emacs emacs-goodies-el firefox flex fusedav  g++ git gcc libcurl3 libftdi-dev libncurses5-dev libdevice-serialport-perl libterm-readkey-perl libsvn-java linux-headers-`uname -r` make meld nano patch openjdk-6-jdk srecord ssh subversion texinfo wireshark wmctrl
    cd /tmp
    wget $REPO_BASE/tools/other/google-chrome-stable_current_i386.deb
    sudo dpkg -i google-chrome-stable_current_i386.deb
    #apt-get -f install 
fi

if [ $ACTION = "GROUPS" ] || [ $ACTION = "ALL" ]; then
sudo groupadd developer
echo "added group"
fi

if [ $ACTION = "VIRTUALTOOLS" ]  || [ $ACTION = "ALL" ]; then
    cd /tmp
     wget $REPO_BASE/tools/other/virtualbox-tools.tar.gz
     tar -xvzf virtualbox-tools.tar.gz
    cd New
    ./VBoxLinuxAdditions.run
fi

if [ $ACTION = "FTDIUDEV" ] ||  [ $ACTION = "ALL" ]; then
    cd /etc/udev/rules.d/
    wget $REPO_BASE/tools/other/99-libftdi.rules
fi
