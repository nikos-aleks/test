#!/bin/sh

mysql_exec()
{
	if [ -z "${db_ca}" ]; then
		mysql -h ${db_host} -D ${db_name} -u ${db_user} -p${db_pass} -Bse "$@"
	else
		mysql -h ${db_host} -D ${db_name} -u ${db_user} -p${db_pass} --ssl-ca=${db_ca} -Bse "$@"
	fi
}

# calls_get_ready_one return_string
calls_get_ready_one()
{
	[ -z "$1" ] && return 1
	mysql_cmd="SELECT id, $table_column_number FROM $db_table_calls_queue WHERE $table_column_status=\"READY\" and $table_column_calling is NULL LIMIT 1"
	mysql_return=$(mysql_exec "$mysql_cmd")
	[ -n "$mysql_return" ] && eval "$1=($mysql_return)" || return 1
}

# calls_get_ready_few return_string
calls_get_ready_few()
{
	[ -z "$1" ] && return 1
	mysql_cmd="SELECT id FROM $db_table_calls_queue WHERE $table_column_status=\"READY\" LIMIT $2"
	mysql_return=$(mysql_exec "$mysql_cmd")
	[ -n "$mysql_return" ] && eval "$1=\"$mysql_return\"" || return 1
}

# calls_get_number_by_id return_string $id
calls_get_number_by_id()
{
	[ -z "$1" -o -z "$2" ] && return 1
	mysql_cmd="SELECT $table_column_number FROM $db_table_calls_queue WHERE id=$2 LIMIT 1"
	eval "$1=$(mysql_exec "$mysql_cmd")"

}

# calls_get_audio_by_url return_file $url
calls_get_audio_by_url()
{
	sleep 1
}

# calls_get_audio_by_id return_string $url_audio
calls_audio_url_to_file()
{
	[ -z "$1" ] && return 1
	url_audio=$2
	if [ -z "${url_audio%0}" ]; then
		eval "$1='silence/1'"
		return 2
	fi
	if [ -z "${url_audio%beep}" ]; then
		eval "$1='beep'"
		return 2
	fi
	while [ -r "$lock_audio" ]; do sleep 1; done
	hash_audio=($(echo $url_audio | $cmd_hash))
	file_audio="$path_audio/$hash_audio"
	file_audio_wav="$file_audio.wav"
	file_audio_mp3="$file_audio.mp3"
	file_audio_alaw="$file_audio.alaw"
	if [ -s $file_audio_alaw ]; then
		eval "$1=$file_audio"
		return 0
	fi
	echo "[$date_now_full] Function: [calls_audio_url_to_file], Proccess: $$, URL: $url_audio, Hash: $hash_audio" > $lock_audio
	sleep 0.1
	[ ! -s $file_audio ] && $wget_cmd $wget_opt $url_audio -O $file_audio

	[ -z "${url_audio%%*.ogg}" ] && $cmd_convert_ogg $file_audio $cmd_convert_ogg_opt - | $cmd_convert_sox - $cmd_convert_alaw_opt $file_audio_alaw

	if [ -z "${url_audio%%*.mp3}" ]; then
		cp $file_audio $file_audio_mp3
		$cmd_convert_sox $file_audio_mp3 $cmd_convert_alaw_opt $file_audio_alaw
		rm -f $file_audio_mp3
	fi
	[ ! -s $file_audio_alaw ] && $cmd_convert_sox $file_audio $cmd_convert_alaw_opt $file_audio_alaw
	#rm -f $file_audio
	#duration_audio=$(soxi -d $file_audio 2> /dev/null)
	#duration_audio_alaw=$(soxi -d $file_audio_alaw 2> /dev/null)
	rm -f $lock_audio

	if [ -s $file_audio_alaw ]; then
		eval "$1=$file_audio"
	else
		eval "$1='silence/1'"
		return 3
	fi
}

