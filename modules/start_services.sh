#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/05/03
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to start all the swift services.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
#  START SWIFT SERVICES  
###########################

start_services (){

    SWIFTINIT=`which swift-init`
    MAIN_SERVICES=("proxy-server" "account-server" "container-server" "object-server")
    OBJECT_SERVICES=("object-replicator" "object-auditor" "object-updater")
    ACCOUNT_SERVICES=("account-auditor" "account-reaper" "account-replicator")
    CONTAINER_SERVICES=("container-updater" "container-replicator" "container-auditor")

    printf "\n\t - Starting up main services "

    for service in "${MAIN_SERVICES[@]}"
    do 
        printf "\n\t\t $service : "
        $SWIFTINIT $service start > /dev/null 
        ps -U swift -f | grep -w "swift-$service" > /dev/null
        if [ $? -eq 0 ]; then 
            echo "OK"
        else
            echo "FAIL"
        fi 
    done

    # Also start memcache and rsync
    printf "\n\t\t Starting memcached "
    /etc/init.d/memcached start > /dev/null

    printf "\n\t\t Starting rsyncd "
    /etc/init.d/rsync start > /dev/null

    printf "\n"

return 0 
}
