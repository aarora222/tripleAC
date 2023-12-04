#!/bin/bash

# Will be put in crontab so it always runs and picks free IP addresses and creates random container
# with the random external IP

# generate random number between 1 and the number of current free IPs to pick a IP address
current_lines=$(wc -l < /home/student/free_ip_file.txt)

# exits with exit code 1 if no free IPs
if [[ $current_lines -lt 1 ]]
then
  exit 1
fi

random_number=$(shuf -i 1-"$current_lines" -n 1)

# moving the line corresponding to the random number to not_free_ip_file
sed -n "${random_number},${random_number}p" /home/student/free_ip_file.txt >> /home/student/not_free_ip_file.txt

# var of name and IP to pass in to create container
line=$(sed -n "$random_number"p /home/student/free_ip_file.txt | grep "1")
namevar=$(echo "$line" | cut -d ' ' -f1)
ipvar=$(echo "$line" | cut -d ' ' -f2)

# deleting line from free_ip_file
sed -i "${random_number}d" /home/student/free_ip_file.txt

# runs create container script with name and IP as variables
/home/student/create_container.sh "$namevar" "$ipvar"
