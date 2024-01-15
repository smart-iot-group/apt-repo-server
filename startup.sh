#!/bin/bash

# Function to handle termination signals
_term() {
  echo "Caught signal, stopping supervisord..."
  /usr/bin/supervisorctl stop all
  /usr/bin/supervisord -c /etc/supervisor/supervisord.conf shutdown
  exit 0
}

# Catch termination signals
trap _term SIGTERM SIGINT

mkdir -p /data/dists/trusty/main/binary-amd64/


# Start rsyslog for logging
service rsyslog start

# Start SSH service
service ssh start

# Start supervisord
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n -e debug

# Wait for supervisord to exit
wait $!
