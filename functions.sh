#!/bin/bash
version="1.3.3";
cpSetup_banner() {
	echo -n "${GREEN}"
	cat <<"EOT"
                        ad88888ba
                       d8"     "8b              ,d
                       Y8,                      88
 ,adPPYba, 8b,dPPYba,  `Y8aaaaa,    ,adPPYba, MM88MMM 88       88 8b,dPPYba,
a8"     "" 88P'    "8a   `"""""8b, a8P_____88   88    88       88 88P'    "8a
8b         88       d8         `8b 8PP"""""""   88    88       88 88       d8
"8a,   ,aa 88b,   ,a8" Y8a     a8P "8b,   ,aa   88,   "8a,   ,a88 88b,   ,a8"
 `"Ybbd8"' 88`YbbdP"'   "Y88888P"   `"Ybbd8"'   "Y888  `"YbbdP'Y8 88`YbbdP"'
           88                                                     88
           88                                                     88
EOT
echo -n "${YELLOW}"
	cat <<"EOT"
			 _                  __  __       _
			| |__  _   _    ___|  \/  |_   _| |       ___  ___
			| '_ \| | | |  / __| |\/| | | | | |      / _ \/ __|
			| |_) | |_| |  \__ \ |  | | |_| | |  _  |  __/\__ \
			|_.__/ \__, |  |___/_|  |_|\__, |_| (_)  \___||___/
			       |___/               |___/
EOT
echo -n "${NORMAL}"
}
#                     cPanel Server Setup & Hardening Script
# ------------------------------------------------------------------------------
# @author Myles McNamara
# @date 12.20.2015
# @version 1.3.2
# @source https://github.com/tripflex/cpsetup
# ------------------------------------------------------------------------------
# @usage ./cpsetup [(-h|--help)] [(-v|--verbose)] [(-V|--version)] [(-u|--unattended)]
# ------------------------------------------------------------------------------
# @copyright Copyright (C) 2015 Myles McNamara
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
# ------------------------------------------------------------------------------

# Uncomment out the code below to make the script break on error
# set -e
#
# Functions and Definitions
#
# Define help function
function help(){
    echo "cpsetup - cPanel setup script";
    echo "Usage example:";
    echo "cpsetup [(-h|--help)] [(-v|--verbose)] [(-V|--version)] [(-u|--unattended)] [(-m|--menu)] [(-r|--run) value] [(-R|--functions)]";
    echo "Options:";
    echo "-h or --help: Displays this information.";
    echo "-v or --verbose: Verbose mode on.";
    echo "-V or --version: Displays the current version number.";
    echo "-u or --unattended: Unattended installation ( bypasses all prompts ).";
    echo "-m or --menu: Show interactive UI menu.";
    echo "-r or --run: Run a specific function.";
    echo "-R or --functions: Show available functions to use with -r or --run command.";
    exit 1;
}

# Declare vars. Flags initalizing to 0.
verbose="--quiet";
yumargs="";
version=0;
unattended=0;
menu=0;
builddir=~/cpsetupbuild/
sshport=222;
rootemail="your@email.com";
functions=0;
cloudflare_api_key="YOUR_CLOUDFLARE_API_KEY_HERE";
cloudflare_company_name="YOUR CLOUDFLARE HOSTING COMPANY NAME HERE";
railgun_token="YOUR_TOKEN_HERE";
railgun_host="YOUR_PUBLIC_IP_OR_HOSTNAME";

# Execute getopt
ARGS=$(getopt -o "hvVumr:R" -l "help,verbose,version,unattended,menu,run:,functions" -n "cpsetup" -- "$@");

#Bad arguments
if [ $? -ne 0 ];
then
    help;
fi

eval set -- "$ARGS";

while true; do
    case "$1" in
        -h|--help)
            shift;
            help;
            ;;
        -v|--verbose)
            shift;
                    verbose="";
            ;;
        -V|--version)
            shift;
                    echo "$version";
                    exit 1;
            ;;
        -u|--unattended)
            shift;
                    unattended="1";
                    yumargs="-y";
            ;;
        -m|--menu)
            shift;
                    menu="1";
            ;;
        -r|--run)
            shift;
                    if [ -n "$1" ];
                    then
                        runcalled="1";
                        run="$1";
                        shift;
                    fi
            ;;
        -R|--functions)
            shift;
            	functions="1";
            ;;

        --)
            shift;
            break;
            ;;
    esac
done

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

BLACKBG=$(tput setab 0)
REDBG=$(tput setab 1)
GREENBG=$(tput setab 2)
YELLOWBG=$(tput setab 3)
BLUEBG=$(tput setab 4)
MAGENTABG=$(tput setab 5)
CYANBG=$(tput setab 6)
WHITEBG=$(tput setab 7)

function headerBlock {
	l=${#1}
	printf "${BLUE}%s\n%s\n%s\n" "--${1//?/-}--" "${GREEN}- $1 -${BLUE}" "--${1//?/-}--${NORMAL}"
}

function lineBreak {
	echo -e "${MAGENTA}-=========================================================================-${NORMAL}"
}

function givemeayes {
	echo -n "$1 (Y/N)"
	read answer
	    case "$answer" in
	    Y|y|yes|YES|Yes) return 0 ;;
	    *) return 1 ;;
	    esac
}

function stepcheck {
	if (($unattended > 0)); then
		return 0;
	fi

	step=$1
	lineBreak
	if givemeayes "${BRIGHT}Would you like to ${step} ?${NORMAL}"; then
		return 0;
	else
		echo -e "\n${YELLOW}Skipping ${RED}${step}${YELLOW} per user input, continuing...\n${NORMAL}"
		return 1;
	fi

	read answer
	    case "$answer" in
	    Y|y|yes|YES|Yes) return 0 ;;
	    *) echo -e "\n${RED}Skipping this step per user input, processing next step...\n${NORMAL}"; return 1 ;;
	    esac
}

function installCXS(){
	cd ~
	wget https://download.configserver.com/cxsinstaller.tgz --no-check-certificate
	tar -xzf cxsinstaller.tgz
	perl cxsinstaller.pl
	rm -fv cxsinstaller.*
}

function installClamAV(){
	/scripts/ensurerpm ${verbose} gmp gmp-devel bzip2-devel
	useradd clamav
	groupadd clamav
	mkdir /usr/local/share/clamav
	chown clamav:clamav /usr/local/share/clamav
	cd ~
	wget --no-check-certificate https://github.com/vrtadmin/clamav-devel/archive/clamav-0.98.7.tar.gz
	tar -xzf clamav-*
	rm -rf clamav-*.tar.gz
	cd clamav*
	headerBlock "Building ClamAV from source..."
	./configure --disable-zlib-vcheck ${verbose}
	make ${verbose}
	make install ${verbose}
	headerBlock "Updating configuration files for ClamAV..."
	mv -fv /usr/local/etc/freshclam.conf.sample /usr/local/etc/freshclam.conf
	mv -fv /usr/local/etc/clamd.conf.sample /usr/local/etc/clamd.conf
	sed -i -e 's/Example/#Example/g' /usr/local/etc/freshclam.conf
	sed -i -e 's/Example/#Example/g' /usr/local/etc/clamd.conf
	sed -i -e 's/#LocalSocket/LocalSocket/g' /usr/local/etc/clamd.conf
	sed -i -e 's/LocalSocketGroup/#LocalSocketGroup/g' /usr/local/etc/clamd.conf
	sed -i -e 's/clamd.socket/clamd/g' /usr/local/etc/clamd.conf
	ldconfig
	headerBlock "Updating ClamAV definition files..."
	freshclam ${verbose}
	curl http://download.configserver.com/clamd -o /etc/init.d/clamd
	chown root:root /etc/init.d/clamd
	chmod +x /etc/init.d/clamd
	chkconfig clamd on
	service clamd restart
	rm -rf /etc/chkserv.d/clamav
	echo "service[clamav]=x,x,x,service clamd restart,clamd,root" >> /etc/chkserv.d/clamav
	touch /var/log/clam-update.log
	chown clamav:clamav /var/log/clam-update.log
	echo "clamav:1" >> /etc/chkserv.d/chkservd.conf
	rm -rf ~/clamav*
	headerBlock "ClamAV installed, sock will be at /tmp/clamd"
}

function installYumColors(){
	if ! grep -q 'color_list_installed_older' /etc/yum.conf ; then
		echo 'color_list_installed_older=red' >> /etc/yum.conf
	fi
	if ! grep -q 'color_list_installed_newer' /etc/yum.conf ; then
		echo 'color_list_installed_newer=yellow' >> /etc/yum.conf
	fi
	if ! grep -q 'color_list_installed_extra' /etc/yum.conf ; then
		echo 'color_list_installed_extra=red' >> /etc/yum.conf
	fi
	if ! grep -q 'color_list_available_reinstall' /etc/yum.conf ; then
		echo 'color_list_available_reinstall=green' >> /etc/yum.conf
	fi
	if ! grep -q 'color_list_available_upgrade' /etc/yum.conf ; then
		echo 'color_list_available_upgrade=blue' >> /etc/yum.conf
	fi
	if ! grep -q 'color_list_available_install' /etc/yum.conf ; then
		echo 'color_list_available_install=cyan' >> /etc/yum.conf
	fi
}

function installMailManage(){
	cd /usr/src
	rm -fv /usr/src/cmm.tgz
	wget http://download.configserver.com/cmm.tgz
	tar -xzf cmm.tgz
	cd cmm
	sh install.sh
	rm -Rfv /usr/src/cmm*
}

function installMailQueue(){
	cd $builddir
	wget http://download.configserver.com/cmq.tgz
	tar -xzf cmq.tgz
	cd cmq
	sh install.sh
}

function installModSecurityControl(){
	cd $builddir
	wget http://download.configserver.com/cmc.tgz
	tar -xzf cmc.tgz
	cd cmc
	sh install.sh
}

function installFirewall(){
	cd $builddir
	wget http://www.configserver.com/free/csf.tgz
	tar -xzf csf.tgz
	cd csf
	sh install.sh
	# Statistical Graphs available from the csf UI
	yum install ${yumargs} perl-GDGraph
	# Check perl modules
	perl /usr/local/csf/bin/csftest.pl
}

function installMalDetect(){
	cd $builddir
	wget --no-check-certificate https://www.rfxn.com/downloads/maldetect-current.tar.gz
	tar -xzf maldetect-*.tar.gz
	rm -rf maldetect-*.tar.gz
	cd maldetect*
	sh install.sh
}

function installSoftaculous(){
	cd $builddir
	wget -N http://files.softaculous.com/install.sh
	chmod 755 install.sh
	./install.sh
}

function installWatchMySQL(){
	cd /usr/src
	wget http://download.ndchost.com/watchmysql/latest-watchmysql
	sh latest-watchmysql
}

function installPHPiniManager(){

	cd /usr/local/cpanel/whostmgr/docroot/cgi
	wget -O addon_phpinimgr.php http://download.how2.be/whm/phpinimgr/addon_phpinimgr.php.txt
	chmod 700 addon_phpinimgr.php

}

function installCleanBackups(){

	cd /usr/src
	wget http://download.ndchost.com/cleanbackups/latest-cleanbackups
	sh latest-cleanbackups

}

function installAccountDNSCheck(){

	cd /usr/src
	wget http://download.ndchost.com/accountdnscheck/latest-accountdnscheck
	sh latest-accountdnscheck

}

function installMySQLTuner(){

	cd /usr/bin
	wget http://mysqltuner.pl/ -O mysqltuner
	chmod +x mysqltuner
}

function installModCloudFlare(){
	cd $builddir
	curl -k -L https://github.com/cloudflare/CloudFlare-CPanel/tarball/master > cloudflare.tar.gz
	tar -zxvf cloudflare.tar.gz
	cd cloudflare-CloudFlare-*/cloudflare/
	./install_cf ${cloudflare_api_key} mod_cf "${cloudflare_company_name}"
}

function addCloudFlareIPv6SubnetsToCSF(){
	# Add IPs to csf.ignore for LFD
	wget --output-document=- "https://www.cloudflare.com/ips-v6" >> /etc/csf/csf.ignore
	# Add IPs to csf.allow for Firewall
	wget --output-document=- "https://www.cloudflare.com/ips-v6" >> /etc/csf/csf.allow
}

function addCloudFlareIPv4SubnetsToCSF(){
	# Add IPs to csf.ignore for LFD
	wget --output-document=- "https://www.cloudflare.com/ips-v4" >> /etc/csf/csf.ignore
	# Add IPs to csf.allow for Firewall
	wget --output-document=- "https://www.cloudflare.com/ips-v4" >> /etc/csf/csf.allow
}

function configureMemCached(){
	if [ -f /etc/sysconfig/memcached ];then
		echo -e "\n${RED}The /etc/sysconfig/memcached file already exists, renaming to memcached.old ...\n${NORMAL}"
		mv /etc/sysconfig/memcached /etc/sysconfig/memcached.old
	fi

	echo 'PORT="22222"' >> /etc/sysconfig/memcached
	echo 'USER="memcached"' >> /etc/sysconfig/memcached
	echo 'MAXCONN="20480"' >> /etc/sysconfig/memcached
	echo 'CACHESIZE="4096"' >> /etc/sysconfig/memcached
	echo 'OPTIONS="-s /var/run/memcached/memcached.sock"' >> /etc/sysconfig/memcached
	# Add railgun user to memcached group
	usermod -a -G memcached railgun

	if [ ! -d "/var/run/memcached" ];then
		mkdir /var/run/memcached
		chown memcached.memcached /var/run/memcached
	fi

	service memcached stop
	service memcached start

	chmod 770 /var/run/memcached/memcached.sock
	echo -e "\n${NORMAL}If you want to change, review, or update memcached, use the ${YELLOW}/etc/sysconfig/memcached${NORMAL} file."
}

function installCloudFlarePackageRepo(){

	cd $builddir
	# Get RHEL major version number
	RHEL_VERSION=$(rpm -q --qf "%{VERSION}" "$(rpm -q --whatprovides redhat-release)" | grep -Eo '^[0-9]*' );
	PACKAGE_URL="http://pkg.cloudflare.com/cloudflare-release-latest.el${RHEL_VERSION}.rpm"

	sudo rpm -ivh $PACKAGE_URL
}

function hardenServerConfig(){
	# Check server startup for portreserve
	service portreserve stop
	chkconfig portreserve off

	configureApache
	configureCSF
	configureSSH
	configurecPanel
	configurePureFTP
	configureTweakSettings
	configureMySQL
	configurePHP
	csf -r
	/etc/init.d/lfd restart
	/etc/init.d/httpd restart
}

function newCpanelApacheLocalConf(){
cat << 'EOF' > /var/cpanel/conf/apache/local
---
"main":
  "serversignature":
    "item":
      "serversignature": 'Off'
  "servertokens":
    "item":
      "servertokens": 'ProductOnly'
  "traceenable":
    "item":
      "traceenable": 'Off'
EOF
}

function configureApache(){

	if [ ! -f /var/cpanel/conf/apache/local ]; then
		newCpanelApacheLocalConf
		/scripts/rebuildhttpdconf
		/etc/init.d/httpd
	else
		#TODO basic sed replacement
		echo -e "cPanel Apache Local Configuration file ( /var/cpanel/conf/apache/local ) already exists, unable to update"
	fi
}

function configureCSF(){
	sed -i -e 's/RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "3"/g' /etc/csf/csf.conf
	sed -i -e 's/SMTP_BLOCK = "0"/SMTP_BLOCK = "1"/g' /etc/csf/csf.conf
	sed -i -e 's/LF_SCRIPT_ALERT = "0"/LF_SCRIPT_ALERT = "1"/g' /etc/csf/csf.conf
	sed -i -e 's/SYSLOG_CHECK = "0"/SYSLOG_CHECK = "1800"/g' /etc/csf/csf.conf
	sed -i -e 's/PT_ALL_USERS = "0"/PT_ALL_USERS = "1"/g' /etc/csf/csf.conf

}

function configureSSH(){
	sed -i -e "s/#Port 22/Port ${sshport}/g" /etc/ssh/sshd_config
	sed -i -e 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
	/etc/init.d/sshd restart
}

function configurecPanel(){
	# Enable Shell Fork Bomb Protection
	perl -I/usr/local/cpanel -MCpanel::LoginProfile -le 'print [Cpanel::LoginProfile::install_profile('limits')]->[1];'
	# Compiler access
	chmod 750 /usr/bin/gcc
	# Root Forwarder
	if [ ! -f /root/.forward ]; then
    	echo $rootemail > /root/.forward
	fi
}

function configurePureFTP(){
	sed -i -e "s/RootPassLogins: 'yes'/RootPassLogins: 'no'/g" /var/cpanel/conf/pureftpd/main
	sed -i -e "s/AnonymousCantUpload: 'no'/AnonymousCantUpload: 'yes'/g" /var/cpanel/conf/pureftpd/main
	sed -i -e "s/NoAnonymous: 'no'/NoAnonymous: 'yes'/g" /var/cpanel/conf/pureftpd/main
	# Build configuration from cPanel FTP config
	/usr/local/cpanel/whostmgr/bin/whostmgr2 doftpconfiguration > /dev/null
}

function configureTweakSettings(){
	sed -i -e 's/skipboxtrapper=0/skipboxtrapper=1/g' /var/cpanel/cpanel.config
	sed -i -e 's/referrerblanksafety=0/referrerblanksafety=1/g' /var/cpanel/cpanel.config
	sed -i -e 's/referrersafety=0/referrersafety=1/g' /var/cpanel/cpanel.config
	sed -i -e 's/cgihidepass=0/cgihidepass=1/g' /var/cpanel/cpanel.config
	echo "maxemailsperhour=199" >> /var/cpanel/cpanel.config
	# Must be ran after updating tweak settings file
	/usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings > /dev/null
}

function configureMySQL(){
	if ! grep -q 'local-infile=0' /etc/yum.conf ; then
		echo 'local-infile=0' >> /etc/my.cnf
		/scripts/restartsrv_mysql
	fi
}

function configurePHP(){
	sed -i -e 's/enable_dl = On/enable_dl = Off/g' /usr/local/lib/php.ini
	sed -i -e 's/disable_functions =/disable_functions = show_source, system, shell_exec, passthru, exec, phpinfo, popen, proc_open, allow_url_fopen, ini_set/g' /usr/local/lib/php.ini
}

function promptForSSHPort(){
	# Configuration Prompts ( only shown when -u is NOT specified )
	if (($unattended < 1)); then
		echo -n "${MAGENTA}Enter SSH port to change from ${BLUE}${sshport}${MAGENTA}:${NORMAL} "
		read customsshport
		if [ $customsshport ]; then
			sshport=$customsshport
		fi
	fi
}

function promptForRootForwardEmail(){
	# Configuration Prompts ( only shown when -u is NOT specified )
	if (($unattended < 1)); then

		echo -n "${MAGENTA}Enter root forwarding email to change from ${BLUE}${rootemail}${MAGENTA}:${NORMAL} "
		read customrootemail
		if [ $customrootemail ]; then rootemail=$customrootemail
		fi

	fi
}

function promptForCloudFlareConfig(){
	# Configuration Prompts ( only shown when -u is NOT specified )
	if (($unattended < 1)); then

		echo -e "\n${WHITEBG}${BLACK}!! HEADS UP !! The mod_cloudflare module will be installed, but you need to recompile Apache with EasyApache in WHM to enable mod_cloudflare!${NORMAL}\n";
		read -p "Press [Enter] key when you are ready to continue..."

		echo -e "\nExisting value: ${BLUE}${cloudflare_api_key}${NORMAL} \n"
		echo -e "${MAGENTA}Enter your CloudFlare API Key if different from existing${MAGENTA}:${NORMAL} "
		read custom_cloudflare_api_key
		if [ $custom_cloudflare_api_key ]; then cloudflare_api_key=$custom_cloudflare_api_key
		fi

		echo -e "\nUsing ${BLUE}${cloudflare_api_key}${NORMAL} as CloudFlare API Key\n"

		echo -e "\nExisting value: ${BLUE}${cloudflare_company_name}${NORMAL} \n"
		echo -e "${MAGENTA}Enter your Hosting Company Name if different from existing${MAGENTA}:${NORMAL} "
		read custom_cloudflare_company_name
		if [ $custom_cloudflare_company_name ]; then cloudflare_company_name="${custom_cloudflare_company_name}"
		fi

		echo -e "\nUsing ${BLUE}${cloudflare_company_name}${NORMAL} as CloudFlare Company Name\n"
	fi
}

function promptForRailGunConfig(){
	# Configuration Prompts ( only shown when -u is NOT specified )
	if (($unattended < 1)); then

		server_hostname=$(hostname);
		server_ip=$(curl -4 icanhazip.com);

		echo -e "\nExisting value: ${BLUE}${railgun_token}${NORMAL} \n"
		echo -e "${MAGENTA}Enter your CloudFlare RailGun Token if different from existing (find this at https://partners.cloudflare.com)${MAGENTA}:${NORMAL} "
		read custom_railgun_token
		if [ $custom_railgun_token ]; then railgun_token=$custom_railgun_token
		fi

		echo -e "\nUsing ${BLUE}${railgun_token}${NORMAL} as CloudFlare RailGun Token\n"

		echo -e "\nExisting value: ${BLUE}${railgun_host}${NORMAL}"
		echo -e "\nFor reference, your hostname is ${BLUE}${server_hostname}${NORMAL}, your IP is ${BLUE}${server_ip}${NORMAL}\n"
		echo -e "${MAGENTA}Enter your CloudFlare RailGun Host if different from existing (should be servers IP or hostname)${MAGENTA}:${NORMAL} "
		read custom_railgun_host
		if [ $custom_railgun_host ]; then railgun_host=$custom_railgun_host
		fi

		echo -e "\nUsing ${BLUE}${railgun_host}${NORMAL} as CloudFlare RailGun Host\n"
	fi
}

cpanel_installed=$(/usr/local/cpanel/cpanel -V 2>/dev/null)

clear
cpSetup_banner
echo -e "\n";
if [ -z "$cpanel_installed" ]; then
	echo -e "${WHITEBG}${RED}${BRIGHT}${BLINK}Whoa Nelly!${NORMAL}${WHITEBG}${BLACK}It looks like cPanel is not installed on this server!${NORMAL}"
	if givemeayes "${RED}Would you like to install cPanel before running this script?${NORMAL}"; then
		headerBlock "No problem, let's get cPanel installed first ... this could take a minute ... or two ... or thirty .. please wait ..."
		echo -e "\n";
		read -p "Press [Enter] key when you are ready..."
		cd /home && curl -o latest -L http://httpupdate.cpanel.net/latest && sh latest
	else
		if ! givemeayes "${RED}Okay no problem, do you want to continue to this script (without installing cPanel)?${NORMAL}"; then
			echo -e "\n${RED}Script killed, nothing has been changed or installed.\n${NORMAL}"
			exit;
		fi
	fi
fi

if (($functions > 0)); then
	echo -e "${RED}Here's a list of available functions to call when using the -r or --run command:${NORMAL}"
	echo -e "\n";
	compgen -A function | egrep -vw 'givemeayes|help|headerBlock|lineBreak|stepcheck|promptForSSHPort|promptForRootForwardEmail|cpSetup_banner';
	echo -e "\n";
	exit;
fi

echo -e "${WHITEBG}${RED}${BRIGHT}${BLINK}Heads Up!${NORMAL}${WHITEBG}${BLACK}A couple things you should know about this script:${NORMAL}"
echo -e "* You must have ${YELLOW}ioncube${NORMAL} enabled in ${YELLOW}WHM${NORMAL} under ${BLUE}Tweak Settings${NORMAL} > ${MAGENTA}cPanel PHP Loader${NORMAL} to install Softaculous"
echo -e "* You must go through the initial setup in ${YELLOW}WHM${NORMAL}, selecting dns and ftp server type (when you first login to WHM) before running this script."
echo -e "${BLUE}Like the script?  Contribute to the open source community and this project at http://github.com/tripflex/cpsetup ... surfs up!${NORMAL}"
echo -e "\n";

if (($unattended > 0)); then
	echo -e "${YELLOW}!!! WARNING: Unattended mode ENABLED, MAKE SURE YOU SET ALL CONFIG VALUES IN THIS SCRIPT !! YOU HAVE BEEN WARNED !!${NORMAL}"
fi

if [ $run ]; then
	echo -e "${YELLOW}RUN command specified, only the${RED} $run ${YELLOW}function will be executed. ${NORMAL}"
fi

echo -e "\n";

if ! givemeayes "${RED}Would you like to continue with the install?${NORMAL}"; then
	echo -e "\n${RED}Script killed, nothing has been changed or installed.\n${NORMAL}"
	exit;
fi

if [ -d "$builddir" ]; then
	rm -rf $builddir
fi

mkdir $builddir

if [ $run ]; then
	${run}
	exit;
fi

if stepcheck "install yum colors"; then
	headerBlock "Adding yum colors if does not exist..."
	installYumColors
fi

if stepcheck "update all server packages"; then
	headerBlock "Updating all system packages, please wait this may take a minute..."
	yum clean all ${verbose}
	yum update ${yumargs} ${verbose}
fi

if stepcheck "install ConfigServer MailManage"; then
	headerBlock "Installing ConfigServer MailManage, please wait..."
	installMailManage
fi

if stepcheck "install ConfigServer MailQueue"; then
	headerBlock "Installing ConfigServer MailQueue, please wait..."
	installMailQueue
fi

if stepcheck "install ConfigServer Firewall"; then
	headerBlock "Installing ConfigServer Firewall, please wait..."
	installFirewall
fi

if stepcheck "install ConfigServer ModSecurity Control"; then
	headerBlock "Installing ConfigServer ModSecurity Control, please wait..."
	installModSecurityControl
fi

if stepcheck "install R-fx Malware Detect"; then
	headerBlock "Installing R-fx Malware Detect, please wait..."
	installMalDetect
fi
echo -e "\n";
echo -n "${YELLOW}!! HEADS UP !!${RED}( You SHOULD do this NOW ): ${NORMAL}You must have ${YELLOW}ioncube${NORMAL} enabled in ${YELLOW}WHM${NORMAL} under ${BLUE}Tweak Settings${NORMAL} > ${MAGENTA}cPanel PHP Loader${NORMAL} or Softaculous will not install"
echo -e "\n";
if stepcheck "install Softaculous"; then
	headerBlock "Installing Softaculous, please wait..."
	installSoftaculous
fi

if stepcheck "install Account DNS Check"; then
	headerBlock "Installing Account DNS Check, please wait..."
	installAccountDNSCheck
fi

if stepcheck "install WatchMySQL"; then
	headerBlock "Installing WatchMySQL, please wait..."
	installWatchMySQL
fi

if stepcheck "install PHP.INI Manager"; then
	headerBlock "Installing PHP.INI Manager, please wait..."
	installPHPiniManager
fi

if stepcheck "install Clean Backups"; then
	headerBlock "Installing Clean Backups, please wait..."
	installCleanBackups
fi

if stepcheck "install MySQL Tuner"; then
	headerBlock "Installing MySQL Tuner, please wait..."
	installCleanBackups
fi

if stepcheck "harden server configuration"; then
	promptForSSHPort
	promptForRootForwardEmail
	headerBlock "Securing the server with configuration tweaks, please wait..."
	hardenServerConfig
fi

if stepcheck "install ClamAV from source"; then
	headerBlock "Installing ClamAV from source, please wait..."
	installClamAV
fi

if stepcheck "install CloudFlare mod_cloudflare"; then
	promptForCloudFlareConfig
	headerBlock "Downloading and installing mod_cloudflare, please wait..."
	installModCloudFlare
fi

if stepcheck "add CloudFlare IPv4 and IPv6 subnets to ConfigServer Firewall allow list"; then
	headerBlock "Adding IPv4 subnets to CSF allow list, please wait..."
	addCloudFlareIPv4SubnetsToCSF
	headerBlock "Adding IPv6 subnets to CSF allow list, please wait..."
	addCloudFlareIPv4SubnetsToCSF
	headerBlock "Restarting ConfigServer Firewall, please wait..."
	csf -r
fi

if stepcheck "install CloudFlare RailGun (includes memcached)"; then
	headerBlock "Attempting to install MemCached, please wait..."
	yum install memcached -y

	headerBlock "Adding CloudFlare RailGun package repository, please wait..."
	installCloudFlarePackageRepo

	headerBlock "Installing CloudFlare Railgun, please wait..."
	yum install railgun-stable -y

	headerBlock "Adding ... CloudFlareRemoteIPTrustedProxy 127.0.0.1 ... to apache user conf file ..."
	if grep -q "CloudFlareRemoteIPTrustedProxy" /usr/local/apache/conf/includes/post_virtualhost_global.conf ; then
		echo -e "\n${RED}CloudFlareRemoteIPTrustedProxy already found in /usr/local/apache/conf/includes/post_virtualhost_global.conf file!\n${NORMAL}"
	else
		echo "<IfModule mod_cloudflare.c>" >> /usr/local/apache/conf/includes/post_virtualhost_global.conf
		echo "CloudFlareRemoteIPHeader CF-Connecting-IP" >> /usr/local/apache/conf/includes/post_virtualhost_global.conf
		echo "CloudFlareRemoteIPTrustedProxy 127.0.0.1" >> /usr/local/apache/conf/includes/post_virtualhost_global.conf
		echo "</IfModule>" >> /usr/local/apache/conf/includes/post_virtualhost_global.conf

		headerBlock "Rebuilding apache configuration ..."
		/scripts/rebuildhttpdconf
		headerBlock "Restarting apache ..."
		/scripts/restartsrv_apache
	fi

	headerBlock "Adding memcached and rg-listener to CSF process ignore list..."
	if grep -q "exe:/usr/bin/memcached" /etc/csf/csf.pignore ; then
		echo "exe:/usr/bin/memcached" >> /etc/csf/csf.pignore
	fi
	if grep -q "exe:/usr/bin/rg-listener" /etc/csf/csf.pignore ; then
		echo "exe:/usr/bin/rg-listener" >> /etc/csf/csf.pignore
	fi
	headerBlock "Restarting ConfigServer Firewall, please wait..."
	csf -r
fi

if stepcheck "configure memcached for RailGun using sockets"; then
	headerBlock "Creating /etc/sysconfig/memcached configuration file, please wait ..."
	configureMemCached
	headerBlock "Restarting memcached service ..."
	service memcached restart
	headerBlock "Setting permissions on /var/run/memcached/memcached.sock to 770"
	chmod 770 /var/run/memcached/memcached.sock
	headerBlock "Adding RailGun user to memcached group"
	usermod -a -G memcached railgun
fi

if stepcheck "configure CloudFlare RailGun"; then
	promptForRailGunConfig
	headerBlock "Configuring CloudFlare RailGun, please wait ..."
	sed -i -e 's/memcached.servers/#memcached.servers/g' /etc/railgun/railgun.conf
	sed -i -e 's/activation.token/#activation.token/g' /etc/railgun/railgun.conf
	sed -i -e 's/activation.railgun_host/#activation.railgun_host/g' /etc/railgun/railgun.conf
	echo "memcached.servers = /var/run/memcached/memcached.sock" >> /etc/railgun/railgun.conf
	echo "activation.token = ${railgun_token}" >> /etc/railgun/railgun.conf
	echo "activation.railgun_host = ${railgun_host}" >> /etc/railgun/railgun.conf
	headerBlock "Restarting RailGun service..."
	/etc/init.d/railgun restart
fi

headerBlock "Cleaning up build files, please wait..."
cd ~
rm -rf $builddir
echo -e "\n${CYAN}Script Complete! Profit!\n${NORMAL}"
echo -e "\n${WHITEBG}${RED}!!! If you installed mod_cloudflare DONT FORGET to login to WHM and recompile Apache with mod_cloudflare (using EasyApache) !!! \n${NORMAL}"
#!/bin/bash
#
# by Felipe Montes, @Gudw4L <gudwal@live.com>
# Changelog
# 23-03-2015 : added cc_deny countries

RED="\033[01;31m"
GREEN="\033[01;32m"
RESET="\033[0m"
ver=v2.07;

TEMPDIR="/root/tmp/csf"

uninstall() {
	if [ -e /etc/csf/bashcode ]
		then
			installver=$(cat /etc/csf/bashcode)
			echo "The bashcode $installver was used, proceeding with uninstallation."
		elif [ "$(echo $switch)" = "-u" ]
			then
			{
				echo "Use -uf if you want to force the installer to attempt an uninstallation."
				exit 1;
			}
		elif [ "$(echo $switch)" = "-uf" ]
			then
			{
				echo "WARNING :: FORCE UNINSTALL DETECTED. PROCEEDING WITH UNINSTALLATION."
				sleep 1
				echo "Press Enter to continue or ctrl^C to quit."
				read
			}
	fi

	echo "WARNING :: THERE MIGHT BE NO FIREWALL ON THIS SERVER AFTER UNINSTALLATION. PLEASE INSTALL A NEW FIREWALL IF NEEDED!"

	echo "STOPPING CSF"
	/etc/init.d/csf stop
	echo "STOPPING LFD"
	/etc/init.d/lfd stop
	echo "REMOVING CSF and LFD init SCRIPTS"
	rm -fv /etc/init.d/csf
	rm -fv /etc/init.d/lfd
	echo "FLUSHING IPTABLES RULES"
	/sbin/iptables --flush
	/etc/init.d/iptables save
	/etc/init.d/iptables restart
	echo "REMOVING CSF AND LFD FROM CHKCONFIG"
	chkconfig --del csf
	chkconfig --del lfd
	echo "REMOVING THE CSF AND LFD SYSLINKS"
	rm -fv /usr/sbin/csf
	rm -fv /usr/sbin/lfd
	echo "BACKING UP THE CSF CONFIGURATION"
	mv /etc/csf /etc/csf.bak
	echo "REMOVING THE CSF WHM PLUGIN"
	rm -fv /usr/local/cpanel/whostmgr/docroot/cgi/addon_csf.cgi
	rm -rfv /usr/local/cpanel/whostmgr/docroot/cgi/csf/
	rm -fv /usr/local/cpanel/whostmgr/docroot/cgi/configserver/csf.cgi
	rm -rfv /usr/local/cpanel/whostmgr/docroot/cgi/configserver/
	echo "REMOVING LFD FROM CHKSERVD"
	sed -ie 's/lfd:1//g' /etc/chkserv.d/chkservd.conf
	echo "RESTARTING cPanel"
	/etc/init.d/cpanel restart
	echo " "
	echo " "
	echo "WARNING :: THERE MIGHT NOT BE A FIREWALL ON THIS SERVER. PLEASE INSTALL A NEW FIREWALL IF NEEDED!"
}

prepare() {

echo -ne "$RED

     _____  _____ ______ 
   / ____|/ ____|  ____|
   | |    | (___ | |__   
   | |     \___ \|  __|  
   | |____ ____) | |     
    \_____|_____/|_|     $RESET $GREEN Automated Installation ver $ver $RESET"  
       

	if [ ! -d "$TEMPDIR" ]; then mkdir -p "$TEMPDIR" &>/dev/null; fi
	cd "$TEMPDIR"

	# CSF won't work if cPanel has the SMTP tweak enabled
        echo " ";
        echo " ";
        echo -n "Checking for SMTP tweak: "
	if [ -f "/var/cpanel/smtpgidonlytweak" ]; then
		echo "Found (disabling)"
		rm -f /var/cpanel/smtpgidonlytweak &>/dev/null
		echo -n "Restarting cPanel: "
		/etc/init.d/cpanel restart &>/dev/null
		echo "OK"
	else
		echo "OK (not found)"
	fi

        # check for conflicting products.
        if [ -e "/etc/cron.d/bfd" ]; then 
                echo "ERROR: BFD is installed. Exiting."
                exit 2
        else
            	echo "OK: BFD not found (conflicting product)"
        fi
	if [ -e "/etc/cron.daily/fw" ]; then 
                echo "ERROR: APF appears to be installed and will conflict. Exiting."
                exit 2
        else
            	echo "OK: APF not found (conflicting product)"
        fi

        echo
        cd "$TEMPDIR"

	echo

	#check for CentOS 6
	release=$(cat /etc/redhat-release | awk '{print $3}' | cut -d . -f1);
	if [ $release -ge 6  ]; then
		releasev=$(cat /etc/redhat-release | awk '{print $3}')
		echo "CentOS $releasev detected : Skipping klogd and syslog checks."
	else
        	# Turn on klogd if skipped in syslog
        	sed -ie 's/passed klogd skipped #//g' /etc/init.d/syslog
        	/etc/init.d/syslog restart

        	# check for requirements.
        	klogd_enabled=$(grep -vE "^\#" /etc/init.d/syslog|grep klogd|wc -l)
	        if [ "0" = "$klogd_enabled" ]; then echo "ERROR: klogd is required but does not appear to be configured. Exiting." ; exit 2 ; fi
        	klogd_running=$(ps ax|grep klog|grep -v grep|wc -l)
	        if [ "0" = "$klogd_running" ]; then echo "ERROR: klogd is required but does not appear to be running. Exiting." ; exit 2 ; fi
        fi   


}

install_csf() {
        echo -n "Downloading CSF: "
        wget https://download.configserver.com/csf.tgz -O "$TEMPDIR/csf.tgz" &>/dev/null
        echo "OK"
        tar -zxvf csf.tgz &>/dev/null
        cd ./csf
        echo -n "Installing CSF: "
        sh install.sh &>/dev/null
        if [ "0" = "$?" ]; then
	{
                echo "OK"
		echo "install-csf $ver" > /etc/csf/bashcode;
		echo "ConfigServer Firewall installed" $(date +%D)". Configuration at /etc/csf/" >> /root/.motd
        }
	else
                echo "Failed"
                exit 2
        fi
}

uncomment_tweak() {
        if [ -z "$3" ]; then echo "uncomment_tweak requires <item> <replacement> <filename>" ; return ; fi
        if [ ! -f "$3" ]; then echo "uncomment_tweak: file does not exist ($2)" ; return ;  fi
        sed -i -e 's/^\#${1}.*/${2}/g' -e 's/${1}.*/${2}/g' "${3}"
}

configure_csf_allow(){
            
        if [ -f "/etc/resolv.conf" ]; then
          for ip in `grep nameserver /etc/resolv.conf | sed -e "s/^nameserver //g"`; do
            echo "- Adding $ip to /etc/csf/csf.allow and csf.ignore (from resolv.conf)"
            echo "$ip:tcp:in:s=53 # DNS Server (do not remove)" >> /etc/csf/csf.allow
            echo "$ip:udp:in:s=53 # DNS Server (do not remove)" >> /etc/csf/csf.allow
            echo "$ip:tcp:out:d=53 # DNS Server (do not remove)" >> /etc/csf/csf.allow
            echo "$ip:udp:out:d=53 # DNS Server (do not remove)" >> /etc/csf/csf.allow
            echo "$ip # DNS Server (do not remove)" >> /etc/csf/csf.ignore
          done

	echo "Editing: /etc/csf/csf.ignore"
	  # whitelist local IPs:
	  grep -E "^IPADDR" /etc/sysconfig/network-scripts/ifcfg*|awk -F"=" '{print $2}'|while read ip; do
		grep "$ip" /etc/csf/csf.ignore &>/dev/null || echo "- Adding $ip to /etc/csf/csf.ignore (Local IP)" && \
		echo "$ip # Local IP: Do not remove" >> /etc/csf/csf.ignore
	  done

	# whitelist gateway:

	for ip in `grep -E "^GATEWAY=" /etc/sysconfig/network-scripts/ifcfg*|awk -F"=" '{print $2}'`; do
		grep "$ip" /etc/csf/csf.ignore &>/dev/null || echo "- Adding $ip to /etc/csf/csf.ignore (Gateway)" && \
		echo "$ip # Local Gateway: Do not remove" >> /etc/csf/csf.ignore
	done

  # whitelist other IPs that are commonly used:
  
    grep "$ip" /etc/csf/csf.ignore &>/dev/null || echo "- Adding $ip to /etc/csf/csf.ignore (common DNS)" && \

	  for ip in \
		74.125.0.0/24 66.249.64.0/19 ; do
		grep "$ip" /etc/csf/csf.ignore &>/dev/null || echo "- Adding $ip to /etc/csf/csf.ignore (Google)" && \
		echo "$ip # GoogleBot: Do not remove" >> /etc/csf/csf.ignore
	  done

	  for ip in \
		209.191.64.0/18; do
		grep "$ip" /etc/csf/csf.ignore &>/dev/null || echo "- Adding $ip to /etc/csf/csf.ignore (Yahoo)" && \
		echo "$ip # Yahoo Crawler: Do not remove" >> /etc/csf/csf.ignore
	  done
      
      fi

}

configure_csf_conf(){
        echo "Editing: /etc/csf/csf.conf"
        echo "- Setting TESTING=0"
        sed -ie "s/^TESTING = .*/TESTING = \"0\"/g" /etc/csf/csf.conf

        echo "- Setting AUTO_UPDATES=1"
        sed -ie "s/^AUTO_UPDATES = .*/AUTO_UPDATES = \"1\"/g" /etc/csf/csf.conf

        echo "- Setting LF_TRIGGER_PERM to 15 minutes (default)"
        sed -ie "s/^LF_TRIGGER_PERM = .*/LF_TRIGGER_PERM = \"900\"/g" /etc/csf/csf.conf

        echo "- Setting SSH failure to 20 / 30 min ban"
        sed -ie "s/^LF_SSHD = .*/LF_SSHD = \"20\"/g" /etc/csf/csf.conf
        sed -ie "s/^LF_SSHD_PERM = .*/LF_SSHD_PERM = \"3600\"/g" /etc/csf/csf.conf

        echo "- Setting SMTP failure rate to 20 / 5 min ban"

        sed -ie "s/^LF_SMTPAUTH = .*/LF_SMTPAUTH = \"20\"/g" /etc/csf/csf.conf
        sed -ie "s/^LF_SMTPAUTH = .*/LF_SMTPAUTH = \"300\"/g" /etc/csf/csf.conf

        echo "- Setting POP3 failure rate to 20 / 5min ban"
        sed -ie "s/^LF_POP3D = .*/LF_POP3D = \"20\"/g" /etc/csf/csf.conf
        sed -ie "s/^LF_POP3D_PERM = .*/LF_POP3D_PERM = \"300\"/g" /etc/csf/csf.conf

        echo "- Setting HTTP auth failure detection to 0 (disabled)"
        sed -ie "s/^LF_HTACCESS = .*/LF_HTACCESS = \"0\"/g" /etc/csf/csf.conf
        sed -ie "s/^LF_HTACCESS_PERM = .*/LF_HTACCESS_PERM = \"300\"/g" /etc/csf/csf.conf

        echo "- Setting MODSEC failure detection to 0 (disabled)"
        sed -ie "s/^LF_MODSEC = .*/LF_MODSEC = \"0\"/g" /etc/csf/csf.conf
        sed -ie "s/^LF_MODSEC_PERM = .*/LF_MODSEC_PERM = \"300\"/g" /etc/csf/csf.conf

        echo "- Setting cPanel login failures to 15 / 15min ban"
        sed -ie "s/^LF_CPANEL = .*/LF_CPANEL = \"15\"/g" /etc/csf/csf.conf
        sed -ie "s/^LF_CPANEL_PERM = .*/LF_CPANEL_PERM = \"3600\"/g" /etc/csf/csf.conf

        echo "- Setting suhosin detection to 0 (disabled)"
        sed -ie "s/^LF_SUHOSIN = .*/LF_SUHOSIN = \"0\"/g" /etc/csf/csf.conf
        sed -ie "s/^LF_SUHOSIN_PERM = .*/LF_SUHOSIN_PERM = \"180\"/g" /etc/csf/csf.conf

        echo "- Setting LF_SPAMHAUS=604800" # 1 day ban if on SpamHaus list
        sed -ie "s/^LF_SPAMHAUS = \"0\"/LF_SPAMHAUS = \"86400\"/g" /etc/csf/csf.conf

        echo "- Setting CT_LIMIT=300"
        sed -ie "s/^CT_LIMIT = .*/CT_LIMIT = \"300\"/g" /etc/csf/csf.conf

        echo "- Setting CT_BLOCK_TIME=900"
        sed -ie "s/^CT_BLOCK_TIME = .*/CT_BLOCK_TIME = \"900\"/g" /etc/csf/csf.conf

	echo "- Setting LF_SCRIPT_LIMIT=1000"
	sed -ie "s/^LF_SCRIPT_LIMIT = .*/LF_SCRIPT_LIMIT = \"1000\"/g" /etc/csf/csf.conf

        echo "- Setting LF_SCRIPT_ALERT=1"
        sed -ie "s/^LF_SCRIPT_ALERT = .*/LF_SCRIPT_ALERT = \"1\"/g" /etc/csf/csf.conf

        echo "- Setting LF_DSHIELD=86400"
        sed -ie "s/LF_DSHIELD = \"0\"/LF_DSHIELD = \"86400\"/g" /etc/csf/csf.conf

        echo "- Disabling email warning for SSH login"
        sed -ie "s/^LF_SSH_EMAIL_ALERT = \"1\"/LF_SSH_EMAIL_ALERT = \"0\"/g" /etc/csf/csf.conf

        echo "- Connection Tracking Options"
        echo "  Setting CT_INTERVAL=120"
        sed -ie "s/^CT_INTERVAL = .*/CT_INTERVAL = \"120\"/g" /etc/csf/csf.conf

        echo "  Setting connection blocks to temporary"
        sed -ie "s/^CT_PERMANENT = .*/CT_PERMANENT = \"0\"/g" /etc/csf/csf.conf

        echo "  Setting blocktime to 30 minutes"
        sed -ie "s/^CT_BLOCK_TIME = .*/CT_BLOCK_TIME = \"1800\"/g" /etc/csf/csf.conf

        echo "  Setting skip time_wait to on"
        sed -ie "s/^CT_SKIP_TIME_WAIT = .*/CT_SKIP_TIME_WAIT = \"1\"/g" /etc/csf/csf.conf

        echo "- Process Tracking Options"

        echo "  Setting Process Tracking Minimum Life to 180 seconds"
        sed -ie "s/^PT_LIMIT = .*/PT_LIMIT = \"180\"/g" /etc/csf/csf.conf

        echo "  Setting Process Tracking Check to 120 seconds"
        sed -ie "s/^PT_INTERVAL = .*/PT_INTERVAL = \"120\"/g" /etc/csf/csf.conf

        echo "  Verifying process killing is disabled"
        sed -ie "s/^PT_USERKILL = .*/PT_USERKILL = \"0\"/g" /etc/csf/csf.conf

        echo "- PortScan Options"

        echo "  Disabling PortScan Block"
        sed -ie "s/^PS_INTERVAL = .*/PS_INTERVAL = \"0\"/g" /etc/csf/csf.conf

        echo "  Disabling PortScan permanent blocks"
        sed -ie "s/^PS_PERMANENT = .*/PS_PERMANENT = \"0\"/g" /etc/csf/csf.conf

        echo "- Setting Integrity check to every 8 hours (from every hour)"
        sed -ie "s/^LF_INTEGRITY = .*/LF_INTEGRITY = \"28800\"/g" /etc/csf/csf.conf

        echo "- Increasing POP3/hour from 60 to 120"
        sed -ie "s/^LT_POP3D = .*/LT_POP3D = \"120\"/g" /etc/csf/csf.conf
        
        echo "- Disable malware countries"
        sed -ie "s/^CC_DENY = .*/CC_DENY = \"RU,CN,HK,JP,RO,TR,DZ,UA\"/g" /etc/csf/csf.conf

	echo "- Add My Own DynamicDNS"
	sed -i '/^DYNDNS =/s/=.*$/= \"300\"/g' /etc/csf/csf.conf;
	sed -i '/^DYNDNS_IGNORE /s/0/1/' /etc/csf/csf.conf;
	grep -i "muhsayd.ddns.net" /etc/csf/csf.dyndns || echo 'muhsayd.ddns.net' >> /etc/csf/csf.dyndns;

	if [ -e /usr/local ]; then
		echo "- Adding Rules for Plesk ports"
		sed -ie 's/20,21,22,25,53,80,110,143,443,465,587,993,995,2222/20,21,22,25,53,80,110,113,143,443,465,587,993,995,2222,8443,8447,8880/g' /etc/csf/csf.conf
		sed -ie 's/20,21,22,25,53,80,110,113,443/20,21,22,25,53,80,110,113,443,5224/g' /etc/csf/csf.conf
	fi
	
}

configure_sshd_config(){
        # SSHD Hardening
        if [ -f "/etc/ssh/sshd_config" ]; then
                echo "Editing: /etc/ssh/sshd_config"
                echo "- Disabling ssh v1"
                uncomment_tweak "Protocol " "Protocol 2" /etc/ssh/sshd_config
                echo "- Setting KeySize to 2048"
                uncomment_tweak "ServerKeyBits " "ServerKeyBits 2048" /etc/ssh/sshd_config
                echo "- Setting LoginGraceTime to 2m"
                uncomment_tweak "LoginGraceTime " "LoginGraceTime 2m" /etc/ssh/sshd_config
                echo "- Setting MaxAuthTries 3"
                uncomment_tweak "MaxAuthTries " "MaxAuthTries 3" /etc/ssh/sshd_config
                echo "- Setting UsePrivSep to yes"
                uncomment_tweak "UsePrivilegeSeparation " "UsePrivilegeSeparation yes" /etc/ssh/sshd_config
                echo "- Setting MaxStartups to 5"
                uncomment_tweak "MaxStartups " "MaxStartups 5" /etc/ssh/sshd_config
        fi
                echo "Restarting: sshd"
        if [ -e "/etc/init.d/sshd" ]; then /etc/init.d/sshd restart &>/dev/null ; fi
}

configure_csf_pignore(){
        if [ -f "/etc/csf/csf.pignore" ]; then
          echo "Editing: /etc/csf/csf.pignore"

	if [ -e "/usr/local/psa/bin/product_info" ]; then
		echo "- Adding Plesk Processes to csf.pignore"
		echo "exe:/usr/bin/sw-engine-cgi" >> /etc/csf/csf.pignore
		echo "cmd:/usr/bin/sw-engine-cgi -c /usr/local/psa/admin/conf/php.ini -d auto_prepend_file=auth.php3 -u psaadm" >> /etc/csf/csf.pignore
		echo "user:psaadm" >> /etc/csf/csf.pignore
		echo "exe:/usr/libexec/mysqld" >> /etc/csf/csf.pignore
		echo "cmd:/usr/libexec/mysqld –basedir=/usr –datadir=/var/lib/mysql –user=mysql –pid-file=/var/run/mysqld/mysqld.pid –skip-external-locking –socket=/var/lib/mysql/mysql.sock" >> /etc/csf/csf.pignore
		echo "user:mysql" >> /etc/csf/csf.pignore
		echo "user:admin" >> /etc/csf/csf.pignore
	fi

          grep -i "/usr/local/cpanel/3rdparty/mailman/bin/qrunner" /etc/csf/csf.pignore &>/dev/null || \
                echo "- Adding /usr/local/cpanel/3rdparty/mailman/bin/qrunner" && \
                echo "exe:/usr/local/cpanel/3rdparty/mailman/bin/qrunner" >> /etc/csf/csf.pignore

          grep -i "/usr/sbin/mysqld" /etc/csf/csf.pignore &>/dev/null || \
                echo "- Adding /usr/sbin/mysqld" && \
                echo "exe:/usr/sbin/mysqld" /etc/csf/csf.pignore >> /etc/csf/csf.pignore

          grep -i "/usr/local/cpanel/3rdparty/mailman/bin/mailmanctl" /etc/csf/csf.pignore &>/dev/null || \
                echo "- Adding /usr/local/cpanel/3rdparty/mailman/bin/mailmanctl" && \
                echo "exe:/usr/local/cpanel/3rdparty/mailman/bin/mailmanctl" >> /etc/csf/csf.pignore

        fi
}

configure_csf_dirwatch(){
        grep "^/etc/ssh/sshd_config" /etc/csf/csf.dirwatch &>/dev/null || echo "/etc/ssh/sshd_config" >> /etc/csf/csf.dirwatch \
                && echo "- Adding /etc/ssh/sshd_config file to watchlist"
}

configure_csf() {
	configure_csf_allow
	configure_csf_conf
	configure_sshd_config
	configure_csf_pignore
	configure_csf_dirwatch
}

stop_services() {
	echo "Stopping/Disabling Services"
	for service in anacron avahi-daemon avahi-dnsconfd bluetooth canna cups gpm hidd iiim nfslock nifd pcscd \
		rpcidmapd saslauthd sbadm webmin xfs ; do
	  echo "- Stopping: $service"
	  service $service stop &>/dev/null
  	  chkconfig $service off &>/dev/null
	done
}

set_permissions() {
	for folder in /tmp /var/tmp ; do
		echo "Setting $folder to 1777"
		chmod 1777 $folder &>/dev/null
	done
}

update_csf() {
        echo
        echo "Checking for CSF updates ..."
        echo
        /usr/sbin/csf --update
}

restart_csf() {
        if [ -e "/etc/rc.d/init.d/lfd" ]; then
                echo -n "Restarting LFD: "
                /etc/rc.d/init.d/lfd restart &>/dev/null
                echo "OK"
        fi
        if [ -e "/etc/rc.d/init.d/csf" ]; then
                echo -n "Restarting CSF: "
                /etc/rc.d/init.d/csf restart &>/dev/null
                echo "OK"

        fi
}

cleanup() {
	rm -rf "$TEMPDIR" &>/dev/null
    rm -f $0 &>/dev/null
}

plesku() {
	if [ -e "/usr/local/psa/bin/product_info" ]; then
		clear
		echo "PLESK SERVER."
		echo " "
		echo "Turning the Plesk Firewall back on after uninstallation."
		touch /usr/local/psa/var/modules/firewall/active.flag
		chkconfig --add psa-firewall
		service psa-firewall start
	fi
}

plesk() {
	if [ -e "/usr/local/psa/bin/product_info" ]; then
		echo "Plesk Server Installation."
		echo " "
		echo "Turning off Plesk Firewall."
		service psa-firewall stop
		echo "Removing the PSA Firewall active.flag"
		rm -fv /usr/local/psa/var/modules/firewall/active.flag
		echo "Removing psa-firewall from chkconfig"
		chkconfig --del psa-firewall
	fi
}

clear
switch="$(echo $1)";

# Uninstall if -u or -uf passed from command line.
if [ "$(echo $1)" = "-u" -o "$(echo $1)" = "-uf" ]
	then
		uninstall
		plesku
fi

# Install if -i passed from command line
if [ "$(echo $1)" = "-i" ]
	then
	{
		plesk
		prepare
		install_csf
		configure_csf
		stop_services
		set_permissions
		update_csf
		restart_csf
		cleanup
	}
fi
# Print usage and exit.
if [ "$(echo $1)" = "-v" ]
	then
		echo "install-csf $ver";
fi
if [ -z "$(echo $1)" ]
	then
	{
		echo "This is bashcode CSF installation script. Please run as follows :";
		echo " ";
		echo "sh install.sh -i :: to install"
		echo "sh install.sh -u :: to uninstall"
		echo "sh install.sh -v :: to print the current version";
	}
fi
