#!/bin/sh -x

evalution ()
{
	unset eval_arg_long
	for eval_arg in "${@#$1}"; do
		echo "arg=[$eval_arg] eval_arg_long=[$eval_arg_long]"
		if [ -z "$eval_arg_long" ]; then
			if [ -z "${eval_arg%%*\"*}" -a -n "${eval_arg%%*\"*\"*}" ]; then
				eval_arg_long="${eval_arg}"
			else
				[ -z "${eval_arg%%*\"*}" ] && eval $1_${eval_arg%%=*}=${eval_arg#*=} || eval $1_${eval_arg%%=*}=\"${eval_arg#*=}\"
			fi
		else
			eval_arg_long=${eval_arg_long}" "${eval_arg}
			if [ -z "${eval_arg%%*\"*}" ]; then
				eval $1_${eval_arg_long%%=*}=${eval_arg_long#*=}
				unset eval_arg_long
			fi
		fi
	done
}

mysql_exec()
{
	if [ -z "${db_ca}" ]; then
		mysql -h ${db_host} -D ${db_name} -u ${db_user} -p${db_pass} -Bse "$@"
	else
		mysql -h ${db_host} -D ${db_name} -u ${db_user} -p${db_pass} --ssl-ca=${db_ca} -Bse "$@"
	fi
}

parse()
{
	echo $*
	filter=$(echo ${6} | sed -r 's/_/ /g')
	echo [$filter]
}

path_script="/var/lib/asterisk/agi-bin/calls"

# calls.main.conf
. $path_script/calls.main.conf
. $path_script/calls.main.conf.local

node_address="188.119.112.159"
node_port="1815"

mysql_cmd="SELECT id, phone, network_prefere, context, apikey, wav, wav1, wav2, filter_recog_yes, filter_recog_no, timeout_ring, timeout_absolute, timeout_silence, scenario FROM ivrcrm"
mysql_options="-h ${db_host} -D ${db_name} -u ${db_user} -p${db_pass}"

mysql $mysql_options -sNB -e "$mysql_cmd" | sed 's/\t/,/g' | while IFS=',' read -r -a MA; do
	ready_one_id=${MA[0]}
	ready_one_scenario=${MA[13]}
	if [ ! "$scenario" = "0" ]; then
		node_ready=$(curl http://$node_address:$node_port/ping)
		[ ! "$node_ready" = "yes" ] && continue
	fi
	echo "[$ready_one_id][$ready_one_scenario]"
done
