#!/bin/bash

# This script assumes the container exists, is running, and contains
# the correct file path already (which it will in the create_container.sh file)

if [[ $# -ne 2 ]]
then
  echo "Enter 1) container name and 2) new full file path for auth.log (for container, not from host)"
  exit 1
fi

# container filepath in the host
rsyslog_path=/var/lib/lxc/"$1"/rootfs/etc/rsyslog.d/50-default.conf
touch ~/temp.txt
touch ~/rsyslog-copy.txt

# allows any attacker to write to the file, making sure we can track 
# any alterations they make and that rsyslog can write there 
sudo lxc-attach -n "$1" -- chmod a+w "$2"

# attackers can read file and determine this is the auth.log file
# tracking their actions and should therefore delete it
sudo lxc-attach -n "$1" -- chmod a+r "$2"

sudo lxc-attach -n "$1" -- chown syslog:adm "$2"

# temporary file to copy *default.conf file in rsyslog.d directory
sudo cp "$rsyslog_path" ~/rsyslog-copy.txt
# reads in each line 
while read -r line
do

  # if line matches default logging location, replace with new logging location
  if [[ $(echo "$line" | grep -c "/var/log/auth.log") -eq 1 ]]
  then
    line="$(echo "$line" | colrm 16)$(echo -e "\t\t\t$2")"  
  fi

  echo "$line" >> ~/temp.txt
done < ~/rsyslog-copy.txt


sudo cp ~/temp.txt "$rsyslog_path"
sudo lxc-attach -n "$1" -- sudo systemctl restart rsyslog
sudo lxc-attach -n "$1" -- bash -c

rm ~/temp.txt
rm ~/rsyslog-copy.txt
