#!/bin/bash
ACTION=$1
username1="bbbb"
#ACTION=testspace
#WEBPATH=http://jira.framezcontrolz.com:7100/WigWag_build_environment
REPO_BASE="https://izuma.repositoryhosting.com/webdav/izuma_frzwebproj"
#UPDATES-------------------------------------------------
#svn co https://izuma.repositoryhosting.com/svn/izuma_frzsoftware/dev-tools/bin/System_Setup/
#chmod 770 -R System_Setup/
#run this as root

function testforroot {
	if [ `whoami` = "root" ]; then
		roottest=1;
		else
			echo "you must be root to use this script"
			exit
		fi
}


function set_username {
	echo "username:"
	read username1
}

function check_username() {
if [ $username1 = "bbbb" ]; then
set_username
fi
}

function fix_groups() {
check_username
sudo usermod -a -G adm,cdrom,sudo,dip,plugdev,lpadmin,sambashare,developer $username1
}

function new_OS_account {	
	echo "creating a new user for the OS"
       check_username
	sudo useradd -m -s /bin/bash $username1
	sudo passwd $username1
	fix_groups
}

function set_netrc_file {
	echo "Building the .netrc file.  Need credentials for izumarepositiory"
	echo "What username do you use at izuma.repositoryhosting.com:"
	read username
	echo "password:"
	read password
	check_username
	sudo echo -e "machine izuma.repositoryhosting.com\nlogin $username\npassword $password">/home/$username1/.netrc
}	

function fix_path {
check_username
    mkdir /home/$username1/.paths
    mkdir -p /home/$username1/.config/lxpanel/Lubuntu/panels
    ls /home/$username1/.config/lxpanel/Lubuntu/panels/
    ln -s /home/$username1/dev-tools/bin/ /home/$username1/.paths/devtools
    echo "PATH=\$PATH:\$(find \$HOME/.paths/ | tr -s '\n' ':')">>/home/$username1/.profile
}
#echo "PATH=$PATH:~/dev-tools/bin">>/home/$username1/.profile

function fix_permissions() {
check_username
	chown -R $username1:$username1 /home/$username1/
}

function launcherbuttons {
check_username
#Wrote /home/user/.config/lxpanel/Lubuntu/panels/top
#wiki.lxde.org/en/Main_Menu
    cd /home/$username1/.config/lxpanel/Lubuntu/panels/
    #cd ~/.config/lxpanel/Lubuntu/panels/
    wget $REPO_BASE/tools/other/top1
    wget $REPO_BASE/tools/other/top
    ls /home/$username1/.config/lxpanel/Lubuntu/panels/
}

function checkout_devtools {
check_username   
 cd /home/$username1/
    svn co --username $username --password $password https://izuma.repositoryhosting.com/svn/izuma_frzsoftware/dev-tools/
}

function rebootsystem {
    sudo reboot
}


#ECLIPSE------------------------------------------------
function doeclipse() {
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


testforroot
yn "Create new user account on this os? y/n" new_OS_account
yn "Fix the groups for the user? y/n" fix_groups
yn "Would you like to set the netrc_file? y/n" set_netrc_file
yn "Would you like to build your path? y/n" fix_path
yn "Would you like to checkout dev-tools? y/n" checkout_devtools
yn "Would you like to build launch buttons (only for mint users)? y/n" launcherbuttons
yn "Would you like to checkout eclipse for contiki development? y/n" doeclipse
yn "Would you like to repair permissons? y/n" fix_permissions
yn "If this is a mint install, would you like launcherbuttons rebuilt? y/n" launcherbuttons
yn "Would you like to reboot your system? y/n" rebootsystem

