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

    mkdir -p $SWIFT_CONF/proxy-server
    cp $TEMPLATES/proxy-server/proxy-server.conf.tmpl  /etc/swift/proxy-server/proxy-server.conf
    sed -i "s/BINDIP/$BIND_IP/g"  /etc/swift/proxy-server/proxy-server.conf
    sed -i "s/PORT/$PROXY_PORT/g"  /etc/swift/proxy-server/proxy-server.conf
    sed -i "s/ALLOW_ACCOUNT_MGNT_BOOLEAN_VALUE/$ALLOW_ACCOUNT_MGNT/"  /etc/swift/proxy-server/proxy-server.conf

    if [ "$IPV6_SUPPORT" = "true" ]; then
        sed -i "s/IPADDRESS/[$PROXY_IPADDR]/"  /etc/swift/proxy-server/proxy-server.conf
    else    
        sed -i "s/IPADDRESS/$PROXY_IPADDR/"  /etc/swift/proxy-server/proxy-server.conf
    fi     

    sed -i "s/SWAUTHKEY_VALUE/$SWAUTHKEY_VALUE/"  /etc/swift/proxy-server/proxy-server.conf
    sed -i "s/MEMCACHE_SERVERS/$MEMCACHE_SERVERS/"  /etc/swift/proxy-server/proxy-server.conf

    
    # Setting up the SSL certificate to be used. Please note that you MUST change the PROXY_PORT in the .cfg file 
    # in order to use 443 if desired otherwise it will use 8080
    if [[ $PROXY_SSL_ENABLED = "true" ]]; then 
        printf "\t\t Setting up SSL for proxy-server \n"

        PROXY_CERT="$SWIFT_CONF/proxy.crt"
        PROXY_KEY="$SWIFT_CONF/proxy.key"
        export OPENSSL_CONF="$CURDIR/saio-openssl.cnf" ; openssl req -new -x509 -nodes -out $PROXY_CERT -keyout $PROXY_KEY -days 1095 -newkey rsa:1024 &> /dev/null

        if [[ $? -eq 0 ]]; then 
            printf "\t\t SSL cert/key created sucessfuly \n"
        fi 

        sed -i 's/# cert_file/cert_file/' /etc/swift/proxy-server/proxy-server.conf
        sed -i 's/# key_file/key_file/' /etc/swift/proxy-server/proxy-server.conf
        sed -i 's/http/https/g' /etc/swift/proxy-server/proxy-server.conf
    fi

    printf "\n"

return 0
}
