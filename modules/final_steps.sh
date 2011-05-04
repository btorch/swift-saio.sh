#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/05/03
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to perform the last steps of the actuall swift SAIO environment setup.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

################
#  FINAL STEPS  
################

final_steps (){

    printf "\n\t - Final Setup Steps "

    UCHECK=`cat /etc/passwd | grep swift > /dev/null ; echo $?`
    GCHECK=`cat /etc/group | grep swift > /dev/null ; echo $?`
    if [ ! $GCHECK -eq 0 ] &&  [ ! $UCHECK -eq 0 ]; then
        printf "\n\t\t Adding swift user & group "
        groupadd swift
        useradd -s /bin/false -g swift swift
    else
        printf "\n\t\t User/group swift already exists "
    fi

    printf "\n\t\t Creating /var/run/swift and /var/log/swift"
    mkdir -p /var/run/swift /var/log/swift
    chown swift.swift /var/run/swift
    chown swift.swift /var/log/swift

    printf "\n\t\t Setting up proper ownerships \n"
    chown -R swift.swift $SWIFT_CONF
    chown swift.swift $MOUNT_LOCATION
    chown -R swift.swift $MOUNT_LOCATION

return 0
}
