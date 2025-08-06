FROM osrf/ros:jazzy-desktop

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=jazzy

RUN apt-get update && apt-get install -y \
    git curl wget lsb-release sudo gnupg2 locales build-essential \
    python3-colcon-common-extensions \
    ros-${ROS_DISTRO}-ros2-control \
    ros-${ROS_DISTRO}-ros2-controllers \
    ros-${ROS_DISTRO}-ros-gz \
    ros-${ROS_DISTRO}-ros-gz-bridge \
    ros-${ROS_DISTRO}-gz-ros2-control \
    ros-${ROS_DISTRO}-gz-tools-vendor \
    ros-${ROS_DISTRO}-gz-sim-vendor \
    ros-${ROS_DISTRO}-joy* \
    ros-${ROS_DISTRO}-teleop-twist-keyboard \
    ros-${ROS_DISTRO}-teleop-twist-joy \
    ros-${ROS_DISTRO}-joint-state-publisher \
    ros-${ROS_DISTRO}-navigation2 \
    ros-${ROS_DISTRO}-nav2-bringup \
    ros-${ROS_DISTRO}-robot-localization \
    ros-${ROS_DISTRO}-urdf-tutorial \
    ros-${ROS_DISTRO}-slam-toolbox \
    ros-${ROS_DISTRO}-xacro \
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