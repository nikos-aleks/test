#!/bin/sh -x

calls_incoming_audiofork_curl()
{
	curl --silent --location --request POST "https://api.mrmarketing.su/crm/func/incoming-call?phone=$1"
}

calls_incoming_audiofork_init()
{
	incoming_audiofork_curl_result=$(calls_incoming_audiofork_curl $1)
	incoming_audiofork_curl_scenario=$(echo $incoming_audiofork_curl_result | jq -r '."scenario"')
	incoming_audiofork_curl_partnerid=$(echo $incoming_audiofork_curl_result | jq -r '."x-partnerid"')
	incoming_audiofork_curl_partnertoken=$(echo $incoming_audiofork_curl_result | jq -r '."x-partnertoken"')
	echo "Variable: calls_callid=$RANDOM"
	echo "Variable: calls_number=$1"
	echo "Variable: calls_scenario=$incoming_audiofork_curl_scenario"
	echo "Variable: calls_partnerid=$incoming_audiofork_curl_partnerid"
	echo "Variable: calls_partnertoken=$incoming_audiofork_curl_partnertoken"
}

calls_incoming_audiofork_init +79675557125
#echo $calls_init

#	 \
#		--header "Content-Type: application/json" \
#		--data-binary "{
#			\"scenario\": 152
#		}"
#		--header "x-partnerid: 152" \
#		--header "x-partnertoken: jIktBZpR1eunLtr3PlBTvJLC-Kf_tNuz" \
#		--header "scenario: a152" \
