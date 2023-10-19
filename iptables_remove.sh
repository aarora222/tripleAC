#!/bin/bash

if [[ $# -ne 1 ]]
then
  echo "Enter external IP"

  ip=$(sudo lxc-info -n "$1" -iH)
  port_num=$(( 'head -1 < port.txt' - 1))

  sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$1" --jump DNAT --to-destination "$ip"
  sudo iptables --table nat --delete POSTROUTING --source "$ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$1"
  sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$1" --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:"$port_num"
