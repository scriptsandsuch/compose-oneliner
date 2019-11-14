#!/bin/bash

channelAndStatus=$2

channel=$(echo "$channelAndStatus" | cut -d '=' -f 1)
status=$(echo "$channelAndStatus" | cut -d '=' -f 2 | awk '{print tolower($0)}')
ip=$3
sendAgain=false

if [ "$status" = "on" ]; then
        status=1
else
        status=0
fi

moxaCallString='http://'$ip'/api/slot/0/io/relay/'$channel'/relayStatus'
curl -H "Accept: vdn.dac.v1" \
        -H "Content-Type: application/json" \
        -H "Content-Length: 49" \
        -X PUT \
        -d '{"slot":0,"io":{"relay":{"'"$channel"'":{"relayStatus":'"$status"'}}}}' \
        "$moxaCallString"

if [ "$channel" = 0 ]; then
        channel=2
	sendAgain=true
elif [ $channel = 3 ]; then
        channel=5
	sendAgain=true
fi

if [ $sendAgain = true ]; then
	moxaCallString='http://'$ip'/api/slot/0/io/relay/'$channel'/relayStatus'
        curl -H "Accept: vdn.dac.v1" \
                -H "Content-Type: application/json" \
                -H "Content-Length: 49" \
                -X PUT \
                -d '{"slot":0,"io":{"relay":{"'"$channel"'":{"relayStatus":'"$status"'}}}}' \
                "$moxaCallString"
fi
