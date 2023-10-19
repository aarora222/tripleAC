#!/bin/bash
# Script checks for 30 mins idle time or maximum 24 hours spent in container before deleting
# container

if [[ "$#" -ne 4 ]]
then
  echo "usage: check_destroy.sh [name of container] [absolute path for directory of mitm logs] [external IP] [type of container (1-8)]"
    exit 1
fi

container_destroyed=0 #Check to ensure container is not attempted to be destroyed twice

# checks idle time, maximum is 30 mins
#start_time=$(grep "Attacker authenticated and is inside container" "$2"/mitm.log | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}')
#echo "Start time: $start_time"
#last_action_time=$(grep "Attacker Keystroke" "$2"/mitm.log | tail -1 | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}')
# checking 24 hours maximum time to spend in container
#cur_time=$(date '+%Y-%m-%d %T.%N')
#timestamp1=$(date -d "$start_time" +%s)
#timestamp2=$(date -d "$cur_time" +%s)
#last_action_stamp=$(date -d "$last_action_time" +%s)
#time_difference=$(("$timestamp2"-"$timestamp1"))
#days_difference=$(("$time_difference"/86400))
#thirty_mins=$(("$last_action_stamp"-"$timestamp1"))
#thirty_mins=$(("$thirty_mins" / 60))

#if [[ $days_difference -ge 1 ]] || [[ $thirty_mins -ge 30 ]] #If 1 day (24 hours) or 30 minutes has passed, container is deleted
#then
#  container_destroyed=1 #Flagging that container should be destroyed
#fi
#checks for attacker logging out, flags container to be destroyed
if [[ $(grep -c "Attacker closed connection" "$2"/mitm.log) -ge 1 ]]
then
  echo "Greped"
  container_destroyed=1
fi

if [[ $container_destroyed -eq 1 ]] #destroying container
then

  echo "destroyed"
  # Later on, we will execute scripts here to zip up log files and export them to our home directory outside of the container. The data_parser.sh script will do that after we edit it, but right now it does not work
  /home/student/data_parser.sh "$2" "$4"

  # We will add code to add the external IP of this container back into play so another randomly
  # created container can use it

  # move ip from not free ip to free ip so it can be used for next container
  sed -n "/$1 $3/p" /home/student/not_free_ip_file.txt >> /home/student/free_ip_file.txt
  # delete line from not free ip
  echo "moving things"
  sed -i "/$1 $3/d" /home/student/not_free_ip_file.txt

  sudo lxc-stop -n "$1"
  sudo lxc-destroy -n "$1"

  sudo crontab -l > /home/student/crontemp.txt

# removes this container's cronjob from the crontab
  while read -r line
  do
    if [[ $(echo "$line" | grep -c "$1") -eq 0 ]]
    then
      echo "$line" >> /home/student/temp.txt
    fi
  done < /home/student/crontemp.txt

  sudo crontab /home/student/temp.txt
  rm /home/student/temp.txt
  rm /home/student/crontemp.txt


fi
