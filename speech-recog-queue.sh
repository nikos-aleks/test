#!/bin/sh -x

cmd_sox="/usr/bin/sox"

path_script="/var/lib/asterisk/agi-bin/calls"
. $path_script/calls.main.conf.local

#date_now_full=$(date "+%Y-%m-%d.%H%M%S")
date_now_date=$(date "+%Y%m%d")
path_sounds="/var/spool/asterisk/recog/queue"
path_www="/var/www/html/queue"
file_record="$2"
file_ogg="$file_record.ogg"
file_wav="$file_record.wav"
file_mp3="$file_record.mp3"
file_text="$file_record.text"
#file_log="$file_record.log"
file_log="/tmp/log/recog-$date_now_date"

if [ -s ${file_record}.sln ]; then
	# silence 1 0.1 0.5% -1 0.1 0.5% pad 0 0.1
	$cmd_sox -b 16 -r 8000 -t raw -e signed-integer ${file_record}.sln $file_wav silence 1 0.1 0.1% -1 0.2 0.1% silence -l 1 0.1 0.2% -1 0.5 0.2% pad 0 0.1
	#$cmd_sox -b 16 -r 8000 -t raw -e signed-integer ${file_record}.sln $file_wav
	file_wav_size=$(stat -c %s $file_wav)
	if [ $file_wav_size -ge 2048 ]; then
		ln -s $file_wav "$path_www/$1.$$.wav"
		url_wav="https://$asterisk_domain/queue/$1.$$.wav"
		echo "SET VARIABLE recog_wav $url_wav"
	else
		echo "SET VARIABLE recog_wav -1"
	fi
	
	#$cmd_sox -b 16 -r 8000 -t raw -e signed-integer ${file_record}.sln $file_mp3 silence 1 0.1 0.2% -1 0.2 0.2% silence -l 1 0.1 0.5% -1 0.5 0.5% pad 0 0.1
	#file_mp3_size=$(stat -c %s $file_mp3)
	#if [ $file_mp3_size -ge 600 ]; then
	#	ln -s $file_mp3 "$path_www/$1.$$.mp3"
	#	url="https://$asterisk_domain/queue/$1.$$.mp3"
	#	echo "SET VARIABLE recog_mp3 $url"
	#else
	#	echo "SET VARIABLE recog_mp3 -1"
	#fi
	echo "SET VARIABLE recog_mp3 -1"
else
	echo "SET VARIABLE recog_wav -3"
	echo "SET VARIABLE recog_mp3 -3"
fi

echo "ID: $1, Number: $3, Record: $url_wav, Size-wav: $file_wav_size, Size-mp3: $file_mp3_size" >> $file_log
