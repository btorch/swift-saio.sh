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

    SWAUTH_PREP=`which swauth-prep`
    SWAUTH_ADD=`which swauth-add-user`
    SWAUTH_LIST=`which swauth-list`

    if [[ $PROXY_SSL_ENABLED = "true" ]]; then
        PROTOCOL="https"
    else
        PROTOCOL="http"
    fi    

    if [ "$IPV6_SUPPORT" = "true" ]; then
        PRIV_AUTH_URL="$PROTOCOL://[::1]:$PROXY_PORT/auth/"
        PUB_AUTH_URL="$PROTOCOL://[$PROXY_IPADDR]:$PROXY_PORT/auth/"
    else
        PRIV_AUTH_URL="$PROTOCOL://127.0.0.1:$PROXY_PORT/auth/"
        PUB_AUTH_URL="$PROTOCOL://$PROXY_IPADDR:$PROXY_PORT/auth/"
    fi


    printf "\n\t - SWAuth account prep "
    printf "\n\t\t Setting up swiftops account \n\n\n"

    $SWAUTH_PREP -K $SWAUTHKEY_VALUE -A $PRIV_AUTH_URL  
    $SWAUTH_ADD -K $SWAUTHKEY_VALUE -A $PRIV_AUTH_URL -a $SWACCOUNT $SWUSER $SWPASS

return 0 
}

swauth_info() {

    printf "\n\t\t Public/LocalNet Authentication command: \n"
    echo -e "\t\t curl -gik -H \"X-auth-user: $SWACCOUNT:$SWUSER\" -H \"X-auth-key: $SWPASS\" $PUB_AUTH_URL"v1.0" "

    printf "\n\t\t Internal Authentication command: \n"
    echo -e "\t\t curl -gik -H \"X-auth-user: $SWACCOUNT:$SWUSER\" -H \"X-auth-key: $SWPASS\" $PRIV_AUTH_URL"v1.0" "

    printf "\n\t\t Quick auth test: \n\n"
    curl -sgik -H "X-auth-user: $SWACCOUNT:$SWUSER" -H "X-auth-key: $SWPASS" $PRIV_AUTH_URL"v1.0" | sed 's/^/\t\t/g'

    printf "\n"
    printf "\n\t#############################################################"
    printf "\n\t###    Swift-SAIO environment finished .. have fun :-)   ####"
    printf "\n\t#############################################################\n\n"

return 0
}
