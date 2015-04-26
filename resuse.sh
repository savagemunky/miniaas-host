#!/bin/bash

##############################################################################
# Title: resuse.sh                                                           #
#                                                                            #
# Purpose:                                                                   #
# A bash script to collect resource usage from IaaS hosts. The results are   #
# then entered into a database.                                              #
##############################################################################


### BEGIN VARIABLE DECLATIONS ###

# Set PATH variable to ensure Cron can access all programs
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# The name this script will use to identify itself when writing to the Syslog
slogid="resource-use-collector"

# The interface the script should use to find this hosts IP Address
ifce="br0" #eth0

# Database client
db_client="mysql"

# Database parameters
dbh="-h"
dbu="-u"
dbp="-p"

# Database configuration
db_host="172.16.0.200"
db_name="miniaas"
db_usr="miniaas"
db_pwd="miniaas"
tblname="ControlServer_host_stats"

# Database column namess
col1="log_time"
col2="cpu_use"
col3="mem_total"
col4="mem_used"
col5="mem_free"
col6="store_total"
col7="store_used"
col8="store_free"
col9="ip_address_id"

# Logging variables (date, time and hostname)
logdt=$(date +"%b %d %T")
loghn=$(hostname)

### END VARIABLE DECLATIONS ###


# Get IP Address
ipaddr=$(ifconfig $ifce | grep "inet addr" | tr ":" " " | awk -F" " '{ print $3 }')
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

# Test for Database connectivity
if $db_client $dbh$db_host $dbu$db_usr $dbp$db_pwd $db_name -e exit &> /dev/null
then
   # Insert the collected statistics into the database
   ins="INSERT INTO $tblname ($col1, $col2, $col3, $col4, $col5, $col6, $col7, $col8, $col9) VALUES (now(), '$cpuused', '$memtotal', '$memused', '$memfree', '$stortotal', '$storused', '$storfree', '$ipaddr');"
   echo $ins | $db_client $dbh$db_host $dbu$db_usr $dbp$db_pwd $db_name 2> resuse.err;

   if [ $? -eq 0 ]
   then
      # Log a success message in the Syslog if data was inserted successfully
      echo "$logdt $loghn $slogid: Resource usage entered into database successfully" | sudo tee -a /var/log/syslog > /dev/null
   else
      # Else log a failure message in the Syslog if the data could not be inserted
      echo "$logdt $loghn $slogid: Failed to enter resource usage into database - see the resuse.err file for details of the error" | sudo tee -a /var/log/syslog > /dev/null
   fi
else
   # Else log an error message in the Syslog if database connectivity could not be established
   echo "$logdt $loghn $slogid: Database connection error" | sudo tee -a /var/log/syslog > /dev/null
fi
