#!/bin/bash
killall twistd
twistd -y server-6.0.tac --pidfile=tmp/server-6.0.pid --logfile log/server-6.0.log

