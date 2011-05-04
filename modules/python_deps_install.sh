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
