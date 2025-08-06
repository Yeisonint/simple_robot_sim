# Simple robot simulation exaple with ROS2

## Prerequisites

Install [docker](https://docs.docker.com/engine/install/ubuntu/) and setup to run without `sudo`.

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

Install [Nvidia Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

Check installation with:

```bash
docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
```

## Launch simulation

Source code is based from [How to Use ROS2 Jazzy and Gazebo Harmonic for Robot Simulation](https://www.youtube.com/watch?v=b8VwSsbZYn0)

In one terminal after execute `./run.sh`:

```bash
colcon build
source install/setup.bash
ros2 launch fws_robot_sim fws_robot_spawn.launch.py
```

In another terminal after execute `./run.sh`:

```bash
source install/setup.bash
ros2 launch velocity_pub four_ws_control.launch.py
```