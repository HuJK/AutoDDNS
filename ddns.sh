#!/bin/sh
domain="example.com"
testmsg="TestMsg:TE5T_server_a1ive"
portnum=5566
cooldown=60
url="https://freedns.afraid.org/dynamic/update.php?API_Key_here"
logfile="/tmp/ddnslog"
errfile="/tmp/ddnserr"
lastupld=0

while true
do
  busybox sleep 1
  if [ "$( (busybox sleep 1; echo $testmsg | busybox nc -w 5 $domain $portnum) | busybox nc -w 5 -l -p $portnum )" = $testmsg ]; then
    #echo "Test pass"
    busybox true
  else
    printf  "Test not pass, "
    if [ "$(expr "$(busybox date +%s)" - "$lastupld")" -gt "$cooldown" ]; then
      output=$(busybox wget -t 10 --no-check-certificate -qO - "$url" )
      status=$?
      if [ "$status" -eq 0 ]; then
        echo "Update Success: $output"
        lastupld="$(busybox date +%s)"
        echo "$(date +%m/%d,%T) $output" >> $logfile
      else
        echo "Update Failed: $output"
        echo "$(date +%m/%d,%T) $output" >> $errfile
      fi
    else
      echo "waiting for cooldown: $(expr $cooldown + $(expr "$lastupld" - "$(busybox date +%s)")) sec"
    fi
  fi
done
