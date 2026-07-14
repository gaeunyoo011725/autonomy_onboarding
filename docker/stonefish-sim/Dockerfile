# Reproducible build of the Stonefish underwater simulation workspace.
#
# This image builds Stonefish core (vendored in-tree under ROS/external/stonefish)
# + the ROS 2 workspace (stonefish_ros2 + bringup) so anyone cloning the repo can
# run the simulation headless with a single command, no host setup and no network
# clones of external dependencies required.
#
# It runs the CONSOLE (no-GPU) simulator: physics + ROS topics, no window.
# For the 3D GUI, run on the host with WSLg via ../../setup.sh (see README).
#
# Build (from the repo root):
#   docker build -f docker/stonefish-sim/Dockerfile -t stonefish-sim .
# Run (headless, publishes ROS topics):
#   docker run --rm -it stonefish-sim
#
FROM ros:jazzy-ros-base

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# --- System dependencies -----------------------------------------------------
# Stonefish core build deps (libglm/sdl2/freetype) + runtime GL/SDL libraries
# (libStonefish.so links against them even in console mode) + build tooling.
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        cmake \
        build-essential \
        python3-colcon-common-extensions \
        python3-rosdep \
        libglm-dev \
        libsdl2-dev \
        libfreetype6-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
    && rm -rf /var/lib/apt/lists/*

# --- Copy sources ------------------------------------------------------------
WORKDIR /ros2_ws
# Vendored Stonefish core + the ROS packages all live under ROS/.
COPY ROS/ src/

# --- Build & install Stonefish core (from the vendored copy) ------------------
# Some SDL2 packages ship a stray space in sdl2-config.cmake that breaks the
# link line; strip it defensively (no-op if the file is already correct).
RUN sed -i 's/-lSDL2 /-lSDL2/g' /usr/lib/x86_64-linux-gnu/cmake/SDL2/sdl2-config.cmake 2>/dev/null || true \
    && cmake -S src/external/stonefish -B /tmp/stonefish_build \
    && cmake --build /tmp/stonefish_build -j"$(nproc)" \
    && cmake --install /tmp/stonefish_build \
    && ldconfig \
    && rm -rf /tmp/stonefish_build

# --- Build the ROS 2 workspace -----------------------------------------------
RUN apt-get update \
    && rosdep update \
    && rosdep install --from-paths src --ignore-src -r -y \
    && rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash \
    && colcon build --event-handlers console_direct+

COPY docker/stonefish-sim/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Foxglove Bridge WebSocket (used by the stonefish_foxglove.py launch).
EXPOSE 8765

ENTRYPOINT ["/entrypoint.sh"]
# Default: run the headless simulator. Override the command to change behaviour:
#   docker run --rm -it stonefish-sim bash                                   # shell
#   docker run --rm -it -p 8765:8765 stonefish-sim \
#       ros2 launch bringup stonefish_foxglove.py                            # + Foxglove Bridge
CMD ["ros2", "launch", "bringup", "stonefish_no_gui.py"]
