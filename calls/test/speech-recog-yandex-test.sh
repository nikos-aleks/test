#!/bin/sh -x

# sox incoming-woman-ask.wav -t raw -r 8k -c 1 -e a-law incoming-woman-ask.alaw
# sox -e signed-integer -r 8000 -c 1 -t raw -e a-law incoming-woman-ask.alaw speech.ogg
# sox -r 8000 -t raw -e a-law incoming-woman-ask.alaw speech.ogg
# sox incoming-woman-ask.wav -r 16000 speech.ogg

curl_yandex ()
{
	curl -X POST \
		-H "Authorization: Api-Key AQVN3h_L7LZnG9FGW4bIzdYEKRkRITzzABohNbz-" \
		-H "Transfer-Encoding: chunked" \
		--data-binary "@$1" \
		"https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?topic=general&lang=ru-RU&folderId=b1grp3u93181d11hrrf6"
	#echo '{"result":"Здравствуйте к сожалению я вам не дозвонилась"}'
}



cmd_sox="/usr/bin/sox"

date_now_full=$(date "+%Y-%m-%d.%H%M%S")
path_sounds="/tmp/sounds/yandex"
file_record="$1"
file_speech="$path_sounds/$date_now_full.$$.ogg"
format="sln"
intkey="#"
timeout_absolute=8000
timeout_silence=2

echo "RECORD FILE $file_record $format $intkey $timeout_absolute s=$timeout_silence"
#$cmd_sox -r 8000 -t raw -e a-law ${file_record}.sln $file_speech
$cmd_sox -b 16 -r 8000 -t raw -e signed-integer ${file_record}.sln $file_speech
#result=$(curl_yandex $file_speech)
#result='{"result":"Да согласен"}'

utterance=$(echo $result | jq -r .result)

echo "SET VARIABLE utterance \"$utterance\""
echo "SET VARIABLE confidence 1"
