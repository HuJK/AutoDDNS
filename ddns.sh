#!/bin/bash
#set -x
domain="example.com"
testmsg="TestMsg:TE5T_server_a1ive"
url="https://freedns.afraid.org/dynamic/update.php?TnhNaDN4dnd5c0R4bGVKR3E2SXh2Qlk3OjE3NjM4OTAw"
portnum=998
cooldown=300
logfile="/var/log/ddnslog"
errfile="/var/log/ddnserr"
bzbox="busybox"

lastupld=0
lastsucs=0
while true
do
  sleep 0.125
  msg_recv=$( (sleep 1 ;echo $testmsg | nc -w 2 $domain $portnum) | (sleep 2 ;echo "T" | nc -w 1 127.0.0.1 $portnum) | nc -N -l -p $portnum )
  if [ $msg_recv = $testmsg ]; then
    true
    if [ $lastsucs -ne 1 ]; then
      echo "[$(date +%m/%d,%T)]: Test pass. Msg recv: $msg_recv" 
      lastsucs=1
    fi
  else
    lastsucs=0
    printf  "[$(date +%m/%d,%T)]: Test not pass. Msg recv: $msg_recv"
    if [ "$(expr "$(date +%s)" - "$lastupld")" -gt "$cooldown" ]; then
      output=$(wget -t 10 --no-check-certificate -qO - "$url" )
      status=$?
      if [ "$status" -eq 0 ]; then
        echo "Update Success: $output"
        lastupld="$(date +%s)"
        echo "$(date +%m/%d,%T) $output" >> $logfile
      else
        echo "Update Failed: $output"
        echo "$(date +%m/%d,%T) $output" >> $errfile
      fi
    else
      echo "waiting for cooldown: $(expr $cooldown + $(expr "$lastupld" - "$(date +%s)")) sec"
    fi
  fi
done

