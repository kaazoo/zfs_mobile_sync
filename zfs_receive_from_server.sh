#!/bin/bash

export PATH="/usr/gnu/bin:/usr/local/bin:/bin:/usr/bin"

USERNAME=$1
ZFS_SRC="data/profiles/$USERNAME" 
ZFS_DEST="data/profiles/$USERNAME" 
SERVER="SERVERNAME" 
SYNC_GROUP="zfs_mobile_sync" 
REMOTE_USER="zfs_mobile_sync" 
LOGFILE="/var/log/zfs_receive_from_server.log"

echo User: $USERNAME
echo Source: $ZFS_SRC
echo Destination: $ZFS_DEST
echo Host: $SERVER
echo Group: $SYNC_GROUP
echo Remote user: $REMOTE_USER
echo Logfile: $LOGFILE

id $USERNAME | grep $SYNC_GROUP 2>&1 >/dev/null
ret=$?

if [ "$ret" -eq "0" ]; then
  echo "" >>$LOGFILE
  echo `date` >>$LOGFILE

  msg="Will sync home filesystem of user $USERNAME from server $SERVER" 
  echo ""
  echo $msg
  logger ZFS mobile user: $msg

  cd /usr/local/ZFS-TimeMachine
  cmd="./zfstimemachinebackup.perl --sourcedataset=$ZFS_SRC --sourcehost=$SERVER --destinationdataset=$ZFS_DEST \
  --snapshotstokeeponsource=100 --deletesnapshotsondestination=0 --sourcehostoptions="
  echo command: ${cmd}\"-l $REMOTE_USER -o PreferredAuthentications=publickey\" -v
  echo ""
  logger ZFS mobile user: ${cmd}\"-l $REMOTE_USER -o PreferredAuthentications=publickey\" -v
  ${cmd}"-l $REMOTE_USER -o PreferredAuthentications=publickey" -v \
  2>&1 | tee -a $LOGFILE
else
  msg="User $USERNAME not in group ${SYNC_GROUP}!" 
  echo $msg
  logger ZFS mobile user: $msg
fi

zfs get mounted $ZFS_DEST | grep no 2>&1 >/dev/null
ret=$?

if [ "$ret" -eq "0" ]; then
  zfs mount $ZFS_DEST
fi
