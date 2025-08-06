FROM osrf/ros:jazzy-desktop

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=jazzy

RUN apt-get update && apt-get install -y \
    git curl wget lsb-release sudo gnupg2 locales build-essential \
    python3-colcon-common-extensions \
    ros-${ROS_DISTRO}-ros-gz \
    ros-${ROS_DISTRO}-gz-tools-vendor \
    ros-${ROS_DISTRO}-gz-sim-vendor \
    mesa-utils \
    libgl1 \
    x11-apps \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash dev_user && \
    usermod -d /workspace dev_user && \
    echo "dev_user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev_user && \
    chmod 0440 /etc/sudoers.d/dev_user

RUN locale-gen en_US en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /root/.bashrc

WORKDIR /workspace