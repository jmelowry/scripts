#!/usr/bin/env bash

if ! command -v nc &> /dev/null; then
    echo "Error: nc (netcat) is not installed."
    exit 1
fi

DEST_HOST=$1
DEST_PORT=$2
MAX_RETRIES=${3:-3} # Default to 3 retries if not specified
TIMEOUT=${4:-5}     # Default to 5 seconds timeout if not specified

# Example usage: ./testproxyv2.sh DEST_HOST DEST_PORT [MAX_RETRIES] [TIMEOUT]

# Validate input arguments
if [ -z "$DEST_HOST" ] || [ -z "$DEST_PORT" ]; then
    echo "Usage: $0 DEST_HOST DEST_PORT [MAX_RETRIES] [TIMEOUT]"
    exit 1
fi

# Validate port
if ! [[ $DEST_PORT =~ ^[0-9]+$ ]] || [ "$DEST_PORT" -lt 1 ] || [ "$DEST_PORT" -gt 65535 ]; then
    echo "Error: Invalid port number."
    exit 1
fi

# Define Proxy Protocol v2 header (customize as needed)
PROXY_HEADER='\x0d\x0a\x0d\x0a\x00\x0d\x0a\x51\x55\x49\x54\x0a\x21\x11\x00\x0c\xc0\xa8\x01\x01\xc0\xa8\x01\x02\x1f\x90\x00\x50'

for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "Attempt $i of $MAX_RETRIES: Connecting to $DEST_HOST on port $DEST_PORT with timeout $TIMEOUT seconds..."
    
    echo -n -e "$PROXY_HEADER" | nc -v "$DEST_HOST" "$DEST_PORT" &
    NC_PID=$!
    
    sleep "$TIMEOUT"
    
    if ps -p $NC_PID > /dev/null; then
        # nc is still running, kill it
        echo "Timeout reached, killing nc process..."
        kill $NC_PID
        wait $NC_PID 2>/dev/null
    else
        RESPONSE=$(cat <&0)
        echo "Proxy Protocol v2 header sent successfully to $DEST_HOST:$DEST_PORT"
        if [ -z "$RESPONSE" ]; then
            echo "Server response is empty. This may or may not be an issue depending on the server's expected behavior."
        else
            echo "Server response:"
            echo "$RESPONSE"
        fi
        exit 0
    fi
    
    if [ $i -lt $MAX_RETRIES ]; then
        echo "Retrying in 1 second..."
        sleep 1
    else
        echo "Maximum retries reached. Exiting."
        exit 1
    fi
done
