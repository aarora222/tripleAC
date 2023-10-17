#!/bin/bash

# hour or more means idle time has been expired
if echo $1 | grep -q "hour"
then
  exit 1
fi 

# if idle time is in minutes, compared to 30 to see if it has exceeded idle time
if echo "$1" | grep -q "minutes"
then 
  minutes=$(echo "$1" | awk '{print $1}')
  if [ $minutes -ge 30 ]
  then 
    exit 1
  else 
    exit 0
  fi

# if in seconds, time has not expired
else
  exit 0 
fi
  
