#!/bin/bash

#Check if argument of config file is correct

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <container_namee>"
  exit 1
fi

#Assigning file argument to var
cont_name="$1"
sshd_config_path="/etc/ssh/sshd_config"

#If the container exists
if sudo lxc-ls | grep -q "$cont_name"; then

  #Use sed to replace line w desired config
  sudo lxc-attach -n "$cont_name" -- sed -i 's/.*PermitRootLogin.*/PermitRootLogin no/' "$sshd_config_path"

  #Restarting SSH service
  sudo lxc-attach -n "$cont_name" -- systemctl restart ssh

fi

