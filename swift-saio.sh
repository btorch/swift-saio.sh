#!/bin/bash

# Author: Marcelo Martins
# Date: 2011-05-01
# Version: 1.00
#
# Info:
#       Script for setting up an openstack-swift All-In-One environment  
#       Currently the script is setup to install swift from source
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
SWARN="\033[1;31;40m" 
EWARN="\033[0m"

# SOURCE CONFIGURATION FILE
if [ ! -e $CFG_FILE ]; then 
    printf "\n\t No configuration file found (\033[1;31;40m mmissing: %s \033[0m)\n" "$CFG_FILE" 
    exit 1
else
    printf "\n\t - Sourcing configuration file "
    source $CFG_FILE
fi



##################
# FUNCTIONS 
##################
# Progress bar 
spinner(){
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



################## 
#   POSSIBLE MAIN
##################

# Start installation of dependencies
printf "\n\t - Initial non-python package installation prior to swift setup"
printf "\n\t\t Packages: bzr curl memcached  sqlite3 xfsprogs iproute \n"
printf "\n\t\t Would you like to proceed ? (y/n) "

read choice 
if [ "$choice" = "y" ]; then 
    printf "\t\t Proceeding with package(s) installation \n"
    apt-get -qq update 
    RESULT=`apt-get install bzr curl memcached sqlite3 xfsprogs iproute -y --force-yes -qq 2>&1`

    if [ $? -eq 0 ]; then 
        printf "\n\t\t -> Succesfully done \n"
    else
        printf "\t\t\t -> $RESULT \n"
        printf "\t\t\t -> \033[1;31;40m Error found  \033[0m\n\n"
        exit 1
    fi
else
    printf "\t\t\033[1;31;40m Quitting installation \033[0m\n\n"
    exit 101
fi



# Start installation of Python-modules dependencies 
# List of Packages : python-configobj python-setuptools python-pastedeploy python-openssl python-cheetah  
# python-scgi python-paste python-simplejson python-webob python-formencode python-netifaces  
# python-pkg-resources libjs-jquery python-pastescript python-xattr python-dev 
printf "\n\t - Python packages installation (dependecies) "
printf "\n\t\t Packages: several, please check code for package listing \n"
printf "\n\t\t Would you like to proceed ? (y/n) "

read choice 
if [ "$choice" = "y" ]; then 
    printf "\t\t Proceeding with python package(s) installation \n"
    RESULT=`apt-get install python-configobj python-setuptools python-pastedeploy python-openssl python-cheetah  \
    python-scgi python-paste python-simplejson python-webob python-formencode python-netifaces  \
    python-pkg-resources libjs-jquery python-pastescript python-xattr  -y --force-yes -qq 2>&1 ` 

    if [ $? -eq 0 ]; then 
        printf "\n\t\t -> Succesfully done \n"
    else
        printf "\t\t\t -> $RESULT \n"
        printf "\t\t\t -> \033[1;31;40m Error found  \033[0m\n\n"
        exit 1
    fi
else
    printf "\t\t\033[1;31;40m Quitting installation \033[0m\n\n"
    exit 101
fi


# Start of PPA installation of certain python modules
printf "\n\t - Python packages PPA installation (dependecies) "
printf "\n\t\t Packages: python-eventlet python-greenlet python-webob  \n"
printf "\n\t\t The PPA repo will be temporarily added and then removed "
printf "\n\t\t Is it ok to have it removed ? (y/n) "

read choice 
if [ "$choice" = "y" ]; then 
    REMOVE_PPA=1
    printf "\t\t -> PPA repo will be removed "
else 
    REMOVE_PPA=0
    printf "\t\t -> PPA repo will not be removed as requested "
fi

printf "\n"


COMMANDS=("apt-get install python-software-properties -qq -y" "add-apt-repository ppa:swift-core/trunk " "apt-get -qq update")
for i in "${COMMANDS[@]}"
do 
    RESULT=`$i 2>&1`
    if [ $? != 0 ]; then 
        printf "\t\t\t -> CMD: $i \n"
        printf "\t\t\t -> $RESULT \n"
        printf "\t\t\t -> \033[1;31;40m Error found  \033[0m\n\n"
        exit 1
    fi
done

printf "\n\t\t Proceeding with python PPA package(s) installation "
RESULT=`apt-get install -qq -y --force-yes python-eventlet python-greenlet python-webob 2>&1`

if [ $? -eq 0 ]; then
    printf "\n\t\t -> Succesfully done \n"
else
    printf "\t\t\t -> $RESULT \n"
    printf "\t\t\t -> \033[1;31;40m Error found  \033[0m\n\n"
    exit 1
fi

if [ $REMOVE_PPA -eq 1 ]; then 
    find /etc/apt/sources.list.d -iname "swift*" -type f -exec rm -f {} \;
fi




########################
# SWIFT SOURCE INSTALL 
########################
INSTALLATION_PREFIX="/usr"
SWIFT_TEMP="swift-src"
cd $CURDIR

printf "\n\t - Starting swift source installation process \n"

if [ ! -d ./$SWIFT_TEMP ]; then  
    printf "\t\t Creating temporaty source directory \n"
    mkdir swift-src
fi 

cd $SWIFT_TEMP

printf "\t\t Downloading swift $VERSION source code \n\n"
BZR=`bzr branch lp:swift/$VERSION`

echo -e "$BZR " | sed 's/^/\t\t/'

cd $VERSION 
if [ ! -d /usr/lib/python$PYTHON_VER/site-packages ]; then 
    printf "\t\t Creating python site-packages directory \n"
    mkdir -p /usr/lib/python$PYTHON_VER/site-packages
fi 


sleep 3
printf "\t\t Building & Installing swift $VERSION under /usr/local "
python setup.py build 2>&1 >  $CURDIR/bzr_swift_build_$VERSION.log  
CODE=$?

if [ $CODE -eq 0 ];then 
    printf "\n\t\t -> Build sucessful "
else
    printf "\t\t\t -> \033[1;31;40m Error found (check log file)  \033[0m\n\n"
    exit 1
fi

sleep 2
python setup.py install 2>&1 >  $CURDIR/bzr_swift_install_$VERSION.log  
CODE=$?

if [ $CODE -eq 0 ];then 
    printf "\n\t\t -> Install sucessful "
else
    printf "\t\t\t -> \033[1;31;40m Error found (check log file)  \033[0m\n\n"
    exit 1
fi


printf "\n\n"
cd $CURDIR
if [ -d $CURDIR/$SWIFT_TEMP ]; then 
    rm -rf $SWIFT_TEMP
fi 


exit 0 
