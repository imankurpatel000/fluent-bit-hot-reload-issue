#!/bin/sh

mkdir -p /var/log

i=0
while true; do
    cur_date=$(date +"%Y-%m-%dT%H:%M:%S.000")
    echo "{\"environment\":\"otk\",\"component\":\"frontend\",\"level\":\"warning\",\"downstream_duration\":\"test_error\",\"msg\":\"Jjaakson test\",\"time\":\"$cur_date\", \"line\":\"$i\"}" >> /var/log/test.log
    i=$((i + 1))
done