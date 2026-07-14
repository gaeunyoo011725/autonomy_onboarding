# Autonomy Onboarding — Stonefish Underwater Simulation

A ROS 2 (Jazzy) workspace that runs a BlueROV2 in the [Stonefish](https://github.com/patrykcieslak/stonefish)
marine simulator.

Everything needed to build and run is **vendored in this repository** — there are
no external clones or submodules to fetch. A plain `git clone` gives you the
complete, self-contained system:

```
ROS/
├── bringup/                # scenarios, launch files, robot + mesh data
└── external/
    ├── stonefish/          # Stonefish core (C++ simulation library, vendored)
    └── stonefish_ros2/     # ROS 2 wrapper for Stonefish (vendored)
docker/stonefish-sim/       # reproducible headless build/run
setup.sh                    # host build for the 3D GUI
```

## Which way do I run it?

| Goal | Use | Window? |
|------|-----|---------|
| Reproducible, headless (physics + ROS topics, CI) | **Docker** | no |
| See the 3D world / drive the robot | **Host + WSLg** (`setup.sh`) | yes |

Stonefish's graphical mode needs **OpenGL 4.3+ and a display**. On WSL2, WSLg
provides both to the host directly, so the GUI is easiest on the host. In a
container the GUI requires fragile GPU/display passthrough, so Docker here is
used for the **headless** path only.

---

## Option A — Docker (headless, reproducible)

Builds Stonefish core + the workspace into an image and runs the console simulator.
No host setup required beyond Docker.

```bash
# from the repo root
docker build -f docker/stonefish-sim/Dockerfile -t stonefish-sim .
docker run --rm -it stonefish-sim
```

This launches `stonefish_no_gpu.py`: no window, but it runs the physics and
publishes the ROS 2 topics (e.g. `/my_thruster_setpoints`, `/my_thruster_state`).
To get a shell instead:

```bash
docker run --rm -it stonefish-sim bash
```

## Option B — Host with the 3D GUI (WSL2 / WSLg)

Installs dependencies, builds the vendored Stonefish core, and builds the workspace.

```bash
# from the repo root
./setup.sh
source install/setup.bash
ros2 launch bringup stonefish_gpu.py       # 3D GUI window
# or, headless on the host:
ros2 launch bringup stonefish_no_gpu.py
```

`setup.sh` is idempotent: if `libStonefish.so` is already installed it skips the
core build.

---

## The simulation

- **Scenario:** [ROS/bringup/scenarios/underwater.scn](ROS/bringup/scenarios/underwater.scn)
  — ocean, seabed, a buoy, a cable, and the robot.
- **Robot:** [ROS/bringup/data/BlueROV2.scn](ROS/bringup/data/BlueROV2.scn)
  — a BlueROV2 (6-thruster vectored config). Physics/buoyancy come from a
  lightweight box hull ([BlueROV2_phy.obj](ROS/bringup/data/BlueROV2_phy.obj));
  the detailed `BlueROV2.obj` is used for rendering only.

### Controlling the thrusters

Publish 6 normalized setpoints in `[-1, 1]` (one per thruster):

```bash
ros2 topic pub /my_thruster_setpoints std_msgs/msg/Float64MultiArray \
  "{data: [0.5, 0.5, 0.5, 0.5, 0.0, 0.0]}"
```

Thruster telemetry is published on `/my_thruster_state`.

### GUI-only features

The forward camera and lights in `BlueROV2.scn` are commented out because the
console (no-GPU) launch rejects them. When using `stonefish_gpu.py`, uncomment
that block to enable them.

---

## Requirements

- **ROS 2 Jazzy** (`setup.sh` checks for `/opt/ros/jazzy`).
- For the GUI: a GPU with **OpenGL 4.3+** and a display (WSLg on WSL2).
- For Docker: Docker Engine.

Stonefish core build dependencies (`libglm-dev`, `libsdl2-dev`, `libfreetype6-dev`,
plus GL/GLU) are installed automatically by `setup.sh` and the Dockerfile.
