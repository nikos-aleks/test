#!/bin/sh

curl_yandex()
{
	curl -X POST \
		-H "Authorization: Api-Key AQVN3h_L7LZnG9FGW4bIzdYEKRkRITzzABohNbz-" \
		-H "Transfer-Encoding: chunked" \
		--data-binary "@$1" \
		"https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?topic=general&lang=ru-RU&folderId=b1grp3u93181d11hrrf6"
}

cmd_sox="/usr/bin/sox"

file_record="$2"
file_ogg="$file_record.ogg"
file_mp3="$file_record.mp3"
file_text="$file_record.text"
file_log="$file_record.log"

sleep .1

if [ -s ${file_record}.sln ]; then
	$cmd_sox -b 16 -r 8000 -t raw -e signed-integer ${file_record}.sln $file_ogg
	result=$(curl_yandex $file_ogg)
	utterance=$(echo $result | jq -r .result)
	[ -n "$utterance" ] && echo "[$utterance]" > $file_text
	echo "SET VARIABLE utterance \"$utterance\""
	echo "SET VARIABLE confidence 1"
else
	echo "SET VARIABLE utterance \"zero\""
	echo "SET VARIABLE confidence 0"
fi
