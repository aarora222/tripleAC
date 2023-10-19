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
finger_output=$(sudo lxc-attach -n "$1" -- bash -c "finger admin")
time_idle=$(echo "$finger_output" | grep -oP '(\d+ days?)? (\d+ hours?)? (\d+ minutes?)? (\d+ seconds?)? idle' | awk '{$1=$1};1') #Accessing the idle time
./finger_time_check.sh "$time_idle" #running script to check if 30 minutes has passed
container_destroyed=$? #Exit code 1 means the container should be deleted, 0 means it should be left alone


# checking 24 hours maximum time to spend in container
start_time=$(grep "Attacker connected" ~/"$2"/mitm.log | colrm 25)
cur_time=$(date '+%Y-%m-%d %T.%N')
timestamp1=$(date -d "$start_time" +%s)
timestamp2=$(date -d "$cur_time" +%s)
time_difference=$((timestamp2 - timestamp1))
days_difference=$((time_difference / 86400))

if [ $days_difference -ge 1 ] && [ $container_destroyed -eq 0 ] #If 1 day (24 hours) has passed, container is deleted
then
  container_destroyed=1 #Flagging that container should be destroyed
fi
#checks for attacker logging out, flags container to be destroyed
if [[ $(grep -c "Attacker closed connection") -eq 1 ]]
then
  container_destroyed=1
fi

if
  [ $container_destroyed -eq 1 ] #destroying container
then
  # Later on, we will execute scripts here to zip up log files and export them to our home directory outside of the container. The data_parser.sh script will do that after we edit it, but right now it does not work
  data_parser.sh "$2" "$4"

  # We will add code to add the external IP of this container back into play so another randomly
  # created container can use it
  #
  # move ip from not free ip to free ip so it can be used for next container
  exchanged_periods=$(echo "$3" | sed 's/\./\\./g')
  sed -i "$exchanged_periods"p /home/student/not_free_ip_file.txt >> /home/student/free_ip_file.txt
  # delete line from not free ip
  sed -i "$exchanged_periods"d /home/student/not_free_ip_file.txt

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
