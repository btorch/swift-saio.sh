#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/05/03
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to setup the proxy-server portion of the swift SAIO environment.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
#  PROXY SERVER SETUP 
###########################

setup_proxy (){
    printf "\t\t Setting up proxy-server configs \n"

    cp $TEMPLATES/proxy-server/proxy-server.conf.tmpl  /etc/swift/proxy-server/proxy-server.conf
    sed -i "s/PORT/$PROXY_PORT/g"  /etc/swift/proxy-server/proxy-server.conf
    sed -i "s/ALLOW_ACCOUNT_MGNT_BOOLEAN_VALUE/$ALLOW_ACCOUNT_MGNT/"  /etc/swift/proxy-server/proxy-server.conf
    sed -i "s/IPADDRESS/$PROXY_IPADDR/"  /etc/swift/proxy-server/proxy-server.conf
    sed -i "s/SWAUTHKEY_VALUE/$SWAUTHKEY_VALUE/"  /etc/swift/proxy-server/proxy-server.conf
    sed -i "s/MEMCACHE_SERVERS/$MEMCACHE_SERVERS/"  /etc/swift/proxy-server/proxy-server.conf
    printf "\n"

return 0
}
