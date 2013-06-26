#!/bin/bash
killall twistd
twistd -y server-5.2.tac --pidfile=tmp/server-5.2.pid --logfile log/server-5.2.log
# twistd -y server-5.4.tac --pidfile=tmp/server-5.4.pid --logfile log/server-5.4.log
