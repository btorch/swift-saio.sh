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
printf "\n\t\t Packages: bzr curl memcached  sqlite3 xfsprogs iproute screen \n"
printf "\n\t\t Would you like to proceed ? (y/n) "

read choice 
if [ "$choice" = "y" ]; then 
    printf "\t\t Proceeding with package(s) installation \n"
    apt-get -qq update 
    RESULT=`apt-get install bzr curl memcached sqlite3 xfsprogs iproute screen -y --force-yes -qq 2>&1`

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






#########################
#  STORAGE DEVICES SETUP 
#########################
# For now assume only loopback device setup 
# Later will implement real device setup 
# This a quick and dirty setup for now ... 
#
printf "\n\t - Starting Storage devices setup (loopback) "
printf "\n\t\t PLEASE NOTE: Everything under $MOUNT_LOCATION will be deleted if already exists " 
printf "\n\t\t Would you like to proceed ? (y/n) "

read choice
if [ "$choice" = "y" ]; then

    # Check for existing mount point 
    CHECK=`mount -v | grep -w "$MOUNT_LOCATION" &> /dev/null ; echo $?` 

    # If mount location not found mounted, proceed
    if [ $CHECK -eq 1 ]; then 
        if [ ! -d $MOUNT_LOCATION ]; then 
            printf "\n\t\t Creating mount location : $MOUNT_LOCATION \n"
            mkdir -p $MOUNT_LOCATION
        fi 
    else
        # unmount directory  
        printf "\n\t\t Removing existing mount : $MOUNT_LOCATION "
        umount $MOUNT_LOCATION 
    fi

    CHECK=$(cat /etc/fstab | grep -w "$DD_FILE" &> /dev/null ; echo $?)
    if [ $CHECK -eq 0 ]; then 
        # disable the previous mount line from fstab 
        sed -i -e "s#$DD_FILE #\#$DD_FILE #" /etc/fstab 
    fi  

    printf "\n\t\t Setting up /etc/fstab file "
    echo -e "$DD_FILE \t $MOUNT_LOCATION \t xfs \t loop,noatime,nodiratime,nobarrier,logbufs=8 0 0" >>  /etc/fstab 


    printf "\n\t\t Setting up disk image and mount settings \n"

    dd if=/dev/zero of=$DD_FILE count=0 bs=$DD_BS_VALUE  seek=$DD_SEEK_VALUE  &> /dev/null
    mkfs.xfs -q -f -i size=1024 $DD_FILE  
    mount $MOUNT_LOCATION 
    mkdir -p $MOUNT_LOCATION/sdb1 $MOUNT_LOCATION/sdb2 $MOUNT_LOCATION/sdb3 $MOUNT_LOCATION/sdb4 

    #chown -R swift.swift node/
    # you may need this depending on VM
    #echo -e "\nmkdir -p /var/run/swift  \nchown swift.swift /var/run/swift \n " >> /etc/rc.local 

else
    printf "\n\t\t Proceeding without storage devices setup "
    printf "\n\t\t You will need to set those up manually in order for installation to work properly "
fi 




###################################
# SWIFT CONFIGURATION & RING SETUP
###################################

# Configuration Path setup  
mkdir -p $SWIFT_CONF
mkdir -p $SWIFT_CONF/object-server
mkdir -p $SWIFT_CONF/proxy-server
mkdir -p $SWIFT_CONF/account-server
mkdir -p $SWIFT_CONF/container-server


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
printf "\t\t Setting up object-server configs \n"

msg=""
RING_BUILDER=`which swift-ring-builder`

for NUMBER in `seq 1 4`; 
do 
    O_PORT="60"$NUMBER"0"
    cp $TEMPLATES/object-server/object-server.conf.tmpl  /etc/swift/object-server/$NUMBER-object-server.conf
    sed -i "s/PORT/$O_PORT/"  /etc/swift/object-server/$NUMBER-object-server.conf
    sed -i "s#MOUNTPOINT#$MOUNT_LOCATION#"  /etc/swift/object-server/$NUMBER-object-server.conf
    sed -i "s/MOUNT_CHECK_BOOLEAN_VALUE/$MOUNT_CHECK/"  /etc/swift/object-server/$NUMBER-object-server.conf
    sed -i "s/VM_TEST_MODE_BOOLEAN_VALUE/$VM_TEST_MODE/"  /etc/swift/object-server/$NUMBER-object-server.conf

    msg=${msg}"\n$RING_BUILDER $SWIFT_CONF/object.builder add z$NUMBER-$PROXY_IPADDR:$O_PORT/sdb$NUMBER 1 " 
