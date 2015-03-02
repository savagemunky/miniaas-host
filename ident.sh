#!/bin/bash

# A script which blinks the Activity LED on a Rasberry Pi
# about 20 times over 10 seconds
# Purpose: To help identify an individual Raspberry Pi in a group
# This script needs to be run with elevated priviledges (sudo)
# Tested on a Rasberry Pi Model B+ but should work on any Pi

# Stop the SD Card from triggering the Activity LED
echo none > /sys/class/leds/led0/trigger

# Zero the count variable
COUNT=0

# While the counter is less than 20...
while [ $COUNT -lt 20 ]; do
   # Turn the Activity LED on
   echo 1 > /sys/class/leds/led0/brightness
   # Sleep for half a second
   sleep 0.5
   # Turn the Activity LED off
   echo 0 > /sys/class/leds/led0/brightness
   # Sleep for half a second
   sleep 0.5
   # Increment the count variable
   let COUNT=COUNT+1
done

# Reset the Activity LED to its default state (monitoring SD Card activity)
echo mmc0 > /sys/class/leds/led0/trigger
