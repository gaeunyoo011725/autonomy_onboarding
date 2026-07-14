# MISO Autonomy Onboarding

BlueROV2 underwater simulation on [Stonefish](https://github.com/patrykcieslak/stonefish)
(ROS 2 Jazzy). Stonefish core and `stonefish_ros2` are vendored in-tree, so a
plain `git clone` is self-contained — no submodules, no external downloads.

There are two ways to run it:

- **Docker** — headless (physics + ROS topics, no window). Works on any OS with
  Docker; needs nothing else installed.
- **Host** — full 3D GUI. Needs Ubuntu 24.04 + ROS 2 Jazzy (on Windows use WSL2).

---

## 1. Install

```bash
git clone <your-repo-url> autonomy_onboarding
cd autonomy_onboarding
```

**Docker path:** install [Docker Engine](https://docs.docker.com/engine/install/).

**Host (GUI) path:** install **ROS 2 Jazzy** on Ubuntu 24.04
([guide](https://docs.ros.org/en/jazzy/Installation.html)). All other
dependencies (Stonefish libs, `colcon`, `rosdep`) are handled by `setup.sh` in
the next step.

---

## 2. Build

**Docker:**

```bash
docker build -f docker/stonefish-sim/Dockerfile -t stonefish-sim .
```

**Host:** builds the vendored Stonefish core + the ROS workspace (idempotent):

```bash
./setup.sh
```

---

## 3. Launch the sim + ROS commands

**Docker (headless):**
Install ROS2 Jazzy on your local machine:
```bash
docker run --rm -it --name sim stonefish-sim
# in another terminal, work inside the container (host has no ROS):
docker exec -it sim bash
source /opt/ros/jazzy/setup.bash && source /ros2_ws/install/setup.bash
```

**Host:**
If you already have ROS2 Jazzy installed:
```bash
source install/setup.bash                    # in every new terminal
ros2 launch bringup stonefish_gui.py         # 3D GUI window
# or headless:
ros2 launch bringup stonefish_no_gui.py
```

**Robot ROS Topics** (once sourced):

```bash
ros2 topic list

# To watch telemetry:
ros2 topic echo /my_thruster_state

# To drive the 6 thrusters (values in [-1, 1]), for example,
ros2 topic pub /my_thruster_setpoints std_msgs/msg/Float64MultiArray \
  "{data: [0.4, 0.4, 0.4, 0.4, 0.0, 0.0]}"
```

| Topic | Direction | Type |
|---|---|---|
| `/my_thruster_setpoints` | input (you publish) | `std_msgs/msg/Float64MultiArray` — 6 values in `[-1, 1]` |
| `/my_thruster_state` | output | `stonefish_ros2/msg/ThrusterState` |
| `/bluerov/odometry` | output | `nav_msgs/msg/Odometry` (pose/twist in `world_ned`) |
| `/bluerov/imu` | output | `sensor_msgs/msg/Imu` |
| `/bluerov/pressure` | output | `sensor_msgs/msg/FluidPressure` |
| `/bluerov/dvl` (+ `/dvl/altitude`) | output | `stonefish_ros2/msg/DVL` (+ `sensor_msgs/msg/Range`) |
| `/tf` | output | `tf2_msgs/msg/TFMessage` (`world_ned` → `BLUEROV2/base_link`) |

---

## 4. Visualize in Foxglove (no GPU needed)

Foxglove Studio shows the robot pose, sensors, TF and plots over a WebSocket —
works from any OS, including against the Docker container, with no display/GPU.
It shows the ROS *data*, not Stonefish's rendered ocean.

**Run the sim with the Foxglove Bridge:**

```bash
# Host:
ros2 launch bringup stonefish_foxglove.py

# Docker (publish the bridge port):
docker run --rm -it -p 8765:8765 stonefish-sim ros2 launch bringup stonefish_foxglove.py
```

**Connect:** open [Foxglove Studio](https://foxglove.dev/download) (app or
browser) → *Open connection* → **Foxglove WebSocket** → `ws://localhost:8765`.

Useful panels: a **3D** panel (fixed frame `world_ned`) shows the robot moving
via `/tf` and `/bluerov/odometry`; **Plot** panels show IMU / pressure / DVL /
thruster state. `foxglove_bridge` is installed automatically (Docker via
`rosdep`; host via `setup.sh`).

---

## 5. BlueROV2 model — thrusters

Robot file is defined in [ROS/bringup/data/BlueROV2.scn](ROS/bringup/data/BlueROV2.scn).
Mass 12.5 kg, ~12.7 L displaced (slightly positive buoyancy).
Body frame: **x = forward, y = starboard, z = down**.

Six thrusters, **vectored** config. The list order = the `/my_thruster_setpoints`
array index:

| Index | Thruster | Orientation | Drives |
|:---:|---|---|---|
| 0 | `ThrusterFrontPort`      | horizontal, +45°  | surge / sway / yaw |
| 1 | `ThrusterFrontStarboard`| horizontal, −45°  | surge / sway / yaw |
| 2 | `ThrusterRearPort`      | horizontal, +135° | surge / sway / yaw |
| 3 | `ThrusterRearStarboard` | horizontal, −135° | surge / sway / yaw |
| 4 | `ThrusterVertPort`      | vertical          | heave / roll / pitch |
| 5 | `ThrusterVertStarboard` | vertical          | heave / roll / pitch |

```bash
# forward/horizontal   → the four vectored thrusters (0–3)
ros2 topic pub /my_thruster_setpoints std_msgs/msg/Float64MultiArray "{data: [0.5,0.5,0.5,0.5,0,0]}"
# descend/ascend       → the two vertical thrusters (4–5)
ros2 topic pub /my_thruster_setpoints std_msgs/msg/Float64MultiArray "{data: [0,0,0,0,0.5,0.5]}"
# yaw in place         → oppose front vs rear
ros2 topic pub /my_thruster_setpoints std_msgs/msg/Float64MultiArray "{data: [0.5,-0.5,-0.5,0.5,0,0]}"
```

> The detailed `BlueROV2.obj` is used for rendering only; physics/buoyancy use a
> lightweight box hull ([BlueROV2_phy.obj](ROS/bringup/data/BlueROV2_phy.obj)).
> A forward camera and lights are defined but commented out (GPU-only; the
> headless launch rejects them).
