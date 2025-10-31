#!/bin/bash
 
set -e
 
DOCKER_USERNAME="${1:-your-docker-username}"
PREVIOUS_TAG="${2:-previous}"
CONTAINER_NAME="${3:-docker-cicd-app-production}"
PORT="${4:-80}"
 
echo "Starting rollback process..."
echo "Rolling back to: $DOCKER_USERNAME/docker-cicd-app:$PREVIOUS_TAG"
 
# Pull previous image
echo "Pulling previous image..."
docker pull $DOCKER_USERNAME/docker-cicd-app:$PREVIOUS_TAG
 
# Stop current container
echo "Stopping current container..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true
 
# Start container with previous image
echo "Starting container with previous image..."
docker run -d \
  --name $CONTAINER_NAME \
  --restart always \
  -p $PORT:3000 \
  -e NODE_ENV=production \
  --health-cmd="curl -f http://localhost:3000/health || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  $DOCKER_USERNAME/docker-cicd-app:$PREVIOUS_TAG
 
echo "Rollback completed successfully!"
echo "Application rolled back to: $DOCKER_USERNAME/docker-cicd-app:$PREVIOUS_TAG"
 
# Show status
docker ps | grep $CONTAINER_NAME
