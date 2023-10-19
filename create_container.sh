#!/bin/bash

# checks for correct number of arguments
if [[ "$#" -ne 2 ]]
then
  echo "usage: script.sh [name of container] [IP address]"
  exit 1
fi

# tries to find container name in list of containers that currently exist
# will be empty string if container doesn't exist
does_exist=$(sudo lxc-ls | grep "$1")
if [[ -z  $does_exist ]]
then
  # create a container
  sudo lxc-create -n "$1" -t download -- -d ubuntu -r focal -a amd64
  sudo lxc-start -n "$1"

  sleep 5
  # installs ssh
  sudo lxc-attach -n "$1" -- bash -c "apt-get update && apt-get install -y openssh-server"
  # installs snoopy
  # took all these commands from the lecture slides (Week 10 - Keyloggers, slide 7)
  sudo lxc-attach -n "$1" -- bash -c "sudo apt-get install wget -y && wget -O install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh && chmod 755 install-snoopy.sh && sudo ./install-snoopy.sh stable && sudo rm -rf ./install-snoopy.* snoopy-*"

  # installs telnet, finger, and apache
  sudo lxc-attach -n "$1" -- apt-get install finger
  sudo lxc-attach -n "$1" -- apt-get install telnet
  sudo lxc-attach -n "$1" -- apt-get install -y apache2

  # randomizes container type and stores in variable
  container_type=$(echo -e "1\n2\n3\n4\n5\n6\n7\n8" | shuf | head -1)

  # gets container's internal IP
  ip=$(sudo lxc-info -n "$1" -iH)
  # makes new directory for the log file, named by time started and container name
  # each container gets a subdirectory in its type subdirectory of router_logs
  time=$(date +"%Y_%m_%d_%H:%M:%S")
  dir="ipcamera_logs/$container_type/${time}_$1"
  mkdir -p ~/"$dir"

  # gets the first line of file as a number (starts at 50000, goes up), uses it as port number
  port_num=$(head -1 < port.txt)

  # starts MITM server and sets up NAT rules
  sudo sysctl -w net.ipv4.conf.all.route_localnet=1
  sudo ip addr add "$2/24" brd + dev eth1
  sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$2" --jump DNAT --to-destination "$ip"
  sudo iptables --table nat --insert POSTROUTING --source "$ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$2"
  sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$2" --protocol tcp --dport 22 --jump DNAT --to-destination 10.0.3.1:"$port_num"
  sudo iptables --table nat --insert POSTROUTING --source "$2" --destination 0.0.0.0/0 --jump SNAT --protocol tcp --to-source "$ip:$port_num"
  sudo forever -l /home/student/"$dir"/mitm.log start -a /home/student/MITM/mitm.js -n "$1" -i "$ip" -p "$port_num" --auto-access --auto-access-fixed 3 --debug


  #increments port number by 1 every time
  echo $((port_num + 1)) > /home/student/port.txt

  # creates nested [a-z] [a-z] directories in container using alphabet string
  alphabet="abcdefghijklmnopqrstuvwxyz"
  # first set of [a-z] directories
  for i in {0..25}
  do
    char=${alphabet:i:1}
    sudo lxc-attach -n "$1" -- mkdir "/home/ubuntu/$char"
    # nest [a-z] in current directory
    for j in {0..25}
    do
      subdir=${alphabet:j:1}
      sudo lxc-attach -n "$1" -- mkdir "/home/ubuntu/$char/$subdir"
    done
  done

  # renames default log file in containers according to type
  log_name="/var/log/auth.log"
  if [[ "$container_type" -ne 1 ]]
  then

    # default location, rename
    if [[ "$container_type" -eq 2 ]]
    then
        log_name=/var/log/asdfgh123!@

    # easy location, default name
    elif [[ "$container_type" -eq 3 ]]
    then
        log_name=/home/ubuntu/auth.log

    # easy location, rename
    elif [[ "$container_type" -eq 4 ]]
    then
        log_name=/home/ubuntu/asdfgh123!@

    # medium location, default name
    elif [[ "$container_type" -eq 5 ]]
    then
        log_name=/etc/auth.log

    # medium location, rename
    elif [[ "$container_type" -eq 6 ]]
    then
        log_name=/etc/asdfgh123!@

    # hard location, default name
    elif [[ "$container_type" -eq 7 ]]
    then
        log_name=/home/ubuntu/m/c/auth.log

    # hard location, rename
    elif [[ "$container_type" -eq 8 ]]
    then
        log_name=/home/ubuntu/m/c/asdfgh123!@


    sudo lxc-attach -n "$1" -- touch $log_name

    fi
  fi


/home/student/change_log.sh "$1" "$log_name"

# creates cronjob to continually check idle and max time
crontab -l > file; echo "* * * * * /home/student/check_destroy $1 $dir $2 $container_type"  >> file; crontab file; rm file

#need to pass in what we want password to be
sudo lxc-attach -n "$1" -- bash -c "echo -e 'hacs200isthebestclassever.\nhacs200isthebestclassever.' | passwd"

exit 0
fi
