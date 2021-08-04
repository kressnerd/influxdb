#!/bin/bash -e

/usr/bin/influxd &
PID=$!
echo $PID > /var/lib/influxdb/influxd.pid

PROTOCOL="http"
BIND_ADDRESS=$(influxd print-config --key-name http-bind-address)
TLS_CERT=$(influxd print-config --key-name tls-cert)
TLS_KEY=$(influxd print-config --key-name tls-key)
if [ -n "${TLS_CERT}" ] && [ -n "${TLS_KEY}" ]; then
  echo "TLS cert and key found -- using https"
  PROTOCOL="https"
fi
HOST=${BIND_ADDRESS%%:*}
HOST=${HOST:-"localhost"}
PORT=${BIND_ADDRESS##*:}

set +e
max_attempts=15
url="$PROTOCOL://$HOST:$PORT/ready"
result=$(curl -k -s -o /dev/null $url -w %{http_code})
while [ "$result" != "200" ]; do
  sleep 1
  result=$(curl -k -s -o /dev/null $url -w %{http_code})
  max_attempts=$(($max_attempts-1))
  if [ $max_attempts -le 0 ]; then
    echo "Failed to reach influxdb $PROTOCOL endpoint at $url"
    exit 1
  fi
done
set -e
