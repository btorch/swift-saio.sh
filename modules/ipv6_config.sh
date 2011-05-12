#!/bin/bash

#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/05/03
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to check IPv6 possible setup.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
#  IPV6 CHECKS 
###########################


ipv6_banner (){

    printf "\n\t #######################################################"
    printf "\n\t #            IPV6 PRE-CONFIGURATION NOTES             #"
    printf "\n\t #######################################################"
    printf "\n\t #  "
    printf "\n\t # - This script will NOT setup IPv6 addreses/network for you   "
    printf "\n\t #  "
    printf "\n\t # - You MUST already have configured IPv6 on this system prior "
    printf "\n\t #   to trying to installing this swift-SAIO using the -6 flag  "
    printf "\n\t #  "
    printf "\n\t # - You can use IPv6 ULA addresses or Global addresses         "
    printf "\n\t #  "
    printf "\n\t # - IPv6 LocalLink addresses are not supported                 "
    printf "\n\t #  "
    printf "\n\t # - The IPv6 address MUST exist on the interface you assign to "
    printf "\n\t #   the PROXY_IFACE variable in the swift-saio.cfg file        "
    printf "\n\t #  "
    printf "\n\t # - DO NOT use \"::\" to represet a single contiguous group of "
    printf "\n\t #   zero fields                                                 "
    printf "\n\t #  "
    printf "\n\t # \n"

}


ipv6_check (){

    IP6_ULA_REGEX="^(fc|fd)"
    IP6_GLOBAL_REGEX="^(2|3)"
    PROXY_IFACE="eth0"
    IP6ADDR=`ip -6 addr show $PROXY_IFACE | grep inet6 | grep -i "global" | awk '{print $2}' | cut -d "/" -f 1`

    # Check IP6 and see if it needs to be expanded 
    NUM_OF_COLONS=7
    OCCOURS=`echo $IP6ADDR | grep -o "::" | wc -l | sed s/\ //g`

    if [[ $OCCOURS -eq 1 ]]; then 
        printf "\n\t Please make sure your IPv6 address has \"::\" in an expanded format "
        printf "\n\t\t E.g: fdef:8130:6627::100  should be fdef:8130:6627:0:0:0:0:100  "
        printf "\n\t Quitting .... \n"
        exit 1
    fi 


    # Check if IP address is ULA or Global
    if [[ ! $IP6ADDR =~ $IP6_ULA_REGEX ]] && [[ ! $IP6ADDR =~ $IP6_GLOBAL_REGEX ]]; then 
        printf "\n\t The IPv6 address type found is not supported. Only ULA or Global supported \n" 
        usage_display
        exit 1
    else
        printf "\n\t - IPv6 checks passed .. proceeding \n"
        PROXY_IPADDR="$IP6ADDR"
    fi

}