done 

# Object Ring builder file (FUTURE FUNCTION)
printf "\t\t Setting up object ring builder script \n"
O_RINGSCRIPT="/tmp/object_ring_builder.sh"
if [ ! -e $O_RINGSCRIPT ]; then 
    touch $O_RINGSCRIPT
else 
    rm -f $O_RINGSCRIPT
fi 

echo -e "$RING_BUILDER $SWIFT_CONF/object.builder create $PART_POWER $REPLICAS $PART_HOUR " >> $O_RINGSCRIPT
echo -e ${msg} >> $O_RINGSCRIPT
echo -e "$RING_BUILDER $SWIFT_CONF/object.builder rebalance \n" >> $O_RINGSCRIPT

printf "\t\t Creating object server ring file \n"
bash $O_RINGSCRIPT >> /tmp/ring_creation.log 
printf "\n"



##################
# Container-server 
##################
printf "\t\t Setting up container-server configs \n"

msg=""
RING_BUILDER=`which swift-ring-builder`

for NUMBER in `seq 1 4`; 
do 
    C_PORT="60"$NUMBER"1"
    cp $TEMPLATES/container-server/container-server.conf.tmpl  /etc/swift/container-server/$NUMBER-container-server.conf
    sed -i "s/PORT/$C_PORT/"  /etc/swift/container-server/$NUMBER-container-server.conf
    sed -i "s#MOUNTPOINT#$MOUNT_LOCATION#"  /etc/swift/container-server/$NUMBER-container-server.conf
    sed -i "s/MOUNT_CHECK_BOOLEAN_VALUE/$MOUNT_CHECK/"  /etc/swift/container-server/$NUMBER-container-server.conf
    sed -i "s/VM_TEST_MODE_BOOLEAN_VALUE/$VM_TEST_MODE/"  /etc/swift/container-server/$NUMBER-container-server.conf

    msg=${msg}"\n$RING_BUILDER $SWIFT_CONF/container.builder add z$NUMBER-$PROXY_IPADDR:$C_PORT/sdb$NUMBER 1 " 
done 

# Container Ring builder file (FUTURE FUNCTION)
printf "\t\t Setting up container ring builder script \n"
C_RINGSCRIPT="/tmp/container_ring_builder.sh"
if [ ! -e $C_RINGSCRIPT ]; then 
    touch $C_RINGSCRIPT
else 
    rm -f $C_RINGSCRIPT
fi 

echo -e "$RING_BUILDER $SWIFT_CONF/container.builder create $PART_POWER $REPLICAS $PART_HOUR " >> $C_RINGSCRIPT
echo -e ${msg} >> $C_RINGSCRIPT
echo -e "$RING_BUILDER $SWIFT_CONF/container.builder rebalance \n" >> $C_RINGSCRIPT

printf "\t\t Creating container server ring file \n"
bash $C_RINGSCRIPT >> /tmp/ring_creation.log
printf "\n"



#################
# Account-server
#################
printf "\t\t Setting up account-server configs \n"

msg=""
RING_BUILDER=`which swift-ring-builder`

for NUMBER in `seq 1 4`; 
do 
    A_PORT="60"$NUMBER"2"
    cp $TEMPLATES/account-server/account-server.conf.tmpl  /etc/swift/account-server/$NUMBER-account-server.conf
    sed -i "s/PORT/$A_PORT/"  /etc/swift/account-server/$NUMBER-account-server.conf
    sed -i "s#MOUNTPOINT#$MOUNT_LOCATION#"  /etc/swift/account-server/$NUMBER-account-server.conf
    sed -i "s/MOUNT_CHECK_BOOLEAN_VALUE/$MOUNT_CHECK/"  /etc/swift/account-server/$NUMBER-account-server.conf
    sed -i "s/VM_TEST_MODE_BOOLEAN_VALUE/$VM_TEST_MODE/"  /etc/swift/account-server/$NUMBER-account-server.conf

    msg=${msg}"\n$RING_BUILDER $SWIFT_CONF/account.builder add z$NUMBER-$PROXY_IPADDR:$A_PORT/sdb$NUMBER 1 "
