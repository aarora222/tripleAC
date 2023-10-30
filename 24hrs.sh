#!/bin/bash

if [[ $# -ne 1 ]]
then
  echo "Enter file containing full filepaths to mitm.log directories but don't include mitm.log in path (/home/student..._A)"
fi
while read -r line
do
  data_file=24$(echo "$line" | cut -d'/' -f5).txt
  mitm_log="$line"/mitm.log
  mitm_zipped="$line"/mitm.log.gz
  if [[ -a "$mitm_zipped" ]]
  then
    sudo gunzip "$mitm_zipped"
  fi
start_time=$(grep "Attacker authenticated and is inside container" "$mitm_log" | head -1 | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}')
end_time=$(grep "Attacker closed connection" "$mitm_log" | head -1 | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}')
if [[ -z "$end_time" ]]
then
  end_time=$(grep "Attacker closed the connection" "$mitm_log" | head -1 | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}')
fi
if [[ -n "$start_time" && -n "$end_time" ]]
then
  timestamp1=$(date -d "$start_time" +%s.%3N)
  timestamp2=$(date -d "$end_time" +%s.%3N)
  time_difference=$( echo "$timestamp2 - $timestamp1" | bc )
  #accumulates data points in seconds up to the millisecond
  echo "$time_difference" >> "$data_file"
fi
done < "$1"
