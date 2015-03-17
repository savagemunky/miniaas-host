#!/bin/bash
# A script that prints out current cpu usage
# Uses top, grep, tail and awk
# top:
# -b = batch mode (prints results to screen a specified number of times)
# -n = the number of times to iterate (2 = 2 iterations)
# -d = the delay between iterations (0.01 = 0.01 seconds)
# Grep for the line containing the CPU % info
# Use tail to get the last of the 2 iterations - the first one is usually inaccurate
# Finally use awk to add the 3 columns of cpu values together to get the total cpu usage
# The 3 cpu values represent:
# $2 = us = usage of user processes that have not been "niced"
# $4 = sy = usage of system / kernel processes
# $6 = ni = usage of user processes that have been "niced"
# Found at and adapated from:
# http://unix.stackexchange.com/questions/69185/getting-cpu-usage-same-every-time
#top -bn 2 -d 0.01 | grep '%Cpu(s):' | tail -n 1 | awk '{ print $2+$4+$6 }'

# Alternatively, $8 = id = the % of CPU that is idle
# 100% - idle% = usage %
usage=$(top -bn 2 -d 0.1 | grep '%Cpu(s):' | tail -n 1 | awk '{ print 100-$8 }')
echo "CPU Use: "$usage" %"
