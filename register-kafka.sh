#!/bin/sh

MAX_RETRIES=6
SLEEP_BETWEEN=2
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

  for attempt in $(seq 1 $MAX_RETRIES); do
    #echo "Attempt $attempt: Sending $action..."
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://service-discovery:3099/http-transport" \
      -H "Content-Type: application/json" \
      -d "$payload" \
      --max-time 5)

    if [ "$response" = "200" ] || [ "$response" = "201" ]; then
      #echo "$action successful."
      return 0
    else
      echo "$action failed with HTTP $response"
      if [ "$attempt" -lt "$MAX_RETRIES" ]; then
        echo "Retrying in $SLEEP_BETWEEN seconds..."
        sleep "$SLEEP_BETWEEN"
      fi
    fi
  done

  echo "$action failed after $MAX_RETRIES attempts."
  return 1
}

# Wait a few seconds for Kafka to start
sleep 5

# Register Kafka initially
send_request "servicediscovery.registerService" || exit 1

# Start heartbeat loop
while true; do
  sleep "$HEARTBEAT_INTERVAL"
  send_request "servicediscovery.serviceHeartbeat"
done