done 

# Account Ring builder file (FUTURE FUNCTION)
printf "\t\t Setting up account ring builder script \n"
A_RINGSCRIPT="/tmp/account_ring_builder.sh"
if [ ! -e $A_RINGSCRIPT ]; then
    touch $A_RINGSCRIPT
else
    rm -f $A_RINGSCRIPT
fi

echo -e "$RING_BUILDER $SWIFT_CONF/account.builder create $PART_POWER $REPLICAS $PART_HOUR " >> $A_RINGSCRIPT
echo -e ${msg} >> $A_RINGSCRIPT
echo -e "$RING_BUILDER $SWIFT_CONF/account.builder rebalance \n" >> $A_RINGSCRIPT

printf "\t\t Creating account server ring file \n"
bash $A_RINGSCRIPT >> /tmp/ring_creation.log
printf "\n"


###############
# Proxy-server 
###############
printf "\t\t Setting up proxy-server configs \n"

cp $TEMPLATES/proxy-server/proxy-server.conf.tmpl  /etc/swift/proxy-server/proxy-server.conf
sed -i "s/PORT/$PROXY_PORT/g"  /etc/swift/proxy-server/proxy-server.conf
sed -i "s/ALLOW_ACCOUNT_MGNT_BOOLEAN_VALUE/$ALLOW_ACCOUNT_MGNT/"  /etc/swift/proxy-server/proxy-server.conf
sed -i "s/IPADDRESS/$PROXY_IPADDR/"  /etc/swift/proxy-server/proxy-server.conf
sed -i "s/SWAUTHKEY_VALUE/$SWAUTHKEY_VALUE/"  /etc/swift/proxy-server/proxy-server.conf
sed -i "s/MEMCACHE_SERVERS/$MEMCACHE_SERVERS/"  /etc/swift/proxy-server/proxy-server.conf


printf "\n"


###############
# SWIFT FINALE 
###############

printf "\n\t - Final Setup Steps "

UCHECK=`cat /etc/passwd |grep swift > /dev/null ; echo $?`
GCHECK=`cat /etc/group |grep swift > /dev/null ; echo $?`
if [ ! $GCHECK -eq 0 ] &&  [ ! $UCHECK -eq 0 ]; then 
    printf "\n\t\t Adding swift user & group "
    groupadd swift
    useradd -s /bin/false -g swift swift
else 
    printf "\n\t\t User/group swift already exists "
fi 

printf "\n\t\t Creating /var/run/swift and /var/log/swift"
mkdir -p /var/run/swift /var/log/swift 
chown swift.swift /var/run/swift
chown swift.swift /var/log/swift

printf "\n\t\t Setting up proper ownerships \n"
chown -R swift.swift $SWIFT_CONF
chown swift.swift $MOUNT_LOCATION
chown -R swift.swift $MOUNT_LOCATION


#############################################
# Start services and setup an admin account
#############################################

SWIFTINIT=`which swift-init`
printf "\n\t - Starting up services "
$SWIFTINIT proxy start
$SWIFTINIT account-server start
$SWIFTINIT container-server start
$SWIFTINIT object-server start


SWAUTH_PREP=`which swauth-prep`
SWAUTH_ADD=`which swauth-add-user`
SWAUTH_LIST=`which swauth-list`
printf "\n\t\t Setting up swiftops account "
$SWAUTH_PREP -K $SWAUTHKEY_VALUE
$SWAUTH_ADD -K $SWAUTHKEY_VALUE -a $SWACCOUNT $SWUSER $SWPASS
$SWAUTH_LIST -K $SWAUTHKEY_VALUE $SWACCOUNT $SWUSER



exit 0 
