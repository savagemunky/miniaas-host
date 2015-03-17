#!/bin/bash
# Script to retrieve Total, Used and Free storage space in Megabytes
df -m | grep /dev/ | awk -F" " '{ totalcol+=$2 } { usedcol+=$3 } { freecol+=$4 } END { print "Storage Use - Total: " totalcol " MB, Used Space: " usedcol " MB, Free Space: " freecol " MB" }'
