#!/bin/bash
 
set -e
 
# Configuration
DOCKER_USERNAME="${1:-your-docker-username}"
IMAGE_TAG="${2:-latest}"
CONTAINER_NAME="docker-cicd-app-staging"
PORT="3001"
 
echo "Starting staging deployment..."
echo "Docker Username: $DOCKER_USERNAME"
echo "Image Tag: $IMAGE_TAG"
 
# Pull latest image
echo "Pulling Docker image..."
docker pull $DOCKER_USERNAME/docker-cicd-app:$IMAGE_TAG
 
# Stop existing container
echo "Stopping existing container..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true
 
# Run new container
echo "Starting new container..."
docker run -d \
  --name $CONTAINER_NAME \
  --restart unless-stopped \
  -p $PORT:3000 \
  -e NODE_ENV=staging \
  -e PORT=3000 \
  --health-cmd="curl -f http://localhost:3000/health || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  $DOCKER_USERNAME/docker-cicd-app:$IMAGE_TAG
 
# Wait for container to start
sleep 10
 
echo "Staging deployment completed successfully!"
echo "Application is running on port $PORT"
 
# Test the deployment
echo "Testing deployment..."
curl -f http://localhost:$PORT/health || echo "Health check failed"
 
# Show container status
docker ps | grep $CONTAINER_NAME
