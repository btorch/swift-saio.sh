#!/bin/bash

# Author: Marcelo Martins
# Date: 2011-05-01
# Version: 1.00
#
# Info:
#       Script for setting up an openstack-swift All-In-One environment  
#       Currently the script is setup to install swift from source
#
#

# CHECK USER ID (MUST BE ROOT)
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root"
   exit 1
fi


# DEFAULTS
PYTHON_VER="2.6"
IPV6_SUPPORT="false"
CURDIR=`pwd`
#VERSION="1.3"


# ARGUMENTS 
NUMBER_OF_ARGS=$#
ARG_SARRAY=("$@")
ARGS=$@

usage_display (){
cat << USAGE

Syntax
    sudo swift-saio.sh [-r swift_version]  
    -r  The swift version to be installed (1.2.x and 1.3.X only)
    -6  Setup using ipv6 addresses (only for 1.3 and above)
    -h  For this usage screen  

USAGE
exit 1
}


while getopts "r:6h" opts
do 
    case $opts in 
        r) 
            VERSION="${OPTARG}"
            VER_REGEX="^1\.[2-4]\.[0-9]"
            if [[ ! "$VERSION" =~ $VER_REGEX ]]; then 
                printf "\t Sorry, only version 1.2, 1.3 and 1.4 currently supported \n"
                exit 1 
            fi
            ;;
        6)
            VER_REGEX="^1\.[3-9]\.[0-9]"
            if [[ ! "$VERSION" =~ $VER_REGEX ]]; then
                printf "\t Sorry, IPv6 only supported on version 1.3 and above \n"
                exit 1 
            else
                IPV6_SUPPORT="true"
            fi
            ;;
        h)
            usage_display
            ;;
        *) 
            usage
            ;;
    esac     
done


################
# INITIALIZING 
################
CFG_FILE="$CURDIR/swift-saio.cfg"
MODULES="$CURDIR/modules"

# SOURCE CONFIGURATION FILE
if [ ! -e $CFG_FILE ]; then 
    printf "\n\t No configuration file found (\033[1;31;40m mmissing: %s \033[0m)\n" "$CFG_FILE" 
    exit 1
else
    #printf "\n\t - Sourcing configuration file "
    source $CFG_FILE
fi

if [[ -z $VERSION ]]; then 
    VERSION="$SWIFT_VER"
fi

TEMPLATES="./etc/swift-$VERSION"
PATCHES="$CURDIR/patches/$VERSION"

if [ "$IPV6_SUPPORT" = "false" ];then 
    BIND_IP="0.0.0.0"
elif [ "$IPV6_SUPPORT" = "true" ];then
    BIND_IP="::"
fi





##################
# FUNCTIONS 
##################
# Progress bar 
spinner (){
    PROC=$1
    echo -n '[' 
    while [ -d /proc/$PROC ];do
        echo -n '#' ; sleep 0.25
        echo -n '#' ; sleep 0.25
        echo -n '#' ; sleep 0.25
        echo -n '#' ; sleep 0.25
    done
    echo -n ' - 100%]' 
    return 0
}

main_banner (){

    SYSTEM=`cat /etc/issue | head -n1`
    ARCH=`uname -m`
    IP6=`lsmod |grep ipv6 >/dev/null ; echo $?`
    if [ $IP6 -eq 0 ]; then 
        IP6="yes"
    else
        IP6="no"
    fi

    printf "\n\t #######################################################"
    printf "\n\t #           WELCOME TO SWIFT-SAIO.SH ver1.0           #" 
    printf "\n\t #######################################################"
    printf "\n\t #   Your System : %s " "$SYSTEM"
    printf "\n\t #   Your Arch : %s " "$ARCH"
    printf "\n\t #   IPv6 Ready  : %s " "$IP6"
    printf "\n\t #  " 
    printf "\n\t #   Swift Install : %s " "$VERSION"
    printf "\n\t # "
    printf "\n\t # \n"
}   


################## 
#      MAIN
##################

# Call Intro Banner
main_banner


####################################
#  CHECK IPV6   
####################################
if [ "$IPV6_SUPPORT" = "true" ]; then 
    source $MODULES/ipv6_config.sh
    ipv6_banner 
    ipv6_calc_install "ubuntu"
    ipv6_check
    sleep 2
fi


####################################
#  NON-PYTHON DEPENDENCIES INSTALL  
####################################
source $MODULES/non_python_deps_install.sh
install_non_python_deps "ubuntu"


####################################
#  PYTHON DEPENDENCIES INSTALL  
####################################
source $MODULES/python_deps_install.sh
install_python_deps "ubuntu"



########################
# SWIFT INSTALL 
########################
source $MODULES/swift_source_install.sh
swift_source_install



########################
# SWAUTH INSTALL 
########################
source $MODULES/swauth_source_install.sh
swauth_source_install



#########################
# STORAGE DEVICES SETUP 
#########################
source $MODULES/loopdev.sh
setup_loopdev $MOUNT_LOCATION $DD_FILE $DD_BS_VALUE $DD_SEEK_VALUE



###################################
# SWIFT CONFIGURATION & RING SETUP
###################################

# Configuration Path setup  
mkdir -p $SWIFT_CONF


printf "\n\t - Starting Swift $VERSION configuration setup "

if [ ! -d $TEMPLATES ]; then 
    printf "\t\t Unabled to locate template's directory \n"
    printf "\t\t Are you running the script from within it's source home ? \n"
    printf "\t\t Your current directory : `pwd` \n"
    printf "\t\t Quiting swift-saio setup \n"
    exit 1 
fi


printf "\n\t\t Setting up /etc/swift/swift.conf"
# All nodes need this file
cp $TEMPLATES/swift.conf.tmpl  /etc/swift/swift.conf
sed -i "s/HASH_PATH_SUFFIX/$HASH_PATH_SUFFIX/" /etc/swift/swift.conf


## Common to object/container/account services
printf "\n\t\t Setting up /etc/swift/drive-audit.conf"
cp $TEMPLATES/drive-audit.conf.tmpl  /etc/swift/drive-audit.conf
sed -i "s#MOUNTPOINT#$MOUNT_LOCATION#" /etc/swift/drive-audit.conf


## Rsync setup
printf "\n\t\t Setting up rsync configs \n\n"
sed -i 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/' /etc/default/rsync
cp $TEMPLATES/rsyncd.conf.tmpl   /etc/rsyncd.conf
sed -i "s#MOUNTPOINT#$MOUNT_LOCATION#g"  /etc/rsyncd.conf


###############
# Object-server
###############
source $MODULES/object.sh
setup_object 


##################
# Container-server 
##################
source $MODULES/container.sh
setup_container


#################
# Account-server
#################
source $MODULES/account.sh
setup_account


###############
# Proxy-server 
###############
source $MODULES/proxy.sh
setup_proxy


###############
# SWIFT FINALE 
###############
source $MODULES/final_steps.sh
final_steps


##################
# START SERVICES 
##################
source $MODULES/start_services.sh
start_services


###############################
# SETUP SWAUTH & ADMIN ACCOUNT
###############################
source $MODULES/swauth_setup.sh
swauth_setup


exit 0 
