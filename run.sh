#!/bin/bash

# Default port
PORT=8080

# Check if port argument is provided
if [ ! -z "$1" ]; then
    PORT=$1
fi

echo "Removing old container to prevent Docker Compose v1 bugs..."
docker rm -f pad-card-guide 2>/dev/null || true

echo "Starting PAD Card Guide Docker container on port $PORT..."
PORT=$PORT docker-compose up -d --build

echo ""
echo "=========================================="
echo "Deployment successful!"
echo "Server is running at: http://localhost:$PORT"
echo "(If deployed remotely, use the host IP instead of localhost)"
echo "To stop the server, run: docker-compose down"
echo "=========================================="
