#!/bin/bash
killall twistd
twistd -y server-6.1.tac --pidfile=tmp/server-6.1.pid --logfile log/server-6.1.log

