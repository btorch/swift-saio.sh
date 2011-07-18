#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/06/26
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to install swauth from .deb packages retrieved from github.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
# SWIFT SOURCE INSTALL 
###########################

swauth_deb_install (){

    SWAUTH="https://github.com/downloads/gholt/swauth/python-swauth_1.0.2-1_all.deb"
    SWAUTH_DOC="https://github.com/downloads/gholt/swauth/swauth-doc_1.0.2-1_all.deb"

    # If swift version is 1.4.1 or greater then swauth needs to be installed from github
    VER_REGEX="^1\.[4-9]\.[0-9]"
    if [[ "$VERSION" =~ $VER_REGEX ]]; then
        SWAUTH_TEMP="swauth-src"
        cd $CURDIR

        printf "\n\n\t - Starting swauth debian pkg installation process \n"
        if [ ! -d ./$SWAUTH_TEMP ]; then
            mkdir $SWAUTH_TEMP
        fi

        cd $SWAUTH_TEMP
        printf "\t\t Downloading .deb packages from github \n"
        wget -q $SWAUTH 
        wget -q $SWAUTH_DOC
   
        if [[ -e `basename $SWAUTH` ]]; then 
            printf "\n\t\t -> Download of `basename $SWAUTH` sucessful "
        else
            printf "\t\t\t -> \033[1;31;40m Error occurred (pkg file not found)  \033[0m\n\n"
            exit 1
        fi

        if [[ -e `basename $SWAUTH_DOC` ]]; then
            printf "\n\t\t -> Download of `basename $SWAUTH_DOC` sucessful "
        else    
            printf "\t\t\t -> \033[1;31;40m Error occurred (pkg file not found)  \033[0m\n\n"
            exit 1
        fi

        sleep 2

        printf "\n\n\t\t Installing swauth .deb packages  \n"
        dpkg -i `basename $SWAUTH` &>/dev/null
        dpkg -i `basename $SWAUTH_DOC` &>/dev/null

        CODE=$?
        if [ $CODE -eq 0 ];then
            printf "\t\t -> Install sucessful "
        else
            printf "\t\t\t -> \033[1;31;40m Error found (check log file)  \033[0m\n\n"
            exit 1
        fi
        sleep 2

        printf "\n\n"
        cd $CURDIR
        if [ -d $CURDIR/$SWAUTH_TEMP ]; then
            rm -rf $SWAUTH_TEMP
        fi
    fi

return 0 
}
