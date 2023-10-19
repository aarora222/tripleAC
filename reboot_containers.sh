#!/bin/bash

# this script runs on reboot

# destroys all the containers upon reboot
sudo lxc-destroy A
sudo lxc-destroy B
sudo lxc-destroy C
sudo lxc-destroy D
sudo lxc-destroy E
sudo lxc-destroy F
sudo lxc-destroy G
sudo lxc-destroy H

# resets all the IPs in not free and free
echo -e "D 128.8.238.182
G 128.8.238.141
C 128.8.238.52
F 128.8.238.82
H 128.8.238.215
B 128.8.238.33
E 128.8.238.10
A 128.8.238.15" > /home/student/free_ip_file.txt
rm /home/student/not_free_ip_file.txt
touch /home/student/not_free_ip_file.txt

# clear crontab and add moveIP back in
sudo crontab -r
touch /home/student/file
echo "@reboot sudo /home/student/firewall_rules.sh" >> /home/student/file
echo "@reboot /home/student/reboot_containers.sh" >> /home/student/file
echo "*/3 * * * * /home/student/moveIP.sh > /home/student/cronjob.log 2>&1"  >> /home/student/file
sudo crontab /home/student/file
rm /home/student/file
