#!/bin/bash

# Will be put in crontab so it always runs and picks free IP addresses and creates random container
# with the random external IP

#Generate random number between 1 and 8 to pick a ip address
random_number=$((1 + RANDOM % 8))

#Moving the line corresponding to the random number to not_free_ip_file
sed -n "$random_number"p free_ip_file.txt >> not_free_ip_file.txt

# var of name and IP to pass in to create container
line=$(sed -n "$random_number"p free_ip_file.txt | grep "1")
ipvar=$(echo $line | cut -d ' ' -f1)
namevar=$(echo $line | cut -d ' ' -f2)

#deleting line from free_ip_file
sed -i "${random_number}d" free_ip_file.txt

# runs create container script with name and IP as variables
./create_container.sh ${namevar} ${ipvar}
