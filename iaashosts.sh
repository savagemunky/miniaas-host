#!/bin/bash

##############################################################################
# Title: Infrastructure-as-a-Service Host Finder Script                      #
#                                                                            #
# Purpose:                                                                   #
# Script to find the Hostname, MAC and IP addresses that DHCP has assigned   #
# to the IaaS Hosts                                                          #
##############################################################################


### BEGIN VARIABLE DECLARATIONS ###

# Set PATH variable to ensure Cron can access all programs
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# The name this script will use to identify itself when writing to the Syslog
slogid="iaas-hosts-updater"

# MAC Address Filtering for IaaS Hosts
# Raspberry Pi MAC addresses all start with these hex digits (to date)
mac_filter="b8:27:eb:"

# Database client
dbclient="mysql"

# Database parameters
dbh="-h" # Hostname Parameter
dbu="-u" # Username Parameter
dbp="-p" # Password Parameter

# Database configuration
db_server="172.16.0.200" # Server Hostname or IP Address
db_port=3306 # Server Port - not used
db_name="miniaas" # Database Name
db_usr="pi" # Username (actual)
db_pwd="pi" # Password (actual)
db_tblname="hosts"

# Database column names
col1="ip_address"
col2="mac_address"
col3="host_name"
col4="online"

# Static / Default Database Values
null="NULL" # For NULL values - not used
online="0" # Default to 0 for offline status

# ARP output path and filename
arp_out="arp.ssv"

# Logging Variables (date, time and hostname)
logdt=$(date +"%b %d %T")
loghn=$(hostname)

# Set the Internal Field Separator to be a single space
IFS=" "

### END VARIABLE DECLARATIONS ###


# Use ARP to get a list of IP addresses, MAC addresses and Hostnames
# The -a output puts brackets around the IP address
# The global substitution (gsub) regex used in the awk command replaces the brackets with nothing
# This effectively removes the brackets
# The IP Addresses are then sorted by individual octet, in numerical order
# Finally, the resultant list of IP addresses is dumped into a file
arp -a | grep "$mac_filter" | awk '{ gsub(/\(|\)/, ""); print $2 " " $4 " " $1 }' | sort -t "." -k 1,1n -k 2,2n -k 3,3n -k 4,4n > $arp_out

# Alternative ARP command, as above but without the MAC Address filter
#arp -a | awk '{ gsub(/\(|\)/, ""); print $2 " " $4 " " $1 }' | sort -t "." -k 1,1n -k 2,2n -k 3,3n -k 4,4n > $arp_out

#echo "DEBUG: Contents of arp.ssv"; cat arp.ssv

# This is quite crude, but works most of the time...
# Test to see if there is database connectivity - log an error and exit if there isn't
# The list of hosts is read in from the ARP space-separated value (.ssv) file
# Each entry is pinged before we attempt an insert to make sure that the host is actually online
# A different insert will be performed before depending on whether the host responds or not
# Finally, the SQL statements are piped to the MySQL client an the insert is performed
# NOTE: The ARP table will drop the MAC address of a host that fails to ping
# If this happens prior to the script performing a ping, an offline host will not be detected at all
# and can't be set as offline by the script, which could lead to offline hosts being erroneously shown
# as online

# Test to see if there is database connectivity
if $dbclient $dbh$db_server $dbu$db_usr $dbp$db_pwd $db_name -e exit &> /dev/null
then
   # Read in Hostnames, IP and MAC addresses, line by line, from the ARP output file
   while read ip mac hostname
      do
         # Check to see if the current host is online
         if ping -c 1 -w 1 $ip &> /dev/null
         then
            # Host is online
            online="1"
         else
            # Host is offline
            online="0"
         fi

         # Insert IP, MAC, Hostname, and Online status into the database
         # If the IP address already exists in the table, then update the other values
         ins="INSERT INTO $db_tblname ($col1, $col2, $col3, $col4) VALUES ('$ip', '$mac', '$hostname', '$online') ON DUPLICATE KEY UPDATE mac_address = '$mac', host_name = '$hostname', online = '$online';"
         echo $ins

   done < $arp_out | $dbclient $dbh$db_server $dbu$db_usr $dbp$db_pwd $db_name 2> iaashosts.err;

   if [ $? -eq 0 ]
   then
      # Log a success message in the Syslog if the database was updated successfully
      echo "$logdt $loghn $slogid: Database hosts table updated successfully" | sudo tee -a /var/log/syslog > /dev/null
   else
      # Else log a failure message in the Syslog if database table could not be updated
      echo "$logdt $loghn slogid: Failed to update database hosts table - see the iaashosts.err file for details of the error" | sudo tee -a /var/log/syslog > /dev/null
   fi
else
   # Else log an error message in the Syslog if database connectivity could not be established
   echo "$logdt $loghn $slogid: Database connection error!" | sudo tee -a /var/log/syslog > /dev/null
fi
