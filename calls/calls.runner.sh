#!/bin/sh

# path
cmd_realpath="readlink -e"
cmd_sh="/bin/sh"
cmd_nice="/usr/bin/nice -n 10"
path_script=$($cmd_realpath $0)
path_script=$(dirname $path_script)
script_main="calls.main.sh"
script_runner="calls.runner.sh"
count_run=0
count_skip=0
date_ts_start=$(date "+%s")

# calls.main.conf
. $path_script/calls.main.conf.local
. $path_script/calls.main.conf

echo $$ > /var/run/calls.runner.pid

#rm -f $lock_audio
sleep 1

while [ true ]; do
. $path_script/calls.main.conf.local
	if [ -r $path_script/$runner_pause_file ]; then
		sleep 8
		continue
	fi
	if [ -r $lock_audio ]; then
		if [ -n "$(find $lock_audio -type f -mmin +$lock_audio_min)" ]; then
			cat $lock_audio >> $lock_audio_log
			rm -f $lock_audio
		fi
		sleep 8
		continue
	fi
	script_running_now=$(pgrep -cf $script_main)
	steal_now=$(cat /proc/stat | head -n 1 | awk '{print $9}')
	steal_diff=$((steal_now-steal_last))
	[ $steal_diff -gt $steal_max ] && steal_diff=$steal_max
	steal_last=$steal_now
	sleep_now=`cat /proc/loadavg | awk -F '[ /]' -v sd="$steal_diff" -v div="$sleep_div" '{print sqrt($1*2+$2+$3/2+$4/2+sd/2)/div}'`
	[ ${sleep_now%.*} -eq ${sleep_min%.*} ] && [ ${sleep_now#*.} \> ${sleep_min#*.} ] || [ ${sleep_now%.*} -gt ${sleep_min%.*} ]
	[ $? -eq 0 ] && sleep_time=$sleep_now || sleep_time=$sleep_min
	proc_running_now=$(cat /proc/loadavg | awk -F '[ /]' '{print $4}')
	date_ts_diff=$(echo $(date "+%s") - $date_ts_start | bc)
	rate_run=$(echo "scale=2; $count_run / $date_ts_diff" | bc)
	echo -n "$sleep_time ($sleep_now/$steal_diff/$script_running_now/$proc_running_now) $rate_run"
	sleep $sleep_time
	if [ $script_running_now -le $script_running_max -a $proc_running_now -le $proc_running_max -a $steal_diff -lt $steal_max ]; then
		[ -z $1 ] && $cmd_nice $cmd_sh $path_script/$script_main call_ready_few &
		count_run=$((count_run+1))
	else
		count_skip=$((count_skip+1))
		percent_skip=$(echo $count_skip \* 100 / \( $count_run + $count_skip \) | bc )
		echo -n " skip ${percent_skip}%"
	fi
	echo
done
