#!/bin/sh

path_script="/var/lib/asterisk/agi-bin/calls"
cd $path_script
date_now_dateonly=$(date "+%Y%m%d")

cp -f /etc/asterisk/extensions_custom.conf .
cp -f /etc/asterisk/extensions_override_freepbx.conf .
cp -f /etc/asterisk/manager.conf .
cp -f /etc/asterisk/manager_custom.conf .
cp -f /etc/asterisk/amd.conf .
cp -f /etc/asterisk/amd.sql .
cp -f /var/lib/asterisk/agi-bin/googletts.agi .
cp -f /var/lib/asterisk/agi-bin/speech-recog-google.agi .
cp -f /var/lib/asterisk/agi-bin/speech-recog-start.sh .
cp -f /var/lib/asterisk/agi-bin/speech-recog-yandex.sh .
cp -f /var/lib/asterisk/agi-bin/speech-recog-queue.sh .
cp -f /var/lib/asterisk/agi-bin/speech-recog-beep.sh .
cp -f /var/lib/asterisk/sounds/en/silence/025.alaw .
cp -f /var/lib/asterisk/sounds/en/silence/0125.alaw .
cp -f /var/lib/asterisk/agi-bin/calls/sounds/beep.sln .
cp -f /etc/asterisk/scripts/cdr_convert.sh .
cp -f /etc/asterisk/scripts/asteriskcdrdb.clean.sql .
cp -f /etc/asterisk/scripts/asterisk.pjsip.trunk.sh .
cp -f /var/www/html/cleanup.sh .
cp -f /etc/crontab .
cp -f /usr/lib64/asterisk/modules/app_audiofork.so .

tar -cf calls.$date_now_dateonly.tar calls.main.conf calls.runner.sh calls.main.sh extensions_custom.conf extensions_override_freepbx.conf manager.conf manager_custom.conf amd.conf amd.sql googletts.agi speech-recog-google.agi speech-recog-start.sh speech-recog-yandex.sh speech-recog-queue.sh speech-recog-beep.sh 025.alaw 0125.alaw beep.sln cdr_convert.sh asteriskcdrdb.clean.sql asterisk.pjsip.trunk.sh cleanup.sh crontab app_audiofork.so

rm -f $path_script/extensions_custom.conf
rm -f $path_script/extensions_override_freepbx.conf
rm -f $path_script/manager_custom.conf
rm -f $path_script/amd.conf
rm -f $path_script/amd.sql
rm -f $path_script/googletts.agi
rm -f $path_script/speech-recog-google.agi
rm -f $path_script/speech-recog-start.sh
rm -f $path_script/speech-recog-yandex.sh
rm -f $path_script/speech-recog-queue.sh
rm -f $path_script/speech-recog-beep.sh
rm -f $path_script/025.alaw
rm -f $path_script/0125.alaw
rm -f $path_script/beep.sln
rm -f $path_script/cdr_convert.sh
rm -f $path_script/asteriskcdrdb.clean.sql
rm -f $path_script/asterisk.pjsip.trunk.sh
rm -f $path_script/cleanup.sh
rm -f $path_script/crontab
rm -f $path_script/app_audiofork.so
