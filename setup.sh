#!/usr/bin/env bash
#
# Host setup for the Stonefish underwater simulation (GUI-capable).
#
# Installs Stonefish core + all ROS dependencies and builds this workspace so
# you can run the graphical simulator (stonefish_gui.py) directly on the host.
# On WSL2, WSLg provides the display/GPU, so the 3D window "just works" after
# this script completes.
#
# For a fully reproducible HEADLESS run instead, use Docker (see README.md).
#
# Usage:
#   ./setup.sh
#   source install/setup.bash
#   ros2 launch bringup stonefish_gui.py
#
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-jazzy}"
WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Stonefish core is vendored in-tree; no network clone needed.
STONEFISH_SRC="${WS_DIR}/ROS/external/stonefish"

echo ">>> Workspace: ${WS_DIR}"
echo ">>> ROS distro: ${ROS_DISTRO}"

if [ ! -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
    echo "ERROR: ROS 2 ${ROS_DISTRO} not found at /opt/ros/${ROS_DISTRO}." >&2
    echo "Install ROS 2 ${ROS_DISTRO} first: https://docs.ros.org" >&2
    exit 1
fi

# --- 1. System dependencies for Stonefish core -------------------------------
echo ">>> Installing system dependencies (sudo required)..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    git cmake build-essential \
    python3-colcon-common-extensions python3-rosdep \
    libglm-dev libsdl2-dev libfreetype6-dev \
    libgl1-mesa-dev libglu1-mesa-dev

# --- 2. Build & install Stonefish core (vendored in-tree) --------------------
if [ -f /usr/local/lib/libStonefish.so ]; then
    echo ">>> Stonefish core already installed at /usr/local/lib/libStonefish.so (skipping)."
else
    echo ">>> Building vendored Stonefish core from ${STONEFISH_SRC}..."
    # Defensive fix for a stray space some SDL2 packages leave in the link line.
    sudo sed -i 's/-lSDL2 /-lSDL2/g' /usr/lib/x86_64-linux-gnu/cmake/SDL2/sdl2-config.cmake 2>/dev/null || true
    cmake -S "${STONEFISH_SRC}" -B "${STONEFISH_SRC}/build"
    cmake --build "${STONEFISH_SRC}/build" -j"$(nproc)"
    sudo cmake --install "${STONEFISH_SRC}/build"
    sudo ldconfig
fi

# --- 3. ROS dependencies -----------------------------------------------------
echo ">>> Resolving ROS dependencies with rosdep..."
sudo rosdep init 2>/dev/null || true
rosdep update
cd "${WS_DIR}"
# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO}/setup.bash"
# Install declared dependencies. Do NOT swallow failures — a missing dep (e.g.
# foxglove_bridge) should stop here with a clear error rather than surface later
# as a broken launch. (set -e aborts on non-zero.)
rosdep install --from-paths ROS --ignore-src -r -y

# Sanity-check the visualization dependency is actually resolvable/installed.
if ! rosdep resolve foxglove_bridge >/dev/null 2>&1; then
    echo "ERROR: foxglove_bridge could not be resolved by rosdep." >&2
    echo "       Install it manually: sudo apt install ros-${ROS_DISTRO}-foxglove-bridge" >&2
    exit 1
fi

# --- 4. Build the workspace --------------------------------------------------
echo ">>> Building the workspace with colcon..."
cd "${WS_DIR}"
colcon build --symlink-install

cat <<EOF

>>> Done. To run the simulation:

    source install/setup.bash
    ros2 launch bringup stonefish_gui.py      # 3D GUI window
    ros2 launch bringup stonefish_no_gui.py   # headless (physics + ROS topics)

EOF
