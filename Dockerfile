#############################
# Stage 1: OpenCV Builder   #
#############################
ARG CUDA_MAJOR_MINOR=12.8
ARG UBUNTU_FLAVOR=ubuntu24.04
FROM nvidia/cuda:${CUDA_MAJOR_MINOR}.0-cudnn-devel-${UBUNTU_FLAVOR} AS opencv-builder

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENCV_VERSION=4.11.0
ARG CUDA_ARCH_BIN=7.5   # GTX 1650
ARG MAKE_JOBS
ENV MAKE_JOBS=${MAKE_JOBS:--j$(nproc)}

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build pkg-config git \
    python3 python3-dev python3-numpy \
    libjpeg-dev libpng-dev libtiff-dev libopenjp2-7-dev \
    libavcodec-dev libavformat-dev libswscale-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libxvidcore-dev libx264-dev libmp3lame-dev libopus-dev libvorbis-dev \
    libva-dev \
    libdc1394-25 libdc1394-dev libxine2-dev libv4l-dev v4l-utils \
    libgtk-3-dev libtbb-dev libatlas-base-dev gfortran \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN git clone --depth 1 --branch ${OPENCV_VERSION} https://github.com/opencv/opencv.git && \
    git clone --depth 1 --branch ${OPENCV_VERSION} https://github.com/opencv/opencv_contrib.git

WORKDIR /tmp/opencv/build
RUN cmake -G Ninja \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D OPENCV_PC_FILE_NAME=opencv4.pc \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D OPENCV_EXTRA_MODULES_PATH=/tmp/opencv_contrib/modules \
    -D WITH_CUDA=ON \
    -D WITH_CUDNN=ON \
    -D OPENCV_DNN_CUDA=ON \
    -D WITH_CUBLAS=ON \
    -D CUDA_ARCH_BIN=${CUDA_ARCH_BIN} \
    -D CUDA_FAST_MATH=1 \
    -D ENABLE_FAST_MATH=1 \
    -D WITH_TBB=ON \
    -D WITH_V4L=ON \
    -D WITH_OPENGL=ON \
    -D WITH_GSTREAMER=ON \
    -D BUILD_opencv_cudacodec=OFF \ 
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D BUILD_EXAMPLES=OFF \
    ..
RUN ninja -j"$(nproc)" && ninja install && ldconfig


################################
# Stage 2: ROS Image           #
################################
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
        ros-${ROS_DISTRO}-cv-bridge \
        ros-${ROS_DISTRO}-xacro \
        mesa-utils \
        libgl1 \
        x11-apps \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-bad1.0-dev \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-tools \
        gstreamer1.0-x \
        gstreamer1.0-alsa \
        gstreamer1.0-gl \
        gstreamer1.0-gtk3 \
        gstreamer1.0-qt5 \
        gstreamer1.0-pulseaudio \
        gstreamer1.0-pipewire \
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

RUN apt-get update && apt-get install -y --no-install-recommends wget gnupg && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && rm -f cuda-keyring_1.1-1_all.deb && \
    apt-get update

RUN apt-get install -y --no-install-recommends \
      cuda-cudart-12-8 \
      cuda-libraries-12-8 \
      libcudnn9-cuda-12 \
      libjpeg-turbo8 libpng16-16 libtiff6 libopenjp2-7 \
      libavcodec60 libavformat60 libswscale7 \
      libva2 libdc1394-25 libxine2 libv4l-0 v4l-utils \
      libgtk-3-0 libtbb12 python3 python3-numpy \
    && rm -rf /var/lib/apt/lists/*

COPY --from=opencv-builder /usr/local/ /usr/local/

ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig
ENV LD_LIBRARY_PATH=/usr/local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
ENV PYTHONPATH=/usr/local/lib/python3.10/dist-packages:/usr/local/lib/python3.12/dist-packages${PYTHONPATH:+:$PYTHONPATH}

WORKDIR /workspace
