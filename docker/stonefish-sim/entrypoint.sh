#!/usr/bin/env bash
# Source ROS 2 and the built workspace, then run whatever command was given
# (defaults to the headless simulator launch defined by CMD in the Dockerfile).
set -e
source /opt/ros/jazzy/setup.bash
source /ros2_ws/install/setup.bash
exec "$@"
