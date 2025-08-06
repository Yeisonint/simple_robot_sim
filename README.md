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

