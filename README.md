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
#   /my_thruster_setpoints   (input  — you publish)
#   /my_thruster_state       (output — thruster telemetry)

# To watch telemetry:
ros2 topic echo /my_thruster_state

# To drive the 6 thrusters (values in [-1, 1]), for example,
ros2 topic pub /my_thruster_setpoints std_msgs/msg/Float64MultiArray \
  "{data: [0.4, 0.4, 0.4, 0.4, 0.0, 0.0]}"
```

- **Input** `/my_thruster_setpoints` — `std_msgs/msg/Float64MultiArray`, 6 values
  in `[-1, 1]` (`0` = stop, `±1` = full).
- **Output** `/my_thruster_state` — `stonefish_ros2/msg/ThrusterState`.

---

## 4. BlueROV2 model — thrusters

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
