#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/10/27
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to install swift from source retrieved from github.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
# SWIFT SOURCE INSTALL 
###########################

swift_source_install (){
    SWIFT_TEMP="swift-src"
    cd $CURDIR

    printf "\n\t - Starting swift source installation process \n"

    if [ ! -d ./$SWIFT_TEMP ]; then
        printf "\t\t Creating temporaty source directory \n"
        mkdir $SWIFT_TEMP
    fi

    cd $SWIFT_TEMP

    printf "\t\t Git cloning openstack swift source code from github\n"
    git clone git://github.com/openstack/swift.git &>/dev/null
    cd swift 

    printf "\t\t Switching to swift tag version $VERSION \n"
    git checkout -b release_$VERSION $VERSION  &>/dev/null

    sleep 2

    printf "\t\t Building & Installing swift $VERSION under /usr/local "
    python setup.py build 2>&1 > $CURDIR/swift_build_$VERSION.log

    CODE=$?
    if [ $CODE -eq 0 ];then
        printf "\n\t\t -> Build sucessful "
    else
        printf "\t\t\t -> \033[1;31;40m Error found (check log file)  \033[0m\n\n"
        exit 1
    fi

    sleep 2
    python setup.py install 2>&1 >  $CURDIR/swift_install_$VERSION.log

    CODE=$?
    if [ $CODE -eq 0 ];then
        printf "\n\t\t -> Install sucessful "
    else
        printf "\t\t\t -> \033[1;31;40m Error found (check log file)  \033[0m\n\n"
        exit 1
    fi


    printf "\n\n"
    if [ "$IPV6_SUPPORT" = "true" ]; then
        ipv6_replicator_patch      
    fi


    printf "\n\n"
    cd $CURDIR
    if [ -d $CURDIR/$SWIFT_TEMP ]; then
        rm -rf $SWIFT_TEMP
    fi

return 0 
}
