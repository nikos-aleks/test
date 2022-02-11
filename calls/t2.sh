#!/bin/sh

asterisk_pjsip_trunk=$1
mysql_cmd="SELECT disposition, count(*) as count FROM cdr WHERE INSTR(dstchannel,\"$asterisk_pjsip_trunk\") and calldate > DATE_SUB(NOW(), INTERVAL 1 day) and DATE(calldate) = DATE(NOW()) group by disposition;"

echo -n "{\"ZERO\":\"0\"";
mysql -h localhost -D asteriskcdrdb -Bse "$mysql_cmd" | sed 's/\t/,/g' | sed 's/ //g' | while IFS=',' read -r -a MA; do
	echo -n ",\"${MA[0]}\":\"${MA[1]}\""
done
echo "}"
