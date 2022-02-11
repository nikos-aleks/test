#!/bin/sh -x

cmd_sox="/usr/bin/sox"
cmd_cmp="/usr/bin/cmp"
beep_sln="/var/lib/asterisk/agi-bin/calls/sounds/beep.sln"
date_now_full=$(date "+%Y-%m-%d %H:%M:%S")
date_now_date=$(date "+%Y%m%d")
log_beep="/tmp/log/beep-$date_now_date"

if [ -s $1 ]; then
	$cmd_sox -b 16 -r 8000 -t raw -e signed-integer $1 "$1-short.sln" silence 1 0.1 1% -1 0.1 1% reverse silence 1 0.1 1% -1 0.1 1% reverse
	size=$(stat -c %s "$1-short.sln")
	[ $size -ge 8200 -a $size -le 8400 ] && matched="yes"
	if [ $size -ge 2828 -a $size -le 2876 ]; then
		bytes=$($cmd_cmp $beep_sln "$1-short.sln" | awk -F '[ ,]' '{print $5}')
		[ $bytes -le 256 ] && matched="yes"
	fi
	if [ -n "$matched" ]; then
		echo "SET VARIABLE AMDSTATUS MACHINE"
		echo "SET VARIABLE AMDCAUSE BEEP"
	fi
	calls_id=${1##*/}
	calls_id=${calls_id%.*}
	echo "[$date_now_full] ID: $calls_id, Number: $2, Size: $size, Match: $matched." >> $log_beep
	rm -f "$1-short.sln"
	#rm -f /tmp/sounds/*.sln
fi

rm -f $1
