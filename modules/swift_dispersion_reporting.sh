#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/07/13
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh.
#       Created it as a separate file so that it can be re-used or extended wihout 
#       impacting the main script.
#
#       This will setup the dispertion reporting and show the user how to test it
#       
#       The script still needs to use some variables that are configured in the 
#       swift-saio.cfg configuration file. 
#

###########################
#  DISPERSION REPORT
###########################

dispersion_setup () {

    printf "\n\t - Copying dispersion configuration file "
    printf "\n\t\t In order to run a dispersioin test just run the following commands"
    printf "\n\t\t   1) swift-dispersion-populate "
    printf "\n\t\t   2) swift-dispersion-report \n\n"


    cp $TEMPLATES/dispersion.conf.tmpl  /etc/swift/dispersion.conf
    sed -i "s/PORT/$PROXY_PORT/g"  /etc/swift/dispersion.conf

    if [[ $PROXY_SSL_ENABLED = "true" ]]; then
        sed -i 's/http/https/g' /etc/swift/dispersion.conf
    fi

    return 0
}

