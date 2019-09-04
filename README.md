function
==

Listen \$port and try to connect to \$domain:\$port. If failed, t will try to wget \$url to update your dns/

varaibles
==
variable name|explain
-------------|-------------
domain       |your domain here
portnum      |port number
cooldown     |cooldown for waiting dns update
url          |your ddns update url
logfile      |logfile
errfile      |error logfile

feature
==

1. check connectivity every second
2. cooldown after request success to wait dns update
3. available under buxybox only enveriment