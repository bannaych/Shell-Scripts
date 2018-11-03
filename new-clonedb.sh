#!/bin/bash
## script to take Target volumes with Production snapshots
## Author : Chris Bannayan
## Date : 25/06/2017
#
#

BOLD=`tput smso`
NORM=`tput rmso`

# Arrays to connect to
# sydney#
FA1="192.168.111.140"
# Singapore
#FA1="10.219.224.112"

PGROUP=ora1

# User to connect with
#
USER="pureuser"

# logfile function
#LOGFILE="snap.log"

log_note ()
{
        echo "`date +%d/%m/%y--%H:%M`" $* >> /home/oracle/scripts/pure.log
}


Check_fs ()
{
export MOUNT=/u01

#om=$(ps -ef|grep pmon|grep -v grep)
#if [ "${#om}" -eq 0 ]
# then

if grep -qs $MOUNT /proc/mounts; then
  echo "$Mount is mounted."
  exit 0
else
  echo "It's not mounted."
fi
#sudo umount /u01
#else
# echo "Cannot unmount $MOUNT"
#3 exit -1
#fi
}


#purevol copy --overwrite testvolcb1.4197 testvol1


#
# Volumes to snapshot
##


#PGROUP="demo-pg"

# Targeet Volume Variabe
VOLTARGET="orahost2"
# Primary volume variable
VOLPRIM="orahost1"

clear

echo "$BOLD Shutting down Oracle... $NORM "
echo "shutdown immediate" | sqlplus -s / as sysdba

sleep 2
echo "$BOLD Unmount the /u01 filesystem $NORM"
sudo umount -l /u01
sleep 1
Check_fs

#
# ssh to array to get snap list
#
#ssh $USER@$FA1 "purevol list --snap --pgroup $PGROUP" > snap.log
ssh $USER@$FA1 "purevol list --snap" > snap.log

#
# couple of loops to get Target and Primary volume and output them to a log file
#

#for x in $VOLTARGET
#do
#grep $x ./snap.log|awk '{print $3}'|head -1
#done > snap1.log
echo $VOLTARGET > snap1.log

awk '{print $1}' snap.log > snaps
echo " Select from Last 5 snapshots\n "
IFS=$'\n' read -d '' -r -a lines < ./snaps 
SNAPS="${lines[1]} ${lines[2]} ${lines[3]} ${lines[4]} ${lines[5]} quit" 
select mysnap in $SNAPS
do
  case $mysnap in
     ${lines[1]} )
printf "%s\n" "${lines[1]}"|tee > cb.log
     ;;
    ${lines[2]} )
printf "%s\n" "${lines[2]}"|tee > cb.log
     ;;
     ${lines[3]})
printf "%s\n" "${lines[3]}"|tee > cb.log
     ;;
     ${lines[4]})
printf "%s\n" "${lines[4]}"|tee > cb.log
     ;;
     ${lines[5]})
printf "%s\n" "${lines[5]}"|tee > cb.log
     ;;
     quit)
     break
     ;;
esac
done
 paste cb.log snap1.log > cb1.log
#
# Main loop to ssh into array and run the refresh
#

input="cb1.log"

      echo "$BOLD refreshing from latest $VOLPRIM snapshot `cat cb1.log|awk '{print $1}'` ... $NORM"
      while IFS=" " read -r f1 f2; do ssh $USER@$FA1 purevol copy --overwrite "$f2" "$f1" </dev/null

   done < "$input"

echo "$BOLD Mounting the /u01 filesystem $NORM"
sudo mount /u01
sleep 1
echo "$BOLD Stating Oracle.... $NORM"
echo "startup mount" | sqlplus -s / as sysdba
echo "alter system set db_unique_name='TARGET' scope=spfile;" | sqlplus -s / as sysdba
echo "shutdown abort" | sqlplus / as sysdba
echo "startup" | sqlplus -s / as sysdba
#echo "alter system set db_unique_name='TARGET' scope=spfile"| sqlplus -s / as sysdba:1

