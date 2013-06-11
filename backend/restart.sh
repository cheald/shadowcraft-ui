#!/bin/bash
killall twistd
# twistd -y server-4.1.tac --pidfile=tmp/server-4.1.pid --logfile log/server-4.1.log
# twistd -y server-4.2.tac --pidfile=tmp/server-4.2.pid --logfile log/server-4.2.log
# twistd -y server-5.0.tac --pidfile=tmp/server-5.0.pid --logfile log/server-5.0.log
twistd -y server-5.2.tac --pidfile=tmp/server-5.2.pid --logfile log/server-5.2.log