# calls_get_audio_by_id return_string $id $column
calls_get_audio_by_id()
{
	[ -z "$1" -o -z "$2" -o -z "$3" ] && return 1
	eval table_column_audio=\$table_column_audio_$3
	mysql_cmd="SELECT $table_column_audio FROM $db_table_calls_queue WHERE id=$2 LIMIT 1"
	url_audio=$(mysql_exec "$mysql_cmd")
	if [ -z "$url_audio" ]; then
		eval "$1='silence/1'"
		return 2
	fi
	while [ -r "$lock_audio" ]; do sleep 1; done
	hash_audio=($(echo $url_audio | $cmd_hash))
	file_audio="$path_audio/$hash_audio"
	file_audio_wav="$file_audio.wav"
	file_audio_mp3="$file_audio.mp3"
	file_audio_alaw="$file_audio.alaw"
	if [ -s $file_audio_alaw ]; then
		eval "$1=$file_audio"
		return 0
	fi
	echo "[$date_now_full] Function: [calls_get_audio_by_id], Proccess: $$, URL: $url_audio, Hash: $hash_audio" > $lock_audio

	[ ! -s $file_audio ] && $wget_cmd $wget_opt $url_audio -O $file_audio
	sleep 0.1

	[ -z "${url_audio%%*.ogg}" ] && $cmd_convert_ogg $file_audio $cmd_convert_ogg_opt - | $cmd_convert_sox - $cmd_convert_alaw_opt $file_audio_alaw

	if [ -z "${url_audio%%*.mp3}" ]; then
		cp $file_audio $file_audio_mp3
		$cmd_convert_sox $file_audio_mp3 $cmd_convert_alaw_opt $file_audio_alaw
		rm -f $file_audio_mp3
	fi
	[ ! -s $file_audio_alaw ] && $cmd_convert_sox $file_audio $cmd_convert_alaw_opt $file_audio_alaw
	#rm -f $file_audio
	#duration_audio=$(soxi -d $file_audio 2> /dev/null)
	#duration_audio_alaw=$(soxi -d $file_audio_alaw 2> /dev/null)
	rm -f $lock_audio

	if [ -s $file_audio_alaw ]; then
		eval "$1=$file_audio"
	else
		eval "$1='silence/1'"
		return 3
	fi
}

calls_get_audio_by_http()
{
	variable_audio=$2
	url_audio=$3

	if [ -z "$variable_audio" -o -z "$url_audio" ]; then
		echo "SET VARIABLE $variable_audio beep"
		return 1
	fi

	hash_audio=($(echo $url_audio | $cmd_hash))
	file_audio="$path_audio/$hash_audio"
	file_audio_download="$file_audio.download"
	file_audio_wav="$file_audio.wav"
	file_audio_alaw="$file_audio.alaw"
	file_audio_mp3="$file_audio.mp3"
	if [ -s $file_audio_alaw ]; then
		echo "SET VARIABLE $variable_audio $file_audio"
		return 0
	fi


	echo "[$date_now_full] Function: [calls_get_audio_by_http], Proccess: $$, URL: $url_audio, Hash: $hash_audio" > $lock_audio


	if [ ! -s $file_audio_download ]; then
		echo "Downloading ..." >> $lock_audio
		$wget_cmd $wget_opt $url_audio -O $file_audio_download >> $lock_audio
	fi

	if [ -z "${url_audio%%*.wav}" -o -z "${url_audio%%*.mp3}" ]; then
		echo "Converting ..." >> $lock_audio
		$cmd_convert_sox $file_audio_download $cmd_convert_alaw_opt $file_audio_alaw >> $lock_audio
		rm -f $file_audio_download
		rm -f $lock_audio
	else
		echo "SET VARIABLE $variable_audio beep"
		rm -f $lock_audio
		return 2
	fi

	if [ -s $file_audio_alaw ]; then
		echo "SET VARIABLE $variable_audio $file_audio"
		return 0
	else
		echo "SET VARIABLE $variable_audio beep"
		return 3
	fi
}

# calls_set_status_by_id return_string $id $status $bill_sec $duration
calls_set_status_by_id()
{
	#[ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" ] && return 1
	#case $3 in
	#	FAILED|CONGESTION|CANCEL|NOANSWER|CANCEL|BUSY|ANSWER)			;;
	#	*)								return 2;;
	#esac
	mysql_cmd="UPDATE $db_table_calls_queue set $table_column_status=\"$3\", $table_column_bill=\"$4\", $table_column_duration=\"$5\", changed=NOW() WHERE id=$2"
	$(mysql_exec "$mysql_cmd")
	return 0
}

