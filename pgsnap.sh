#!/bin/bash
## script to take  protection groups snapshot
## Author : Chris Bannayan
## Date : 25/06/2017


# Setup the Arrays to connect to:
#
#sydney
FA1="192.168.111.140"
# Singapore
#FA1="10.219.224.112"

# Setup the FA User to connect with
USER="pureuser"

# Setup a logfile function
#LOGFILE="/Users/chrisb/VHA/snaplog"

log_note ()
{
        echo "`date +%d/%m/%y--%H:%M` Snap Completed for $PGROUP" $* >> /home/oracle/pure.log
}



#
# Add the name of the protection group to snap
##

PGROUP="ora-pg"

#

#for i in $VOLLIST
#    do
#SUFFIX=$i


#
# Main loop to create the protection group snap
#
clear
echo ""
tput cup 10 2
echo " About to Snapshot the Protection Group $PGROUP - Press Enter to continue "
read ans

      ssh $USER@$FA1 "for i in $PGROUP
             
             do 
               echo "======================================"
               purepgroup snap  \$i 
              if (( $? != 0 ))
              then
              echo  "Snap Failed for \$i"
              else
              echo "Snap completed for \$i"
              echo ""
              echo "" 
               echo "======================================"
              fi
 done";log_note

