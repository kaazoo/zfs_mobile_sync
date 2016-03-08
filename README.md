# zfs_mobile_sync
Mac OSX mobile accounts using ZFS snapshots

* Each user account has the home directory on an own ZFS filesystem.
* A snapshot of the home filesystem is created on logout and transfered to the server.
* On user login all missing snapshots are transfered from the server to the client so that the home filesystem of the user contains the most recent data.
* Snapshots are automatically thinned by ZFS-Timemachine.
* On client, local ZFS oerations happen as root user.
* Authentication on the server by SSH public key as user 'zfs_mobile_sync'.
* Remote shell is restricted by rssh for ZFS use only.

## Dependencies:

* ZFS-TimeMachine (https://github.com/jollyjinx/ZFS-TimeMachine)
* rssh with ZFS support (https://github.com/kaazoo/homebrew/blob/master/Library/Formula/rssh.rb)

## Server setup

* User accounts are stored in LDAP.
* Create parent filesystem for user profiles on zpool 'data':
<pre>
zfs create -o canmount=off data/profiles
</pre>
* Add local user account 'login_sync' with 'rssh' as login shell.
* Add option 'allowzfs' to rssh.conf.

## Client setup

* Configure LDAP server for user authentication.
* Shrink system partition or use separate disk.
* Install ZFS: https://openzfsonosx.org/
* Create zpool 'data' and parent filesystem for user profiles:
<pre>
zpool create data /dev/disk1s4
zfs set compression=lz4 data
zfs set atime=off data
zfs set com.apple.browse=off data
zfs set canmount=off data
zfs create -o canmount=off data/profiles
</pre>
* Install ZFS-TimeMachine at /usr/local/ZFS-TimeMachine:
<pre>
cd /usr/local
git clone https://github.com/jollyjinx/ZFS-TimeMachine.git
</pre>
* Place login hook script at '/usr/local/bin/zfs_receive_from_server.sh'
* Place logout hook script at '/usr/local/bin/zfs_send_to_server.sh'
* Modify script variables 'ZFS_SRC', 'ZFS_DEST', 'SERVER', 'SYNC_GROUP', 'REMOTE_USER'
* Activate hooks:
<pre>
chmod +x /usr/local/bin/zfs_send_to_server.sh
chmod +x /usr/local/bin/zfs_receive_from_server.sh
sudo defaults write com.appleloginwindow LogoutHook /usr/local/bin/zfs_send_to_server.sh
sudo defaults write com.appleloginwindow LoginHook /usr/local/bin/zfs_receive_from_server.sh
</pre>
* Become root user, create SSH public key and import hostkey of server:
<pre>
sudo -i
ssh-keygen -b 4096
ssh-keyscan SERVER >>.ssh/known_hosts
</pre>
* Add SSH public key of root user on server in file '.ssh/authorized_keys' of user 'zfs_mobile_sync'


## Creating new mobile users

* Create user account 'user123' in LDAP and add to group 'zfs_mobile_sync'.
* Create filesystem 'data/profiles/user123' with mountpoint '/Users/user123' on server:
<pre>
zfs create -o mountpoint=/Users/user123 -o canmount=noauto data/profiles/user123
</pre>
* Add permissions for user 'zfs_mobile_sync' on server:
<pre>
zfs allow zfs_mobile_sync create,destroy,snapshot,mount,send,receive data/profiles/user123
</pre>
* Create filesystem 'data/profiles/user123' with mountpoint '/Users/user123' on client and set ownership:
<pre>
zfs create -o mountpoint=/Users/user123 data/profiles/user123
chown -R user123:staff /Users/user123
</pre>
* Log in as user on client.
* Log out.
* Check if ZFS snaphosts have been transfered to server.


## Pros

* Home folders are synchronized completely.
* Use of ZFS features: compression, checksums, snapshots.
* Transfer of changed data should be faster than file-based approaches like rsync.

## Cons

* Specific files / folders can't be excluded from the transfer.
* No graphical status / progress output on login / logout while transfer is happening, only shell output / syslog.

