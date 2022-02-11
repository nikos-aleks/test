#!/bin/sh

mysql_exec ()
{
mysql -h ${db_host} -D ${db_name} -u ${db_user} -p${db_pass} -Bse "$@"
}

## path
cmd_realpath="readlink -e"
path_script=$($cmd_realpath $0)
path_script=$(dirname $path_script)

# reports.conf
#. $path_script/reports.conf

db_name="asteriskcdrdb"
db_table="cdr"
db_port="3306"
db_user="reports"
db_pass="SRYes99bWftL"

date_now_full=$(date "+%Y-%m-%d %H:%M:%S")
date_now_date=$(date "+%Y%m%d")

db_host_list="voip-01 voip-02 voip-03 voip-04 voip-05 voip-06 voip-07 voip-08"
db_host_list="voip-08"

call_number=$1
call_date=$2

echo mysql -e "GRANT ALL on $db_name.$db_table to $db_user@'%' identified by '$db_pass'" > mysql.patch

for db_host in $db_host_list; do
#	ssh $db_host < mysql.patch
#	mysql_cmd="SELECT billsec FROM $db_table WHERE dst like '$call_number' and date(calldate)='$call_date' and dcontext='from-internal'"
#	mysql_return=$(mysql_exec "$mysql_cmd")
#	echo $mysql_return
done
