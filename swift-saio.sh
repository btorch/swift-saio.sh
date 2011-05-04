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
# Todo:
#       - Setup SAIO with ipv6 networking 
#       - Create functions and modules 
#       - Add ipv6 setup 
#       - Add 1.2 and trunk support 
#
#

# CHECK USER ID (MUST BE ROOT)
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root"
   exit 1
fi


# ARGUMENTS 
NUMBER_OF_ARGS=$#
ARG_SARRAY=("$@")
ARGS=$@

usage_display (){
cat << USAGE

Syntax
    sudo swift-saio.sh [-r swift_version]  
    -r  The swift version to be installed (currently only 1.3.X)
    -6  Setup using ipv6 addresses (only for 1.3 and above)
    -h  For this usage screen  

USAGE
exit 1
}


while getopts "r:h" opts
do 
    case $opts in 
        r) 
            VERSION="${OPTARG}"
            if [ "$VERSION" != "1.3" ]; then 
                printf "\t Sorry, only 1.3 version currently supported \n"
                exit 1 
            fi
            ;;
        6)
            if [ "$VERSION" = "1.2" ]; then
                IPV6_SUPPORT="false"
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



# INITIAL VARIABLES
CURDIR=`pwd`
VERSION="1.3"                       # Overrides the -r flag at this time
PYTHON_VER="2.6"
TEMPLATES="./etc/swift-$VERSION"
CFG_FILE="$CURDIR/swift-saio.cfg"
MODULES="$CURDIR/modules"
IPV6_SUPPORT="false"


# SOURCE CONFIGURATION FILE
if [ ! -e $CFG_FILE ]; then 
    printf "\n\t No configuration file found (\033[1;31;40m mmissing: %s \033[0m)\n" "$CFG_FILE" 
    exit 1
else
    #printf "\n\t - Sourcing configuration file "
    source $CFG_FILE
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
    printf "\n\t # "
    printf "\n\t # \n"
}   


################## 
#   POSSIBLE MAIN
##################

# Call Intro Banner
main_banner


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


#### Start installation of Python-modules dependencies 
#### List of Packages : python-configobj python-setuptools python-pastedeploy python-openssl python-cheetah  
#### python-scgi python-paste python-simplejson python-webob python-formencode python-netifaces  
#### python-pkg-resources libjs-jquery python-pastescript python-xattr python-dev 
###printf "\n\t - Python packages installation (dependecies) "
###printf "\n\t\t Packages: several, please check code for package listing \n"
###printf "\n\t\t Would you like to proceed ? (y/n) "
###
###read choice 
###if [ "$choice" = "y" ]; then 
###    printf "\t\t Proceeding with python package(s) installation \n"
###    RESULT=`apt-get install python-configobj python-setuptools python-pastedeploy python-openssl python-cheetah  \
###    python-scgi python-paste python-simplejson python-webob python-formencode python-netifaces  \
###    python-pkg-resources libjs-jquery python-pastescript python-xattr  -y --force-yes -qq 2>&1 ` 
###
###    if [ $? -eq 0 ]; then 
###        printf "\n\t\t -> Succesfully done \n"
###    else
###        printf "\t\t\t -> $RESULT \n"
###        printf "\t\t\t -> \033[1;31;40m Error found  \033[0m\n\n"
###        exit 1
###    fi
###else
###    printf "\t\t\033[1;31;40m Quitting installation \033[0m\n\n"
###    exit 101
###fi
###
###
#### Start of PPA installation of certain python modules
###printf "\n\t - Python packages PPA installation (dependecies) "
###printf "\n\t\t Packages: python-eventlet python-greenlet python-webob  \n"
###printf "\n\t\t The PPA repo will be temporarily added and then removed "
###printf "\n\t\t Is it ok to have it removed ? (y/n) "
###
###read choice 
###if [ "$choice" = "y" ]; then 
###    REMOVE_PPA=1
###    printf "\t\t -> PPA repo will be removed "
###else 
###    REMOVE_PPA=0
###    printf "\t\t -> PPA repo will not be removed as requested "
###fi
###
###printf "\n"
###
###
###COMMANDS=("apt-get install python-software-properties -qq -y" "add-apt-repository ppa:swift-core/trunk " "apt-get -qq update")
###for i in "${COMMANDS[@]}"
###do 
###    RESULT=`$i 2>&1`
###    if [ $? != 0 ]; then 
###        printf "\t\t\t -> CMD: $i \n"
###        printf "\t\t\t -> $RESULT \n"
###        printf "\t\t\t -> \033[1;31;40m Error found  \033[0m\n\n"
###        exit 1
###    fi
###done
###
###printf "\n\t\t Proceeding with python PPA package(s) installation "
###RESULT=`apt-get install -qq -y --force-yes python-eventlet python-greenlet python-webob 2>&1`
###
###if [ $? -eq 0 ]; then
###    printf "\n\t\t -> Succesfully done \n"
###else
###    printf "\t\t\t -> $RESULT \n"
###    printf "\t\t\t -> \033[1;31;40m Error found  \033[0m\n\n"
###    exit 1
###fi
###
###if [ $REMOVE_PPA -eq 1 ]; then 
###    find /etc/apt/sources.list.d -iname "swift*" -type f -exec rm -f {} \;
###fi



########################
# SWIFT SOURCE INSTALL 
########################
source $MODULES/swift_source_install.sh
source_install



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
