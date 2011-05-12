#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/05/03
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to setup the account-server portion of the swift SAIO environment.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
#  ACCOUNT SERVER SETUP 
###########################

setup_account (){

    # if the directory already exists, just clean it up 
    if [ -d $SWIFT_CONF/account-server ]; then 
        rm -f $SWIFT_CONF/account-server/* 
    else
        mkdir -p $SWIFT_CONF/account-server
    fi 

    printf "\t\t Setting up account-server configs \n"

    msg=""
    RING_BUILDER=`which swift-ring-builder`

    for NUMBER in `seq 1 4`;
    do
        A_PORT="60"$NUMBER"2"
        cp $TEMPLATES/account-server/account-server.conf.tmpl  /etc/swift/account-server/$NUMBER-account-server.conf
        sed -i "s/BINDIP/$BIND_IP/"  /etc/swift/account-server/$NUMBER-account-server.conf
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

return 0
}
