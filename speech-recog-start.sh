#!/bin/sh -x

checkresults()
{
	while read row; do
		case ${row:0:4} in
			"200 ")		return			;;
			"510 ")		return			;;
			"520 ")		return			;;
			*)		echo [${row:0:4}]	;;
		esac
	done
}

cmd_sox="/usr/bin/sox"
date_now_full=$(date "+%Y-%m-%d.%H%M%S")
path_sounds="/var/spool/asterisk/recog/$1"
file_record="$path_sounds/$date_now_full.$$"
format="sln"
intkey="#"
[ -z "$2" ] && timeout_absolute=5000 || timeout_absolute=$(($2*1000))
[ -z "$3" ] && timeout_silence=2 || timeout_silence=$3

echo "SET VARIABLE file_record $file_record"
echo "RECORD FILE $file_record $format $intkey $timeout_absolute s=$timeout_silence"
checkresults
