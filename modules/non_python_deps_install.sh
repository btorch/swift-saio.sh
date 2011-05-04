#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/05/03
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to install all the Non-Python dependencies prior to any swift build/install.
#
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###################################
#  NON-PYTHON DEPENDENCIES INSTALL  
###################################

install_non_python_deps (){

    SYSTYPE=$1 

    # This has not really been implemented. It's just an idea and more things
    # need to change in order for this too work. e.g: pkg names, flags, etc ...
    if [ "$SYSTYPE" = "debin" ] || [ "$SYSTYPE" = "ubuntu" ]; then 
        INSTOOL="apt-get"
        INSTOOL_OPTS="-y --force-yes -qq"
        INSTOOL_UPDATE="$INSTOOL -qq update"
    elif [ "$SYSTYPE" = "suse" ] || [ "$SYSTYPE" = "opensuse" ]; then 
        INSTOOL="zypper"
    fi

    printf "\n\t - Initial non-python package installation prior to swift setup"
    printf "\n\t\t Packages: bzr curl memcached sqlite3 xfsprogs iproute screen \n"
    printf "\n\t\t Would you like to proceed ? (y/n) "

    read choice
    if [ "$choice" = "y" ]; then
        printf "\t\t Proceeding with package(s) installation \n"
        $INSTOOL_UPDATE
        RESULT=`$INSTOOL install bzr curl memcached sqlite3 xfsprogs iproute screen $INSTOOL_OPTS 2>&1`

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

return 0 
}
