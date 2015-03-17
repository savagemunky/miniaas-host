#!/bin/bash
# Script to retrieve Total, Used and Free storage space
df -m | grep /dev/ | awk -F" " '{ totalcol+= } { usedcol+= } { freecol+= } END { print totalcol " " usedcol " " freecol }'
