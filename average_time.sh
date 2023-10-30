#!/bin/bash
if [[ $# -ne 1 ]]
then
  echo "Enter full path to data file that contains values to average on each line"
fi
sum=0
count=0
while read -r line
do
  sum=$(echo "$sum + $line" | bc)
  count=$(( count + 1 ))
done < "$1"
avg=$(echo "$sum / $count" | bc)
echo "$avg"
