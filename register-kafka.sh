#!/bin/sh

# Never exits: every service that resolves Kafka at startup fails until this registration exists.

RETRY_INTERVAL=2
HEARTBEAT_INTERVAL=10

SERVICE_NAME="kafka"
HOST="kafka"
PORT=9092

send_request() {
  local action=$1
  local payload=$(cat <<EOF
{
  "id": "$(uuidgen)",
  "correlation_id": "$(uuidgen)",
  "action": "$action",
  "data": {
    "service_name": "$SERVICE_NAME",
    "host": "$HOST",
    "port": $PORT
  },
  "transport": "HTTP"
}
EOF
)

  response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://service-discovery:3099/http-transport" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    --max-time 5)

  if [ "$response" = "200" ] || [ "$response" = "201" ]; then
    return 0
  fi

  echo "$action failed with HTTP $response"
  return 1
}

# Wait a few seconds for Kafka to start
sleep 5

until send_request "servicediscovery.registerService"; do
  sleep "$RETRY_INTERVAL"
done

# A heartbeat rewrites the whole entry, so it also restores an expired registration.
while true; do
  sleep "$HEARTBEAT_INTERVAL"
  send_request "servicediscovery.serviceHeartbeat"
done
