#!/bin/bash

ps aux | grep "make qemu" | grep -v grep | awk  '{print "kill -9 " $2}' | sh 
ps axf | grep "make qemu-nox-gdb" | grep -v grep | awk '{print "kill -9 " $1}' | sh
ps axf | grep "qemu-system-x86_64" | grep -v grep | awk '{print "kill -9 " $1}' | sh

