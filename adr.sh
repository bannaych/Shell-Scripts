#!/bin/bash
# Script to promote Disaster Recovery server using Active-DR
# Version 0.1
#

# Set variables

Array1=10.226.224.112
POD=ora-target
PGROUP=adr-rep-pg
USER=pureuser
SUFFIX=snap`date +%Y%m%d%M`
VOL1=drdatavol
VOL2=drfravol
DDMONYYYY=`date +%d%b%Y`
LOG="/home/oracle/adr_${DDMONYYYY}.log"


tput clear

if [[ $EUID -eq 0 ]]
then
  echo "This script cannot be run as root user please run again as user ${ORA_USER}"
   exit 0
fi


function logit ()
{

   echo "INFO `date`- ${*}" >> $LOG 2>&1

}

RC ()
{
 ERR=$?
   if [ $ERR -ne 1 ]
       then
       logit echo "Function had an error please review logs file and contact Administrator"
       mailx -s "Problem with Refresh Script on ${DBNAME}, please review log file and Contact Administrator " $MAILLIST
       exit 0
     fi
}


pgroup ()
{
ssh_cmd="$(cat <<-EOF
    purepgroup list $PGROUP
EOF
)"

result=`ssh -t pureuser@10.226.224.112 $ssh_cmd`
if [[ $result == *"Error"* ]]; then
  echo "It's not there"
  ssh pureuser@10.226.224.112 "purepgroup create $PGROUP"
  fi

}

create_snapshot()
{
  VOLUMES=$(ssh pureuser@10.226.224.112 " purevol list --filter \"name='ora-target::*'\" --csv"|grep -v Name|awk -F:: '{print $2}'|awk -F, '{print $1}')
for VOL in $VOLUMES; do
    SNAP_NAME="${VOL}.${SNAP_SUFFIX}"
    logit echo "Taking snapshot of volume $VOL as $SNAP_NAME..."
    logit "Function:""${FUNCNAME}:" ssh pureuser@10.226.224.112 "purevol snap ora-target::$VOL --suffix $SUFFIX"
done
}

copy-snap ()
{
ssh_cmd="$(cat <<-EOF
    purevol list $VOL1, $VOL2
EOF
)"

newvol=`ssh -t pureuser@10.226.224.112 $ssh_cmd`
echo $newvol
if [[ $newvol == *"Error"* ]]; then
  echo "Volumes are not created"
  logit "Function:""${FUNCNAME}:" ssh pureuser@10.226.224.112 "purevol copy ora-target::data.$SUFFIX drdatavol --overwrite"
  logit "Function:""${FUNCNAME}:"  ssh pureuser@10.226.224.112 "purevol copy ora-target::fra.$SUFFIX drfravol --overwrite"
  logit "Function:""${FUNCNAME}:" ssh pureuser@10.226.224.112 " purevol add drdatavol,drfravol --pgroup adr-rep-pg"
  else
  logit "Function:""${FUNCNAME}:" ssh pureuser@10.226.224.112 "purevol copy ora-target::data.$SUFFIX drdatavol --overwrite"
  logit "Function:""${FUNCNAME}:"  ssh pureuser@10.226.224.112 "purevol copy ora-target::fra.$SUFFIX drfravol --overwrite"
  fi

}

pgroup
create_snapshot
copy-snap
