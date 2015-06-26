#!/bin/bash
killall twistd
twistd -y server-6.2.tac --pidfile=tmp/server-6.2.pid --logfile log/server-6.2.log

