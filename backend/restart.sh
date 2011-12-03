#!/bin/bash
killall twistd
# twistd -y server-4.1.tac --pidfile=tmp/server-4.1.pid --logfile log/server-4.1.log
# twistd -y server-4.2.tac --pidfile=tmp/server-4.2.pid --logfile log/server-4.2.log
twistd -y server-4.3.tac --pidfile=tmp/server-4.3.pid --logfile log/server-4.3.log
