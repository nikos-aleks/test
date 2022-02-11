#!/bin/sh

# sox incoming-woman-ask.wav -t raw -r 8k -c 1 -e a-law incoming-woman-ask.alaw
# sox -e signed-integer -r 8000 -c 1 -t raw -e a-law incoming-woman-ask.alaw speech.ogg
# sox -r 8000 -t raw -e a-law incoming-woman-ask.alaw speech.ogg
# sox incoming-woman-ask.wav -r 16000 speech.ogg

curl_yandex()
{
	curl -X POST \
		-H "Authorization: Api-Key AQVN3h_L7LZnG9FGW4bIzdYEKRkRITzzABohNbz-" \
		-H "Transfer-Encoding: chunked" \
		--data-binary "@$1" \
		"https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?topic=general&lang=ru-RU&folderId=b1grp3u93181d11hrrf6"
	#echo '{"result":"Здравствуйте к сожалению я вам не дозвонилась"}'
}

checkresults()
{
while read row; do
	case ${row:0:4} in
		"200 ")		return		;;
		"510 ")		return		;;
		"520 ")		return		;;
		*)				;;
	esac
done
}

#result='{"result":"Здравствуйте к сожалению я вам не дозвонилась вы интересовались кредитом и меня есть возможность вам его выдать интересно скажите да"}'

cmd_sox="/usr/bin/sox"

date_now_full=$(date "+%Y-%m-%d.%H%M%S")
path_sounds="/tmp/sounds/yandex"
file_record="$path_sounds/$date_now_full.$$"
file_speech="$path_sounds/$date_now_full.$$.ogg"
file_log="$path_sounds/$date_now_full.$$.log"
format="sln"
intkey="#"
timeout_absolute=8000
timeout_silence=2

true > $file_log
echo "RECORD FILE $file_record $format $intkey $timeout_absolute s=$timeout_silence" >> $file_log
echo "RECORD FILE $file_record $format $intkey $timeout_absolute s=$timeout_silence"
checkresults

echo "$cmd_sox -b 16 -r 8000 -t raw -e signed-integer ${file_record}.sln $file_speech" >> $file_log
$cmd_sox -b 16 -r 8000 -t raw -e signed-integer ${file_record}.sln $file_speech >> $file_log 2>&1
result=$(curl_yandex $file_speech)

utterance=$(echo $result | jq -r .result)

echo "SET VARIABLE utterance \"$utterance\""
echo "SET VARIABLE confidence 1"