# calls_set_status_by_id return_string $id $dtmf
calls_set_dtmf_by_id()
{
	#[ -z "$1" -o -z "$2" -o -z "$3" ] && return 1
	[ -z "$6" ] && dtmf=-3 || dtmf=$6
	mysql_cmd="UPDATE $db_table_calls_queue set $table_column_amd_status=\"$4\", $table_column_amd_cause=\"$5\", $table_column_dtmf=\"$dtmf\" WHERE id=$2"
	#echo VERBOSE \"$mysql_cmd\"
	$(mysql_exec "$mysql_cmd")
	echo "[$date_now_full] Number: $3, DTMF: $dtmf, ID: $2" >> $log_dtmf
	#mysql_cmd="UPDATE $db_table_calls_queue set $table_column_status='DTMF' WHERE id=$2"
	#$(mysql_exec "$mysql_cmd")
	#mysql_cmd="UPDATE $db_table_calls_queue set changed=NOW() WHERE id=$2"
	#$(mysql_exec "$mysql_cmd")
	return 0
}

calls_set_recog_by_id()
{
	#[ -z "$1" -o -z "$2" -o -z "$3" -o z "$4" ] && return 1
	callid=$2
	number=$3
	amd_status=$4
	amd_cause=$5
	confidence=$6
	shift; shift; shift; shift; shift; shift
	utterance=$*
	mysql_cmd="UPDATE $db_table_calls_queue set $table_column_amd_status=\"$amd_status\", $table_column_amd_cause=\"$amd_cause\", $table_column_utterance=\"$utterance\", $table_column_confidence=\"$confidence\" WHERE id=$callid"
	$(mysql_exec "$mysql_cmd")
	echo "[$date_now_full] CallID: $callid, Number: $number, Confidence: $confidence, Utterance: $utterance" >> $log_recog
	return 0
}

calls_set_recog_queue_by_id()
{
	#[ -z "$1" -o -z "$2" -o -z "$3" -o z "$4" ] && return 1
	[ -z "$6" ] && recog_wav="-3" || recog_wav=$6
	[ -z "$7" ] && recog_mp3="-3" || recog_mp3=$7
	mysql_cmd="UPDATE $db_table_calls_queue set amd_status=\"$4\", amd_cause=\"$5\", recog_wav=\"$recog_wav\", recog_mp3=\"$recog_mp3\" WHERE id=$2"
	$(mysql_exec "$mysql_cmd")
	echo "[$date_now_full] CallID: $2, Number: $3, recog_wav: $6" >> $log_recog
	return 0
}

calls_set_recog_audiofork_by_id()
{
	mysql_cmd="UPDATE $db_table_calls_queue set amd_status=\"$4\", amd_cause=\"$5\", sec_recognize=\"$6\", final_answer=\"$7\", shorthand=\"$8\" WHERE id=$2"
	$(mysql_exec "$mysql_cmd")
	echo "[$date_now_full] CallID: $2, Number: $3, recog_wav: $6" >> $log_recog
	return 0
}

# calls_set_record_by_id return_string $id $uniqueid $mixmonitor
calls_set_record_by_id()
{
	#[ -z "$1" -o -z "$2" -o -z "$3" ] && return 1
	#echo VERBOSE \"!!!!!!! ln -s $4 $www_path_records/$3.wav\"
	ln -s $4 "$www_path_records/$3.wav"
	record_url="$www_url_records/$3.wav"
	unset network; eval network=\$network_$5
	mysql_cmd="UPDATE $db_table_calls_queue set record=\"$record_url\", network_called=\"$network\", changed=NOW() WHERE id=$2"
	$(mysql_exec "$mysql_cmd")
	return 0
}

#calls_filter_recog()
#{
#	shift
#	utterance=$*
#	mysql_cmd="SELECT count(*) from $table_filter_recog WHERE idrecognition<>1 and word LIKE \"$utterance\""
#	filter_no=$(mysql_exec "$mysql_cmd")
#	[ $filter_no -eq 1 ]
#
#	utterance_pattern=$(echo $utterance | sed -r 's/ /\\\\b|\\\\b/g')
#	utterance_pattern="\\\\b$utterance_pattern\\\\b"
#	mysql_cmd="SELECT count(*) from $table_filter_recog WHERE idrecognition=1 and word REGEXP(\"$utterance_pattern\")"
#	filter_yes=$(mysql_exec "$mysql_cmd")
#	mysql_cmd="SELECT count(*) from $table_filter_recog WHERE idrecognition<>1 and word REGEXP(\"$utterance_pattern\")"
#}

