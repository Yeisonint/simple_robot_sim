#!/bin/bash

IMAGE_NAME="ros2-gazebo-jazzy"
echo "🔧 Building Docker image..."
docker build -t $IMAGE_NAME .
