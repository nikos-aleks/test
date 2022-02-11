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

#parse parse a=1 b=abc c=3 x= a_b_c e=4 f=qwe
#evalution arg a=1 b=abc c=3 d="a b c" e=4 f=qwe
#echo "[$arg_d]"

#aaa="a b c"
#aaa=$(echo ${aaa} | sed -r 's/ /_/g')
#echo $aaa


#utterance_pattern=$(echo $utterance | sed -r 's/[^ $]/\\b|\\b/g')
#utterance_pattern=$(echo $utterance | sed -r 's/ /\\\\b|\\\\b/g')
#utterance_pattern="\\\\b$utterance_pattern\\\\b"


#echo $utterance_pattern

#utterance="Пошли вы знаете куда"
utterance="Пошли"


mysql_cmd="SELECT count(*) from $db_table_filter_recog WHERE recognition<>1 and word LIKE \"$utterance\""
filter_no=$(mysql_exec "$mysql_cmd")
echo $filter_no