# calls_set_status_by_id return_string $id
calls_set_calling_by_id()
{
	[ -z "$1" -o -z "$2" ] && return 1
	mysql_cmd="UPDATE $db_table_calls_queue set $table_column_status=\"CALLING\", changed=NOW() WHERE id=$2"
	$(mysql_exec "$mysql_cmd")
	#mysql_cmd="UPDATE $db_table_calls_queue set changed=NOW() WHERE id=$2"
	#$(mysql_exec "$mysql_cmd")
	return 0
}

# calls_originate_ivr return_string $id $number $audio
calls_originate_ivr()
{
	shift; for arg in $*; do
		case $arg in
			callid=*)		callid=${arg#callid=}				;;
			number=*)		number=${arg#number=}				;;
			network_prefere=*)	network_prefere=${arg#network_prefere=}		;;
			context=*)		context=${arg#context=}				;;
			scenario=*)		scenario=${arg#scenario=}			;;
			amd_method=*)		amd_method=${arg#amd_method=}			;;
			apikey=*)		apikey=${arg#apikey=}				;;
			ask=*)			audio_ask=${arg#ask=}				;;
			one=*)			audio_one=${arg#one=}				;;
			two=*)			audio_two=${arg#two=}				;;
			timeout_ring=*)		timeout_ring=$((${arg#timeout_ring=}*1000))	;;
			timeout_absolute=*)	timeout_absolute=${arg#timeout_absolute=}	;;
			timeout_silence=*)	timeout_silence=${arg#timeout_silence=}		;;
			*)			exit 1						;;
		esac
	done
	[ -z "${apikey##default}" ] && apikey=$apikey_default
	[ -z "$audio_ask" ] && audio_ask="beep"
	[ -z "$timeout_absolute" ] && timeout_absolute=4

	case $network_prefere in
		beeline)		network="11"		;;
		mtt)			network="21"		;;
		mts)			network="31"		;;
		tele2)			network="41"		;;
		megafon)		network="51"		;;
		*)			unset network		;;
	esac

	echo "open 127.0.0.1 5038"
	sleep 0.1
	echo "Action: Login"
	echo "Username: $ami_username"
	echo "Secret: $ami_password"
	echo
	sleep 0.1
	echo "Action: Originate"
	echo "Channel: Local/${network}${number}@calls-dial/n"
	echo "Context: $context"
	echo "Exten: s"
	echo "Priority: 1"
	echo "Callerid: "
	echo "Timeout: $timeout_ring"
	echo "Async: yes"
	echo "Account: $context"
	echo "Variable: calls_callid=$callid"
	echo "Variable: calls_number=${network}${number}"
	echo "Variable: calls_scenario=$scenario"
	echo "Variable: calls_amd_method=$amd_method"
	echo "Variable: calls_apikey=$apikey"
	echo "Variable: calls_audio_ask=$audio_ask"
	echo "Variable: calls_audio_one=$audio_one"
	echo "Variable: calls_audio_two=$audio_two"
	echo "Variable: calls_timeout_absolute=$timeout_absolute"
	echo "Variable: calls_timeout_silence=$timeout_silence"
	echo "Variable: calls_node_address=$node_address"
	echo "Variable: calls_node_port=$node_port"
	#echo "Variable: calls_caller=9651234567"
	echo
	sleep 0.2
}

calls_incoming_curl_dtmf()
{
	[ -z "$2" ] && dtmf=-3 || dtmf=$2
	curl --location --request POST "http://api.mrmarketing.su/partner-api/save" \
	--header "x-partnerid: 152" \
	--header "x-partnertoken: jIktBZpR1eunLtr3PlBTvJLC-Kf_tNuz" \
	--header "Content-Type: application/json" \
	--data-binary "{
		\"sub_id\": \"$dtmf\",
		\"phone\": \"$1\",
		\"optionValueList\": []
	}"
	echo "[$date_now_full] Method: dtmf, Number: $1, DTMF: $2, Return: $?" >> $log_incoming
}

