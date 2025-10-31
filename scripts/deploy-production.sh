#!/bin/bash
 
set -e
 
# Configuration
DOCKER_USERNAME="${1:-your-docker-username}"
IMAGE_TAG="${2:-latest}"
CONTAINER_NAME="docker-cicd-app-production"
PORT="80"
 
echo "Starting production deployment..."
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
  --restart always \
  -p $PORT:3000 \
  -e NODE_ENV=production \
  -e PORT=3000 \
  --health-cmd="curl -f http://localhost:3000/health || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  $DOCKER_USERNAME/docker-cicd-app:$IMAGE_TAG
 
# Wait for container to be healthy
echo "Waiting for container to be healthy..."
timeout=60
counter=0
 
while [ $counter -lt $timeout ]; do
  if docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null | grep -q "healthy"; then
    echo "Container is healthy!"
    break
  fi
  
  if [ $counter -eq $((timeout-1)) ]; then
    echo "Container failed to become healthy within $timeout seconds"
    docker logs $CONTAINER_NAME
    exit 1
  fi
  
  echo "Waiting for container to be healthy... ($((counter+1))/$timeout)"
  sleep 1
  counter=$((counter+1))
done
 
echo "Production deployment completed successfully!"
echo "Application is running on port $PORT"
 
# Show container status
docker ps | grep $CONTAINER_NAME
