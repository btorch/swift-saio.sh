#
#   Author: Marcelo Martins (btorch AT gmail.com)
#   Created: 2011/05/03
#
#   Info:
#       This a script that is imported (sourced) by the main swift-saio.sh in order 
#       to setup the loopback device(s) that will be used by swift SAIO environment.
#       Created it as a separate file so that it can re-used or extended wihout 
#       impacting the main script.
#

#########################
#  LOOPBACK SETUP 
#########################

setup_loopdev (){

    MOUNT=$1
    DISKFILE=$2
    BS_VALUE=$3
    SEEK_VALUE=$4

    printf "\n\t - Starting Storage devices setup (loopback) "
    printf "\n\t\t PLEASE NOTE: Everything under $MOUNT will be deleted if already exists "
    printf "\n\t\t Would you like to proceed ? (y/n) "
    
    read choice
    if [ "$choice" = "y" ]; then

        # Check for existing mount point 
        mount -v | grep -w "$MOUNT" &> /dev/null 

        # If mount location not found mounted
        if [ $? -eq 1 ]; then

            cat /etc/fstab | grep -w "$DISKFILE" &> /dev/null 
            if [ $? -eq 0 ]; then
                # Removes fstab line that contains basename of DISKFILE  
                sed -i -e  "/`basename $DISKFILE`/d" /etc/fstab
            fi

            if [ ! -d $MOUNT ]; then
                printf "\n\t\t Creating mount location : $MOUNT "
                mkdir -p $MOUNT
            fi

        else
            # unmount directory  
            printf "\n\t\t Removing existing mount : $MOUNT "
            umount $MOUNT

            cat /etc/fstab | grep -w "$DISKFILE" &> /dev/null 
            if [ $? -eq 0 ]; then
                # Removes fstab line that contains basename of DISKFILE  
                sed -i -e  "/`basename $DISKFILE`/d" /etc/fstab
            fi

        fi

        printf "\n\t\t Setting up /etc/fstab file "
        echo -e "$DISKFILE \t $MOUNT \t xfs \t loop,noatime,nodiratime,nobarrier,logbufs=8 0 0" >>  /etc/fstab

        printf "\n\t\t Setting up disk image and mount settings \n"
        dd if=/dev/zero of=$DISKFILE count=0 bs=$BS_VALUE  seek=$SEEK_VALUE  &> /dev/null
        mkfs.xfs -q -f -i size=1024 $DISKFILE
        mount $MOUNT
        mkdir -p $MOUNT/sdb1 $MOUNT/sdb2 $MOUNT/sdb3 $MOUNT/sdb4

    else
        printf "\n\t\t Proceeding without storage device setup "
        printf "\n\t\t You will need to set those up manually in order for installation to work properly "
        SKIP_FINAL_STAGE="true"
    fi

return 0 
}