calls_incoming_audiofork_curl()
{
	curl --silent --location --request POST "https://api.mrmarketing.su/crm/func/incoming-call?phone=$1&callid=$2"
}

calls_incoming_audiofork_init()
{
	case $2 in
		+7[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])		incoming_number=${2#+}		;;
		7[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])		incoming_number=${2}		;;
		[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])		incoming_number="7${2}"		;;
		*)								incoming_number="HANGUP"	;;
	esac
	incoming_callid="${asterisk_id}${RANDOM}"
	if [ ! "$incoming_number" = "HANGUP" ]; then
		incoming_audiofork_curl_result=$(calls_incoming_audiofork_curl $incoming_number $incoming_callid)
		incoming_audiofork_curl_scenario=$(echo $incoming_audiofork_curl_result | jq -r '."scenario"')
		incoming_audiofork_curl_partnerid=$(echo $incoming_audiofork_curl_result | jq -r '."x-partnerid"')
		incoming_audiofork_curl_partnertoken=$(echo $incoming_audiofork_curl_result | jq -r '."x-partnertoken"')
	fi
	echo "SET VARIABLE calls_callid $incoming_callid"
	echo "SET VARIABLE calls_number $incoming_number"
	echo "SET VARIABLE calls_scenario $incoming_audiofork_curl_scenario"
	echo "SET VARIABLE calls_partnerid $incoming_audiofork_curl_partnerid"
	echo "SET VARIABLE calls_partnertoken $incoming_audiofork_curl_partnertoken"
	echo "SET VARIABLE calls_node_address $node_address"
	echo "SET VARIABLE calls_node_port $node_port"
}

calls_incoming_audiofork_exit()
{
	curl --silent --location --request POST "https://api.mrmarketing.su/partner-api/save" \
		--header "x-partnerid: $4" \
		--header "x-partnertoken: $5" \
		--header "Content-Type: application/json" \
		--data-binary "{
			\"sub_id\": \"answer_$6\",
			\"phone\": \"$3\",
			\"context\":\"ivr\",
			\"answer\":$6,
			\"shorthand\":\"$7\"
		}"
	echo "[$date_now_full] Method: audiofork, Callid: $2, Number: $3, partnerid, $4, partnertoken: $5, answer: $6, shorthand: $7, Return: $?" >> $log_incoming
}


## path
#cmd_realpath="readlink -e"
#path_script=$($cmd_realpath $0)
#path_script=$(dirname $path_script)
path_script="/var/lib/asterisk/agi-bin/calls"

# calls.main.conf
. $path_script/calls.main.conf.local
. $path_script/calls.main.conf

date_now_full=$(date "+%Y-%m-%d %H:%M:%S")
date_now_date=$(date "+%Y%m%d")
log_dtmf="/tmp/log/dtmf-$date_now_date"
log_recog="/tmp/log/recog-$date_now_date"
log_audio="/tmp/log/audio-$date_now_date"
log_incoming="/tmp/log/incoming-$date_now_date"
log_ping="/tmp/log/ping-$date_now_date"

sleep $script_sleep_start

