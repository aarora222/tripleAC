#!/bin/bash

if [[ $# -ne 2 ]]
then
  echo "usage: data_parser.sh [directory of mitm] [type of container (1-8 random number)]"
  exit 1
fi

data_file=~/data$2.txt

# checking 24 hours maximum time to spend in container
#start_time=$(grep "Attacker connected" "$1"/mitm.log | colrm 25 | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}')
start_time=$(grep "Attacker connected" "$1"/mitm.log | tail -1 | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}')
#end_time=$(grep "Attacker closed connection" "$1"/mitm.log | colrm 25)
end_time=$(grep "Attacker closed connection" "$1"/mitm.log | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}')
timestamp1=$(date -d "$start_time" +%s)
timestamp2=$(date -d "$end_time" +%s)
time_difference=$(("$timestamp2"-"$timestamp1"))

#accumulates data points in secods
echo "$time_difference" >> "$data_file"



# creates log with all attacker connections, to be added into command logs
cat "$1"/mitm.log | grep "\[Connection\]" | colrm 26 46 > "$1"/connections.log

# creates temporary log with all commands and their timestamps from mitm log
cat "$1"/mitm.log | grep "line from reader" | colrm 24 58 > "$1"/all_commands.tmp

# creates temporary log with only important commands and their timestamps
important_commands="ls\|cd\|rm\|cp\|mv\|cat\|find\|grep\|less\|more\|log\|/var\|/etc\|~\|~/m/c\|m/c/\|auth.log\|asdfgh123!@#\|rsyslog.d\|50-default.conf\|$(cat "$data_file" | head -1)"

cat "$1"/all_commands.tmp | grep "$important_commands" > "$1"/important_commands.tmp

# creates main_data.log as list of timestamps with commands present only if they're in the list of important commands
# attacker connections also included
cat "$1"/all_commands.tmp "$1"/important_commands.tmp | sort | uniq -u | colrm 24 > "$1"/unimportant_command_times.tmp

cat "$1"/connections.log "$1"/unimportant_command_times.tmp "$1"/important_commands.tmp | sort > "$1"/main_data.log

# adds connections into all_commands and important_commands
cat "$1"/connections.log "$1"/all_commands.tmp | sort > "$1"/all_commands.log
cat "$1"/connections.log "$1"/important_commands.tmp | sort > "$1"/important_commands.log

# zips the log files to save room
gzip "$1"/mitm.log
gzip "$1"/connections.log
gzip "$1"/all_commands.log
gzip "$1"/important_commands.log
gzip "$1"/main_data.log
# removes the temporary log files
rm "$1"/all_commands.tmp
rm "$1"/important_commands.tmp
rm "$1"/unimportant_command_times.tmp
exit 0
