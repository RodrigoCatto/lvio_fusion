# Use the official ROS Noetic image with Ubuntu 20.04
FROM ros:noetic

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York

# Install necessary system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libeigen3-dev \
    libopencv-dev \
    libpcl-dev \
    libceres-dev \
    libgeographic-dev \
    libvtk7-dev \
    python3-rosdep \
    python3-catkin-tools \
    ros-noetic-catkin \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep update

# Upgrade CMake to a newer version if necessary
RUN apt-get update && apt-get install -y wget \
    && wget -qO- "https://github.com/Kitware/CMake/releases/download/v3.26.4/cmake-3.26.4-linux-x86_64.tar.gz" | tar --strip-components=1 -xz -C /usr/local

# Install Eigen 3.4.0 from source
RUN git clone https://gitlab.com/libeigen/eigen.git --branch 3.4.0 /opt/eigen && \
    cd /opt/eigen && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_CXX_STANDARD=17 && \
    make -j$(nproc) && \
    make install

# Install Sophus manually
RUN git clone https://github.com/strasdat/Sophus.git /opt/Sophus && \
    cd /opt/Sophus && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_CXX_STANDARD=17 && \
    make -j$(nproc) && \
    make install

# Set up the catkin workspace
RUN mkdir -p /catkin_ws/src
WORKDIR /catkin_ws/src

# Clone the lvio_fusion repository
RUN git clone https://github.com/jypjypjypjyp/lvio_fusion.git

# Install remaining dependencies using rosdep
RUN cd /catkin_ws && rosdep install --from-paths src --ignore-src -r -y

# Build the workspace (source ROS setup first)
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && cd /catkin_ws && catkin_make -DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_STANDARD_REQUIRED=ON -j4"

# Source the setup scripts automatically in new shells
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
RUN echo "source /catkin_ws/devel/setup.bash" >> ~/.bashrc

# Run the launch file
CMD ["/bin/bash"]


# CMD ["/bin/bash", "-c", "source /opt/ros/noetic/setup.bash && source /catkin_ws/devel/setup.bash && roslaunch lvio_fusion_node kitti.launch"]
