#!/bin/bash
 
TARGET_URL="${1:-http://localhost:3000}"
DURATION="${2:-30s}"
CONNECTIONS="${3:-10}"
 
echo "Running performance test against: $TARGET_URL"
echo "Duration: $DURATION"
echo "Concurrent connections: $CONNECTIONS"
 
# Install Apache Bench if not available
if ! command -v ab &> /dev/null; then
  echo "Installing Apache Bench..."
  sudo apt-get update
  sudo apt-get install -y apache2-utils
fi
 
# Run performance test
echo "Starting performance test..."
ab -t 30 -c $CONNECTIONS -g performance-results.tsv $TARGET_URL/
 
# Display results summary
echo -e "\nPerformance Test Summary:"
echo "========================="
tail -n 20 performance-results.tsv | head -n 10
 
# Test health endpoint
echo -e "\nTesting health endpoint..."
ab -n 100 -c 5 $TARGET_URL/health/
 
echo "Performance test completed!"

