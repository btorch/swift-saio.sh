#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/06/24
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to install swift from the git-hub repository that gholt has created. 
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
# SWIFT REPO INSTALL 
###########################

swift_repo_install (){

    SWIFT_REPO="deb http://crashsite.github.com/swift_debian/lucid-$VERSION lucid main"
    SWIFT_APT_LIST="/etc/apt/sources.list.d/swift_github.list"
    echo $SWIFT_REPO >$SWIFT_APT_LIST

    printf "\n\t - Starting swift github debian repository installation process \n"
    apt-get update -qq

    printf "\t\t Installing all swift $VERSION service(s) from github repo "
    apt-get install swift swift-account swift-container swift-object swift-proxy -y -qq --force-yes &>/dev/null 

    CODE=$?
    if [ $CODE -eq 0 ];then
        printf "\n\t\t -> Install sucessful \n"
    else
        printf "\t\t\t -> \033[1;31;40m Error found (check log file)  \033[0m\n\n"
        exit 1
    fi

return 0 
}
