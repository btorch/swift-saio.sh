#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/05/03
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to setup the object-server portion of the swift SAIO environment.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

#########################
#  OBJECT SERVER SETUP 
#########################

setup_object (){

    # if the directory already exists, just clean it up 
    if [ -d $SWIFT_CONF/object-server ]; then 
        rm -f $SWIFT_CONF/object-server/* 
    else
        mkdir -p $SWIFT_CONF/object-server
    fi 

    printf "\t\t Setting up object-server configs \n"

    msg=""
    RING_BUILDER=`which swift-ring-builder`

    for NUMBER in `seq 1 4`;
    do
        O_PORT="60"$NUMBER"0"
        cp $TEMPLATES/object-server/object-server.conf.tmpl  /etc/swift/object-server/$NUMBER-object-server.conf
        sed -i "s/BINDIP/$BIND_IP/"  /etc/swift/object-server/$NUMBER-object-server.conf
        sed -i "s/PORT/$O_PORT/"  /etc/swift/object-server/$NUMBER-object-server.conf
        sed -i "s#MOUNTPOINT#$MOUNT_LOCATION#"  /etc/swift/object-server/$NUMBER-object-server.conf
        sed -i "s/MOUNT_CHECK_BOOLEAN_VALUE/$MOUNT_CHECK/"  /etc/swift/object-server/$NUMBER-object-server.conf
        sed -i "s/VM_TEST_MODE_BOOLEAN_VALUE/$VM_TEST_MODE/"  /etc/swift/object-server/$NUMBER-object-server.conf

        if [ "$IPV6_SUPPORT" = "true" ]; then
            msg=${msg}"\n$RING_BUILDER $SWIFT_CONF/object.builder add z$NUMBER-[$PROXY_IPADDR]:$O_PORT/sdb$NUMBER 1 "
        else
            msg=${msg}"\n$RING_BUILDER $SWIFT_CONF/object.builder add z$NUMBER-$PROXY_IPADDR:$O_PORT/sdb$NUMBER 1 "
        fi
    done

    printf "\t\t Setting up object ring builder script \n"
    O_RINGSCRIPT="/tmp/object_ring_builder.sh"
    if [ ! -e $O_RINGSCRIPT ]; then
        touch $O_RINGSCRIPT
    else
        rm -f $O_RINGSCRIPT
        touch $O_RINGSCRIPT
    fi

    echo -e "$RING_BUILDER $SWIFT_CONF/object.builder create $PART_POWER $REPLICAS $PART_HOUR " >> $O_RINGSCRIPT
    echo -e ${msg} >> $O_RINGSCRIPT
    echo -e "$RING_BUILDER $SWIFT_CONF/object.builder rebalance \n" >> $O_RINGSCRIPT

    printf "\t\t Creating object server ring file \n"
    bash $O_RINGSCRIPT >> /tmp/ring_creation.log
    printf "\n"

return 0 
}
