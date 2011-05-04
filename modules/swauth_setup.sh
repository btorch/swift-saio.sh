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

    printf "\n\t\t Setting up swiftops account "
    $SWAUTH_PREP -K $SWAUTHKEY_VALUE
    $SWAUTH_ADD -K $SWAUTHKEY_VALUE -a $SWACCOUNT $SWUSER $SWPASS
    $SWAUTH_LIST -K $SWAUTHKEY_VALUE $SWACCOUNT $SWUSER

    printf "\n\t\t Public/LocalNet Authentication command \n"
    echo "curl -i -H \"X-auth-user: $SWACCOUNT:$SWUSER\" -H \"X-auth-key: $SWPASS\" http://$PROXY_IPADDR:$PROXY_PORT/auth/v1.0 "

    printf "\n\t\t Internal Authentication command \n"
    echo "curl -i -H \"X-auth-user: $SWACCOUNT:$SWUSER\" -H \"X-auth-key: $SWPASS\" http://127.0.0.1:$PROXY_PORT/auth/v1.0 "

return 0
}