case $1 in
	call_ready_one)		calls_get_ready_one return_ready_one
				[ $? -ne 0 -o -z "$return_ready_one" ] && exit 1
				#calls_get_number_by_id return_number $return_id_ready_one
				ready_one_id=${return_ready_one[0]}
				ready_one_number=${return_ready_one[1]}
				calls_set_calling_by_id return_set_calling $ready_one_id
				calls_get_audio_by_id return_audio_ask $ready_one_id ask
				calls_get_audio_by_id return_audio_one $ready_one_id one
				calls_get_audio_by_id return_audio_two $ready_one_id two
				if [ ! "$return_audio_ask" = "silence/1" ]; then
					#calls_originate_ivr return_originate $ready_one_id $ready_one_number $return_audio_ask $return_audio_one $return_audio_two | ncat 127.0.0.1 5038
					calls_originate_ivr return_originate $ready_one_id $ready_one_number $return_audio_ask $return_audio_one $return_audio_two | telnet
				else
					calls_set_status_by_id return_set_status $return_id_ready_one "ERROR-AUDIO" 0 0
				fi
				;;
	call_dtmf)		calls_set_dtmf_by_id return_set_dtmf $2 $3 $4 $5 $6
				;;
	call_recog)		calls_set_recog_by_id return_set_recog $2 $3 $4 $5 $6 $7
				;;
	call_recog_queue)	calls_set_recog_queue_by_id return_set_recog $2 $3 $4 $5 $6 $7
				;;
	call_recog_audiofork)	calls_set_recog_audiofork_by_id return_set_recog $2 $3 $4 $5 $6 $7 $8
				;;
	call_hangup)		calls_set_status_by_id return_set_status $2 $3 $4 $5 $6
				;;
	call_record)		calls_set_record_by_id return_set_record $2 $3 $4 $5
				;;
	call_audio_by_http)	calls_get_audio_by_http return_get_record $4 $5
				echo "[$date_now_full] ID: $2, Number: $3, URL: [$5], Error: $?" >> $log_audio
				;;
	incoming)		calls_incoming_curl_dtmf $2 $3
				;;
	call_incoming_audiofork_init)
				calls_incoming_audiofork_init return_incoming_init $2
				;;
	call_incoming_audiofork_exit)
				calls_incoming_audiofork_exit return_incoming_exit $2 $3 $4 $5 $6 $7
				;;
	call_ready_few)		mysql_cmd="UPDATE $db_table_calls_queue set calling=\"$$\", changed=NOW() WHERE result=\"READY\" and asterisk_id=$asterisk_id and calling IS NULL"
				mysql_exec "$mysql_cmd"
				mysql_cmd="UPDATE $db_table_calls_queue set calling=\"$$\", asterisk_id=$asterisk_id, changed=NOW() WHERE asterisk_id IS NULL and result=\"READY\" and calling IS NULL LIMIT $call_ready_few_limit"
				mysql_exec "$mysql_cmd"
				mysql_cmd="SELECT id, phone, network_prefere, context, scenario, amd_method, wav, wav1, wav2, timeout_ring, timeout_absolute, timeout_silence FROM $db_table_calls_queue where result=\"READY\" and asterisk_id=$asterisk_id and calling=\"$$\""
				if [ -z "${db_ca}" ]; then
					mysql_options="-h ${db_host} -D ${db_name} -u ${db_user} -p${db_pass}"
				else
					mysql_options="-h ${db_host} -D ${db_name} -u ${db_user} -p${db_pass} --ssl-ca=${db_ca}"
				fi
				mysql $mysql_options -sNB -e "$mysql_cmd" | sed 's/\t/,/g' | while IFS=',' read -r -a MA; do
					callid=${MA[0]}
					number=${MA[1]}
					network_prefere=${MA[2]}
					context=${MA[3]}
					scenario=${MA[4]}
					#if [ ! "$scenario" = "0" ]; then
					#	unset node_ready
					#	node_ready=$(curl --connect-timeout 2 --max-time 4 http://$node_address:$node_port/ping)
					#	if [ ! "$node_ready" = "yes" ]; then
					#		echo "$date_now_full [$node_ready]" >> $log_ping
					#		mysql_cmd="UPDATE $db_table_calls_queue set calling=NULL WHERE id=$callid"
					#		mysql_exec "$mysql_cmd"
					#		continue
					#	fi
					#fi
					amd_method=${MA[5]}
					calls_set_calling_by_id return_set_calling $callid
					calls_audio_url_to_file return_audio_ask ${MA[6]}
					calls_audio_url_to_file return_audio_one ${MA[7]}
					calls_audio_url_to_file return_audio_two ${MA[8]}
					timeout_ring=${MA[9]}
					timeout_absolute=${MA[10]}
					timeout_silence=${MA[11]}
					[ -z "$apikey" ] && apikey="default"
					if [ ! "$return_audio_ask" = "silence/1" ]; then
						calls_originate_ivr return_originate callid=$callid number=$number network_prefere=$network_prefere context=$context scenario=$scenario amd_method=$amd_method apikey=$apikey ask=$return_audio_ask one=$return_audio_one two=$return_audio_two timeout_ring=$timeout_ring timeout_absolute=$timeout_absolute timeout_silence=$timeout_silence | telnet
					else
						calls_set_status_by_id return_set_status $return_id_ready_one "ERROR-A" 0 0
					fi
				done
				;;
esac
