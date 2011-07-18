#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/07/18
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to setup syslog-ng configuration for this swift SAIO install.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
#  SYSLOG-NG SETUP
###########################

swift_syslog_ng_setup (){

    printf "\n\t - Setting up syslog-ng for swift logging \n"
    printf "\t\t - Creating /var/log/swift directory \n"
    mkdir -p /var/log/swift
    chown swift.swift /var/log/swift

    apt-get purge rsyslog -Vy &>/dev/null
    printf "\t\t - Installing syslog-ng \n"
    apt-get install syslog-ng -Vy &>/dev/null 

    printf "\t\t - Setting up syslog-ng.conf"
    cp $SYSLOGNG/syslog-ng.conf.tmpl /etc/syslog-ng/syslog-ng.conf

    printf "\t\t - Restarting syslog-ng"
    /etc/init.d/syslog-ng restart | sed 's/^/\t\t/g'
    
    sleep 2

return 0
}

