#!/bin/bash
killall twistd
twistd -y server-7.0.tac --pidfile=tmp/server-7.0.pid --logfile log/server-7.0.log

