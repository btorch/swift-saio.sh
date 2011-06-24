#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/05/03
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to prep SWAUTH and setup an admin account that can be used.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
#  SWAUTH SETUPS  
###########################

swauth_setup (){

    # If swift version is 1.4.1 or greater then swauth needs to be installed from github

    VER_REGEX="^1\.[4-9]\.[0-9]"
    if [[ "$VERSION" =~ $VER_REGEX ]]; then
        SWAUTH_TEMP="swauth-src"
        cd $CURDIR

        printf "\n\t - Starting swauth source installation process \n"
        if [ ! -d ./$SWAUTH_TEMP ]; then
            printf "\t\t Creating temporaty swauth source directory \n"
            mkdir $SWAUTH_TEMP
        fi

        cd $SWAUTH_TEMP
        printf "\t\t Downloading swauth source code \n"
        GIT=`git clone git://github.com/gholt/swauth.git &> /dev/null`
        cd swauth
        sleep 2
        
        printf "\t\t Building & Installing swauth under /usr/local "
        python setup.py build 2>&1 >  $CURDIR/git_swauth_build.log
    
        CODE=$?
        if [ $CODE -eq 0 ];then
            printf "\n\t\t -> Build sucessful "
        else
            printf "\t\t\t -> \033[1;31;40m Error found (check log file)  \033[0m\n\n"
            exit 1
        fi

        sleep 2
        python setup.py install 2>&1 >  $CURDIR/git_swauth_install.log

        CODE=$?
        if [ $CODE -eq 0 ];then
            printf "\n\t\t -> Install sucessful "
        else
            printf "\t\t\t -> \033[1;31;40m Error found (check log file)  \033[0m\n\n"
            exit 1
        fi

        printf "\n\n"
        cd $CURDIR
        if [ -d $CURDIR/$SWAUTH_TEMP ]; then
            rm -rf $SWAUTH_TEMP
        fi
    fi

    SWAUTH_PREP=`which swauth-prep`
    SWAUTH_ADD=`which swauth-add-user`
    SWAUTH_LIST=`which swauth-list`

    printf "\n\t - SWAuth account prep "
    printf "\n\t\t Setting up swiftops account "
    $SWAUTH_PREP -K $SWAUTHKEY_VALUE
    $SWAUTH_ADD -K $SWAUTHKEY_VALUE -a $SWACCOUNT $SWUSER $SWPASS
    #$SWAUTH_LIST -K $SWAUTHKEY_VALUE $SWACCOUNT $SWUSER

    printf "\n\t\t Public/LocalNet Authentication command: \n"
    if [ "$IPV6_SUPPORT" = "true" ]; then
        echo -e "\t\t curl -gi -H \"X-auth-user: $SWACCOUNT:$SWUSER\" -H \"X-auth-key: $SWPASS\" http://[$PROXY_IPADDR]:$PROXY_PORT/auth/v1.0 "
    else    
        echo -e "\t\t curl -i -H \"X-auth-user: $SWACCOUNT:$SWUSER\" -H \"X-auth-key: $SWPASS\" http://$PROXY_IPADDR:$PROXY_PORT/auth/v1.0 "
    fi

    printf "\n\t\t Internal Authentication command: \n"
    if [ "$IPV6_SUPPORT" = "true" ]; then
        echo -e "\t\t curl -gi -H \"X-auth-user: $SWACCOUNT:$SWUSER\" -H \"X-auth-key: $SWPASS\" http://[::1]:$PROXY_PORT/auth/v1.0 "
    else
        echo -e "\t\t curl -i -H \"X-auth-user: $SWACCOUNT:$SWUSER\" -H \"X-auth-key: $SWPASS\" http://127.0.0.1:$PROXY_PORT/auth/v1.0 "
    fi    

    printf "\n\t\t Quick auth test: \n"
    if [ "$IPV6_SUPPORT" = "true" ]; then
        curl -gi -H "X-auth-user: $SWACCOUNT:$SWUSER" -H "X-auth-key: $SWPASS" http://[::1]:$PROXY_PORT/auth/v1.0
    else
        curl -i -H "X-auth-user: $SWACCOUNT:$SWUSER" -H "X-auth-key: $SWPASS" http://127.0.0.1:$PROXY_PORT/auth/v1.0
    fi

    printf "\n"
    printf "\n\t#############################################################"
    printf "\n\t###    Swift-SAIO environment finished .. have fun :-)   ####"
    printf "\n\t#############################################################\n\n"


return 0
}
