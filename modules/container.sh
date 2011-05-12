#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/05/03
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to setup the container-server portion of the swift SAIO environment.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
#  CONTAINER SERVER SETUP 
###########################

setup_container (){

    # if the directory already exists, just clean it up 
    if [ -d $SWIFT_CONF/container-server ]; then 
        rm -f $SWIFT_CONF/container-server/* 
    else
        mkdir -p $SWIFT_CONF/container-server
    fi 

    printf "\t\t Setting up container-server configs \n"

    msg=""
    RING_BUILDER=`which swift-ring-builder`

    for NUMBER in `seq 1 4`;
    do
        C_PORT="60"$NUMBER"1"
        cp $TEMPLATES/container-server/container-server.conf.tmpl  /etc/swift/container-server/$NUMBER-container-server.conf
        sed -i "s/BINDIP/$BIND_IP/"  /etc/swift/container-server/$NUMBER-container-server.conf
        sed -i "s/PORT/$C_PORT/"  /etc/swift/container-server/$NUMBER-container-server.conf
        sed -i "s#MOUNTPOINT#$MOUNT_LOCATION#"  /etc/swift/container-server/$NUMBER-container-server.conf
        sed -i "s/MOUNT_CHECK_BOOLEAN_VALUE/$MOUNT_CHECK/"  /etc/swift/container-server/$NUMBER-container-server.conf
        sed -i "s/VM_TEST_MODE_BOOLEAN_VALUE/$VM_TEST_MODE/"  /etc/swift/container-server/$NUMBER-container-server.conf

        if [ "$IPV6_SUPPORT" = "true" ]; then
            msg=${msg}"\n$RING_BUILDER $SWIFT_CONF/container.builder add z$NUMBER-[$PROXY_IPADDR]:$C_PORT/sdb$NUMBER 1 "
        else
            msg=${msg}"\n$RING_BUILDER $SWIFT_CONF/container.builder add z$NUMBER-$PROXY_IPADDR:$C_PORT/sdb$NUMBER 1 "
        fi
    done

    printf "\t\t Setting up container ring builder script \n"
    C_RINGSCRIPT="/tmp/container_ring_builder.sh"
    if [ ! -e $C_RINGSCRIPT ]; then
        touch $C_RINGSCRIPT
    else
        rm -f $C_RINGSCRIPT
    fi

    echo -e "$RING_BUILDER $SWIFT_CONF/container.builder create $PART_POWER $REPLICAS $PART_HOUR " >> $C_RINGSCRIPT
    echo -e ${msg} >> $C_RINGSCRIPT
    echo -e "$RING_BUILDER $SWIFT_CONF/container.builder rebalance \n" >> $C_RINGSCRIPT

    printf "\t\t Creating container server ring file \n"
    bash $C_RINGSCRIPT >> /tmp/ring_creation.log
    printf "\n"

return 0 
}
