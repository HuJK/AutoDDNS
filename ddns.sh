#!/opt/bin/bash
domain="example.com"
testmsg="TestMsg:TE5T_server_a1ive"
url="https://freedns.afraid.org/dynamic/update.php?YourTokenHere"
bzbox="busybox"
portnum=999
cooldown=300
logfile="/opt/var/log/ddnslog"
errfile="/opt/var/log/ddnserr"
maxlog=64

test_bz_1o=$($bzbox nc -w 1 -l -p $portnum 2>&1)
if test "${test_bz_1o#*Usage}" != "$test_bz_1o" ; then
  echo "Error: Your busybox not compiled with CONFIG_NC_SERVER=y"
  exit 1
elif test "${test_bz_1o#*"Address already in use"}" != "$test_bz_1o" ; then
  echo  "Error: $test_bz_1o"
  exit 1
fi

test_wget_1o=$($bzbox wget -T 10 --no-check-certificate -qO - "https://google.com" 2>&1)
test_wget_1s=$?
if test "${test_wget_1o#*"not an http or ftp url"}" != "$test_wget_1o" ; then
  echo  "Warning: Your busybox not compiled with CONFIG_FEATURE_WGET_HTTPS=y"
fi


lastupld=0
lastsucs=0
while true
do
  $bzbox sleep 0.125
  if [ "$( ($bzbox sleep 0.4 ;$bzbox echo $testmsg | $bzbox nc -w 1 $domain $portnum) | $bzbox nc -w 2 -l -p $portnum )" = $testmsg ]; then
    true
    if [ $lastsucs -ne 1 ]; then
      echo "Test pass"
      lastsucs=1
    fi
  else
    lastsucs=0
    printf  "Test not pass, "
    if [ "$(expr "$(busybox date +%s)" - "$lastupld")" -gt "$cooldown" ]; then
      output=$($bzbox wget -t 10 --no-check-certificate -qO - "$url" 2>&1)
      status=$?
      if [ "$status" -eq 0 ]; then
        echo "Update Success: $output"
        lastupld="$(busybox date +%s)"
        echo "$(date +%m/%d,%T) $output" >> $logfile
        $bzbox tail -n $maxlog $logfile > "$logfile.tmp"
        $bzbox mv "$logfile.tmp" "$logfile"
      else
        echo "Update Failed: $output"
        echo "$(date +%m/%d,%T) $output" >> $errfile
        $bzbox tail -n $maxlog $errfile > "$errfile.tmp"
        $bzbox mv "$errfile.tmp" "$errfile"
      fi
    else
      echo "waiting for cooldown: $(expr $cooldown + $(expr "$lastupld" - "$(busybox date +%s)")) sec"
    fi
  fi
done
