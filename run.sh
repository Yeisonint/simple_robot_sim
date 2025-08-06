#!/bin/bash

IMAGE_NAME="ros2-gazebo-jazzy"
CONTAINER_NAME="robot-simulation"
SUDOERS_FILE="$(pwd)/.sudoers_sim"
USERNAME="$(whoami)"
USERID="$(id -u)"
USERGID="$(id -g)"

if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
  ./build.sh
else
  echo "Docker image '$IMAGE_NAME' already exists."
fi

if [[ -z "$DISPLAY" ]]; then
  export DISPLAY=$(ls /tmp/.X11-unix/X* 2>/dev/null | head -n1 | sed 's|/tmp/.X11-unix/X||' | awk '{print ":"$1}')
  echo "DISPLAY was unset, using: $DISPLAY"
fi

if ! xdpyinfo >/dev/null 2>&1; then
  echo "❌ DISPLAY $DISPLAY is not valid. Try using: ssh -X user@host"
  exit 1
fi

if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
  echo "Connecting to running container..."
  docker exec -it $CONTAINER_NAME bash
  exit 0
fi

if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
  echo "Starting existing container..."
  docker start -ai $CONTAINER_NAME
  exit 0
fi

init_dev_user='
set -e

USERNAME=${USERNAME:-dev_user}
USERID=${USERID:-1000}
USERGID=${USERGID:-1000}

existing_user=$(getent passwd "$USERID" | cut -d: -f1)
if [ -n "$existing_user" ] && [ "$existing_user" != "$USERNAME" ]; then
  usermod -l "$USERNAME" "$existing_user" > /dev/null
  usermod -d /workspace "$USERNAME" > /dev/null
fi

current_user=$(getent passwd "$USERID" | cut -d: -f1)
if [ "$current_user" != "$USERNAME" ]; then
  echo "❌ Could not set up user $USERNAME"
  exit 1
fi

existing_group=$(getent group "$USERGID" | cut -d: -f1)
if [ -z "$existing_group" ]; then
  groupmod -g "$USERGID" "$USERNAME" > /dev/null
else
  usermod -g "$existing_group" "$USERNAME" > /dev/null
fi

usermod -u "$USERID" -g "$USERGID" "$USERNAME" > /dev/null

echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev_user
chmod 0440 /etc/sudoers.d/dev_user

exec su "$USERNAME"
'


if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
  echo "Launching new container with Wayland..."
  exec docker run -it --name $CONTAINER_NAME \
    --net=host \
    --rm \
    -e HOME=/workspace \
    -e DISPLAY=$DISPLAY \
    -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
    -e CONTAINER_NAME=$CONTAINER_NAME \
    -e USERNAME=$USERNAME \
    -e USERID=$USERID \
    -e USERGID=$USERGID \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR \
    -v "$(pwd)/workspace:/workspace" \
    -v "$(pwd)/src:/workspace/src" \
    --entrypoint bash \
    $IMAGE_NAME \
    -c "$init_dev_user"
else
  echo "Launching new container with X11..."
  xhost +local:docker
  exec docker run -it --name $CONTAINER_NAME \
    --net=host \
    --rm \
    -e HOME=/workspace \
    -e DISPLAY=$DISPLAY \
    -e QT_X11_NO_MITSHM=1 \
    -e CONTAINER_NAME=$CONTAINER_NAME \
    -e USERNAME=$USERNAME \
    -e USERID=$USERID \
    -e USERGID=$USERGID \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v "$(pwd)/workspace:/workspace" \
    -v "$(pwd)/src:/workspace/src" \
    --entrypoint bash \
    $IMAGE_NAME \
    -c "$init_dev_user"
fi
