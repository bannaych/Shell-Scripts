##!/bin/bash
#
# Script to report on Storage Capacity and Snapshot utilisation
# Chris Bannayan 28/10/17
# updated 11/12/17
# Version: 0.3
# Update 0.4 - Added Space consumption by Volume and Percentage change since last report run
# Update 0.5 - Added Snap and Snap space usage to volume section
# Update 0.5 - Formatted awk printf statement in volume report section, added timestamp information


#
# Seting up some variables..


BOLD=`tput smso`
NORM=`tput rmso`

LOGDIR=/home/oracle/scripts/GWF
USER=$1
FA1=$2
APPEND=/home/oracle/scripts/GWF/append#

CURR_DATE=$(date "+%D %H:%M" )
READ_DATE=$(cat $LOGDIR/timelog )


space()
   {
      echo ""
   }

if [ -d $LOGDIR ]
    then continue
    else
    mkdir $SNAPDIR
fi


# Clean up gwfdiff files
ls -t compare/gwfdiff*|tail -n +5|xargs rm -f

clear
 ssh $USER@$FA1 "purevol list --csv --space --total" > $LOGDIR/pure-raw-data.log
 ssh $USER@$FA1 "purevol list --snap --total" > $LOGDIR/pure-raw-snap.log
 ssh $USER@$FA1 "purepgroup list "|awk '{print $1}'|sed 1d > $LOGDIR/pgroup.list


space
echo " $BOLD PUREARRY OVERVIEW  $CURR_DATE $NORM"
echo "$CURR_DATE" > $LOGDIR/timelog
space
space

ssh $USER@$FA1 "purearray list --space"
space
space
space

#
# Printing out Volume Overview
#

echo " $BOLD VOLUME OVERVIEW $NORM"
space

fmt="%-24s %-23s %-19s\n"
printf "$fmt" Total_Volumes  Total_Volvume_Snapshots
printf "$fmt" -------------  -----------------------

vol=`ssh $USER@$FA1 "purevol list --space --csv --total" | wc -l`
ssh $USER@$FA1 "purevol list --space --csv --total" > cbvol1
snap=`ssh $USER@$FA1 "purevol list --snap" | wc -l`

printf "%-24s %-24s  %-18s\n" "$vol" "$snap"

#vol=`cat cbvol|wc -l`
sed '1d; $d' cbvol1 > cbvol2

# Copy the cbvol2 volume as vol1, use vol1 as the current copy to test againt the new report run
#cp cbvol2 vol1

space
echo "Total Vol unique space + snaps | Total Effective Space calculated per volume"
awk -F, '{ sum+=$10/1024/1024/1024}
         { eff+=$10*$4/1024/1024/1024}

 END {print sum"GB","\t\t\t",eff"GB"}' cbvol2 | tee compare/gwfdiff.$$

LATEST_FILE=`ls -t compare/gwfdiff*|head -2`
space
pr -mts $LATEST_FILE |sed 's/GB//g'|awk '{printf "Percentage Change since last report""   " "%.2f",($1-$3)/($3)*100} '|tee -a $APPEND

#
# Printing out Host Overview
#

space
echo " $BOLD HOST OVERVIEW $NORM"
space

fmt="%-24s %-23s \n"
printf "$fmt" Total_Hosts    Total_Host_Space
printf "$fmt" -------------  ------------------

host=`ssh $USER@$FA1 "purehost list --notitle" | wc -l`
ssh $USER@$FA1 "purehost list --space --notitle --csv" > hosts
space=`cat hosts|awk -F, '{ sum+=$8/1024/1024/1024} END {print sum}'`

 printf "%-24s %-24s \n" "$host" "$space"

echo "Note: Total Host space includes Snaphosts"


# Priting out Protection group Overview
#

space
space
echo " $BOLD PROTECTION GROUPS OVERVIEW $NORM"
space

fmt="%-24s %-23s %-19s\n"

ssh $USER@$FA1 "purepgroup  list --space --total"|sed '1d;$d'|sort -r -n -k 2|awk 'BEGIN{ { print "Count","Pgroup Name","\t\t""Pgroup Size"}}{{printf FNR "%16s %25s\n", $1,$2}}'
space
space

# Print out Per volume space consumption and % change since last report run
#

cat vol1|awk -F, '{print $1,$10}' |sed '/ 0/d' > vol2
cat cbvol2|awk -F, '{print $10}' |sed '/^0/d'>  vol3
awk  -F, '{print $7/1024/1024}' GWF/pure-raw-data.log > sn4
grep -v -e  "^0$" sn4 > sn5
ssh pureuser@192.168.111.140 "purevol list --snap --space" > snap-list

     for i in `awk '{print $1}' vol2`
         do
         grep -w $i snap-list|wc -l
     done > vol-sn


paste vol2 vol3 > vol4
awk '{print $1, $2/1024/1024/1024,$3/1024/1024/1024}' vol4 > vol5
sed -i '/0 0/d' vol5
paste vol5 vol-sn sn5 > vol6
#awk 'BEGIN {print "Vol Name","\t", "Vol Size","\t","New Size ","\t","% Change","\t","# of snaps","\t", "Snap Size GB"}{print $1,"\t", $2,"\t", $3,"\t",($3-$2)/($2)*100,"\t",$4,"\t\t" $5}' vol6

echo "Last Run:     $READ_DATE"
echo "Current Date: $CURR_DATE"
echo ""
awk -F' '  'BEGIN {print "Vol Name","\t", "Vol Size GB","\t","New Size GB","\t","% Change","\t","# of snaps","\t", "Snap Size GB"}{printf "%-16s %-9.3f %12.3f %15.2f %11d %22.3f\n", $1, $2, $3, ($3-$2)/($2)*100,$4,$5}' vol6

cp cbvol2 vol1
