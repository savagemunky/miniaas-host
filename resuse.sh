#!/bin/bash

# Title: resuse.sh
#
# Purpose:
# A bash script to collect resource usage from IaaS hosts
# The results are then entered into a database

# Set PATH variable to ensure Cron can access all programs
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Database client
db_client="mysql"

# Database parameters
dbh="-h"
dbu="-u"
dbp="-p"

# Database configuration
db_host="172.16.0.200"
db_name="miniaas"
db_usr="pi"
db_pwd="pi"

# Set SQL table attributes
tblname="host_stats"
col1="ip_address"
col2="cpu_use"
col3="mem_total"
col4="mem_used"
col5="mem_free"
col6="store_total"
col7="store_used"
col8="store_free"

# Get IP Address
ipaddr=$(ifconfig eth0 | grep "inet addr" | tr ":" " " | awk -F" " '{ print $3 }')
#echo "DEBUG: Resource Usage for IP Address: $ipaddr"

# Get CPU Usage
cpuused=$(top -bn 2 -d 0.1 | grep '%Cpu(s):' | tail -n 1 | awk '{ print 100-$8 }')
#echo "DEBUG: CPU Usage: "$cpuused"%"

# Get Memory Usage
memtotal=$(free -m | grep "Mem:" | awk '{ print $2 }')
memused=$(free -m | grep -e "-/+ buffers/cache:" | awk -F" " '{ print $3 }')
memfree=$(free -m | grep -e "-/+ buffers/cache:" | awk -F" " '{ print $4 }')
#echo "DEBUG: Memory Usage: "$memtotal"MB Total, "$memused"MB Used, "$memfree"MB Free"

# Get Storage Usage
stortotal=$(df -m | grep /dev/ | awk -F" " '{ totalcol+=$2 } END { print totalcol }')
storused=$(df -m | grep /dev/ | awk -F" " '{ usedcol+=$3 } END { print usedcol }')
storfree=$(df -m | grep /dev/ | awk -F" " '{ freecol+=$4 } END { print freecol }')
#echo "DEBUG: Storage Usage: "$stortotal"MB Total, "$storused"MB Used, "$storfree"MB Free"

# Insert the collected statistics into the database
ins="INSERT INTO $tblname ($col1, $col2, $col3, $col4, $col5, $col6, $col7, $col8) VALUES ('$ipaddr', '$cpuused', '$memtotal', '$memused', '$memfree', '$stortotal', '$storused', '$storfree');"
echo $ins | $db_client $dbh$db_host $dbu$db_usr $dbp$db_pwd $db_name;

