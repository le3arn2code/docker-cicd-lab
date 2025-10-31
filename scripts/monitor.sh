#!/bin/bash
 
CONTAINER_NAME="${1:-docker-cicd-app-production}"
 
echo "Monitoring container: $CONTAINER_NAME"
echo "=================================="
 
# Check if container exists and is running
if ! docker ps | grep -q $CONTAINER_NAME; then
  echo "ERROR: Container $CONTAINER_NAME is not running!"
  exit 1
fi
 
# Get container information
echo "Container Status:"
docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
 
echo -e "\nHealth Status:"
docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null || echo "No health check configured"
 
echo -e "\nResource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $CONTAINER_NAME
 
echo -e "\nRecent Logs (last 20 lines):"
docker logs --tail 20 $CONTAINER_NAME
 
echo -e "\nContainer Details:"
docker inspect $CONTAINER_NAME | grep -E "(Image|Created|StartedAt)" | head -3
EOF
 
# Create rollback script
cat > scripts/rollback.sh << 'EOF'
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
