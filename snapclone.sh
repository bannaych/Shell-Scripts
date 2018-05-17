#!/bin/bash
# script:   Snapclone.sh - refresh oracle databases using Pure Storge Snapshots
# Author:   Chris Bannayan
# Date:     25/06/2017
# Rev:      0.8
# Platform: Unix,Linux


#
# Define Bold and non-bold screen output
#

BOLD=`tput smso`
NORM=`tput rmso`
SNAPDIR=$PWD/snapdir

# Define the Arrays and Users to connect to
# Sydney Lab

FA1="192.168.111.140"
USER="pureuser"
PGROUP=ora1


# Define the Targeet Volume to refresh
VOLTARGET="orahost2"
# Define htre Primary volume to take snapshots from
VOLPRIM="orahost1"

# logfile function
# LOGFILE="snap.log"

log_note ()
{
        echo "`date +%d/%m/%y--%H:%M`" $* >> /home/oracle/scripts/pure.log
}

if [ -d $SNAPDIR ]
  then continue
else
  mkdir $SNAPDIR
fi


#
# Function to check whehter the /u01 filesystem is mounted
#

Check_fs ()
{
export MOUNT=/u01
if grep -qs $MOUNT /proc/mounts; then
  echo "$Mount is mounted."
  exit 0
else
  echo "It's not mounted."
fi

}

# Shutting down Oracle to apply snapshot refresh
#

clear

echo "$BOLD Shutting down Oracle... $NORM "
echo "shutdown immediate" | sqlplus -s / as sysdba

sleep 2
echo "$BOLD Unmount the /u01 filesystem $NORM"
sudo umount -l /u01
sleep 1
Check_fs

#
# ssh to the Pure array and get Volume snap listing
#
#ssh $USER@$FA1 "purevol list --snap --pgroup $PGROUP" > snap.log
ssh $USER@$FA1 "purevol list --snap" > $SNAPDIR/snap.log

#
# couple of loops to get Target and Primary volume and output them to a log file
# Get Listing on last 5 snapshots, then pick the snapshot to refresh with.
#


echo $VOLTARGET > $SNAPDIR/snap1.log

awk '{print $1}' $SNAPDIR/snap.log > $SNAPDIR/snaps
printf "\n"
printf "Select from the followint five snapshots\n "
printf "==========================================="
printf "\n"
IFS=$'\n' read -d '' -r -a lines < $SNAPDIR/snaps 
SNAPS="${lines[1]} ${lines[2]} ${lines[3]} ${lines[4]} ${lines[5]} quit" 
     select mysnap in $SNAPS
         do
           case $mysnap in
           ${lines[1]} )
           printf "Snapshot: %s\n" "${lines[1]}" |tee $SNAPDIR/cb.log
           ;;
           ${lines[2]} )
           printf "Snapshot: %s\n" "${lines[2]}"|tee $SNAPDIR/cb.log
           ;;
          ${lines[3]})
           printf "Snapshot: %s\n" "${lines[3]}"|tee $SNAPDIR/cb.log
           ;;
           ${lines[4]})
           printf "Snapshot: %s\n" "${lines[4]}"|tee $SNAPDIR/cb.log
           ;;
           ${lines[5]})
           printf "Snapshot: %s\n" "${lines[5]}"|tee $SNAPDIR/cb.log
           ;;
           quit)
           break
           ;;
           esac
        done
 
 paste $SNAPDIR/cb.log $SNAPDIR/snap1.log > $SNAPDIR/cb1.log

#
# Main loop to ssh into array and run the refresh
#

input="cb1.log"

      echo "$BOLD refreshing from latest $VOLPRIM snapshot `cat cb1.log|awk '{print $1}'` ... $NORM"
      
      while IFS=" " read -r f1 f2 
         do ssh $USER@$FA1 purevol copy --overwrite "$f2" "$f1" </dev/null
      done < "$input"

echo "$BOLD Mounting the /u01 filesystem $NORM"
sudo mount /u01
sleep 1
echo "$BOLD Stating Oracle.... $NORM"
echo "startup mount" | sqlplus -s / as sysdba
echo "alter system set db_unique_name='TARGET' scope=spfile;" | sqlplus -s / as sysdba
echo "shutdown abort" | sqlplus / as sysdba
echo "startup" | sqlplus -s / as sysdba
#echo "alter system set db_unique_name='TARGET' scope=spfile"| sqlplus -s / as sysdba
