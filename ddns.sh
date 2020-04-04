#!/bin/bash
#set -x
bzbox="busybox"
domain="example.com"
testmsg="<h1>$($bzbox hostname) is live</h1>$($bzbox date)"
url="https://freedns.afraid.org/dynamic/update.php?YOUR_KEY_ID"
port=998
cooldown=300
logfile="/var/log/ddnslog"
errfile="/var/log/ddnserr"

lastupld=0
lastsucs=0

#Setup http server
trap "kill 0" SIGINT
while true
do
  $bzbox echo -e "HTTP/1.1 200 OK\r\n\r\n$testmsg" | $bzbox nc -l -w0 -p $port > /dev/null
done &

while true
do
  sleep 1
  msg_recv=$($bzbox wget -t 10 -qO - "http://$domain:$port" )
  if [ "$msg_recv" = "$testmsg" ]; then
    true
    if [ $lastsucs -ne 1 ]; then
      echo "[$($bzbox date +%m/%d,%T)]: Test pass. Msg recv: $msg_recv" 
      #lastsucs=1
    fi
  else
    lastsucs=0
    printf  "[$($bzbox date +%m/%d,%T)]: Test not pass. Msg recv: $msg_recv"
    if [ "$(expr "$($bzbox date +%s)" - "$lastupld")" -gt "$cooldown" ]; then
      output=$($bzbox wget -t 10 --no-check-certificate -qO - "$url" )
      status=$?
      if [ "$status" -eq 0 ]; then
        echo "Update Success: $output"
        lastupld="$($bzbox date +%s)"
        echo "$($bzbox date +%m/%d,%T) $output" >> $logfile
      else
        echo "Update Failed: $output"
        echo "$($bzbox date +%m/%d,%T) $output" >> $errfile
      fi
    else
      echo "waiting for cooldown: $(expr $cooldown + $(expr "$lastupld" - "$($bzbox date +%s)")) sec"
    fi
  fi
done

