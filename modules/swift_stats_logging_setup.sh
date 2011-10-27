#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/07/13
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to setup stats logging for this swift SAIO install.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
#  SLOGGING SETUP
###########################

slogging_setup () {

    SWAUTH_PREP=`which swauth-prep`
    SWAUTH_ADD=`which swauth-add-user`
    SWAUTH_LIST=`which swauth-list`
    STATS_ACCOUNT="stats2"
    STATS_USER="stats2"
    STATS_PW="stats2"
    STATS_DIRECTORY="/var/log/swift/stats"
    ACCESS_STATS_DIRECTORY="/var/log/swift/access-log-delivery"

    SLOGGING_REPO="deb http://notmyname.github.com/slogging-debian/lucid lucid main"
    SLOGGING_APT_LIST="/etc/apt/sources.list.d/slogging_github.list"

    ACCESS_LOG_UPLOADER="/etc/cron.d/swift-access-log-uploader"
    ACCESS_LOG_UPLOADER_CRON="10 * * * * swift swift-log-uploader /etc/swift/log-processor.conf access"
    STATS_LOG_CREATOR="/etc/cron.d/swift-stats-log-creator"
    STATS_LOG_UPLOADER="/etc/cron.d/swift-stats-log-uploader"
    STATS_LOG_CREATOR_CRON="0 * * * * swift swift-account-stats-logger /etc/swift/log-processor.conf"
    STATS_LOG_UPLOADER_1_CRON="10 * * * * swift swift-log-uploader /etc/swift/log-processor.conf stats"
    STATS_LOG_UPLOADER_2_CRON="30 * * * * swift swift-log-uploader /etc/swift/log-processor.conf container-stats"
    CONTAINER_STATS_LOG_CREATOR="/etc/cron.d/swift-container-stats-log-creator"
    CONTAINER_STATS_LOG_CREATOR_CRON="20 * * * * swift swift-container-stats-logger /etc/swift/log-processor.conf"

    ACCESS_LOG_DELIVERY="/etc/cron.d/access-log-delivery"
    ACCESS_LOG_DELIVERY_CRON="50 * * * * swift swift-access-log-delivery /etc/swift/access-log-delivery.conf  2> /dev/null"


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


    printf "\n\t - Setting up swift slogging"

    # If swift version is 1.4.2 or greater then slogging is now a seperate project on github
    # We can install it from notmyname github deb repo. Support is only available on swift 1.4.2 and higher
    VER_REGEX="^1\.[4-9]\.[2-9]"
    if [[ "$VERSION" =~ $VER_REGEX ]]; then

    
        if [ -d $STATS_DIRECTORY ]; then 
            mkdir -p $STATS_DIRECTORY
            chown swift.swift $STATS_DIRECTORY
        fi

        if [ -d $ACCESS_STATS_DIRECTORY ]; then 
            mkdir -p $ACCESS_STATS_DIRECTORY
            chown swift.swift $ACCESS_STATS_DIRECTORY
        fi


        echo "$SLOGGING_REPO"  >$SLOGGING_APT_LIST

        printf "\n\t\t - Installing python-slogging for swift stats from its github repo"
        apt-get update -qq
        apt-get install -y -qq python-slogging slogging-doc --force-yes &>/dev/null
        
        CODE=$?
        if [ $CODE -eq 0 ];then
            printf "\n\t\t  -> Install sucessful \n"
        else
            printf "\t\t\t -> \033[1;31;40m Error found (check log file)  \033[0m\n\n"
            exit 1
        fi

        printf "\n\t\t - Setting up stats swift account"
        $SWAUTH_ADD -K $SWAUTHKEY_VALUE -A $PRIV_AUTH_URL -a $STATS_ACCOUNT $STATS_USER $STATS_PW 
	sleep 5
        STATSHASH=`$SWAUTH_LIST -A $PRIV_AUTH_URL -K $SWAUTHKEY_VALUE $STATS_ACCOUNT | python -mjson.tool |grep "account_id" | tr -d " " | tr -d "\"" | tr -d "," | cut -d ":" -f 2` 

        printf "\n\t\t - Configuring log-processor.conf (proxy and object) \n"
        cp $TEMPLATES/log-processor.conf.tmpl  /etc/swift/log-processor.conf
        sed -i "s/STATSHASH/$STATSHASH/g" /etc/swift/log-processor.conf
        sed -i "s#MOUNTPOINT#$MOUNT_LOCATION#g"  /etc/swift/log-processor.conf
        sed -i "s/MOUNT_CHECK_BOOLEAN_VALUE/$MOUNT_CHECK/g"  /etc/swift/log-processor.conf
        
        printf "\n\t\t - Setting up Proxy server related cronjobs for stats"
        printf "\n\t\t   Adding : $ACCESS_LOG_UPLOADER \n\n"
        echo "$ACCESS_LOG_UPLOADER_CRON" >$ACCESS_LOG_UPLOADER         

        printf "\n\t\t - Setting up Object server related cronjobs for stats"
        printf "\n\t\t   Adding : \n\t\t\t $STATS_LOG_CREATOR \n\t\t\t $CONTAINER_STATS_LOG_CREATOR \n\t\t\t $STATS_LOG_UPLOADER \n"
        echo "$STATS_LOG_CREATOR_CRON" >$STATS_LOG_CREATOR         
        echo "$CONTAINER_STATS_LOG_CREATOR_CRON" >$CONTAINER_STATS_LOG_CREATOR
        echo "$STATS_LOG_UPLOADER_1_CRON" >$STATS_LOG_UPLOADER
        echo "$STATS_LOG_UPLOADER_2_CRON" >>$STATS_LOG_UPLOADER


        printf "\n\t\t - Configuring access-log-delivery.conf (usually on a data collection box) "
        cp $TEMPLATES/access-log-delivery.conf.tmpl  /etc/swift/access-log-delivery.conf
        sed -i "s/STATSHASH/$STATSHASH/g" /etc/swift/access-log-delivery.conf
        sed -i "s#MOUNTPOINT#$MOUNT_LOCATION#g"  /etc/swift/access-log-delivery.conf
        sed -i "s/MOUNT_CHECK_BOOLEAN_VALUE/$MOUNT_CHECK/g"  /etc/swift/access-log-delivery.conf

        printf "\n\t\t - Setting up Access log delivery related cronjobs "
        printf "\n\t\t   Adding : $ACCESS_LOG_DELIVERY \n"
        echo "$ACCESS_LOG_DELIVERY_CRON" >$ACCESS_LOG_DELIVERY

        printf "\n\t\t - Reloading crond \n\n"
        /etc/init.d/cron reload &>/dev/null

    fi

}
