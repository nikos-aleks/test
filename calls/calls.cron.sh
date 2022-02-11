#!/bin/sh

script_main="calls.main.sh"
script_runner="calls.runner.sh"
pid_runner="/var/run/calls.runner.pid"

if ! pgrep -x "$script_runner" > /dev/null; then
	#systemctl restart calls
	sleep 1
fi
