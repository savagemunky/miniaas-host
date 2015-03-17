#!/bin/bash
#free -m | grep "Mem:" | awk '{ print "Total: " $2 "\nUsed: " $3 "\nFree: " $4 }'
memtotal=$(free -m | grep "Mem:" | awk '{ print $2 }')
memused=$(free -m | grep "Mem:" | awk '{ print $3 }')
memfree=$(free -m | grep "Mem:" | awk '{ print $4 }')
echo "Memory Use - Total: "$memtotal" MB, Used: "$memused" MB, Free: "$memfree" MB"
