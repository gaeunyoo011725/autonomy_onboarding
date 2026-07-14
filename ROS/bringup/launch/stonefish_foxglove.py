# Headless Stonefish simulation + Foxglove Bridge.
#
# Runs the console (no-GPU) simulator and a foxglove_bridge WebSocket server so
# you can visualize the robot pose, sensors, TF and thruster telemetry in
# Foxglove Studio without needing a GPU/display. Connect Foxglove to:
#     ws://localhost:8765
#
# Usage:
#   ros2 launch bringup stonefish_foxglove.py
#   ros2 launch bringup stonefish_foxglove.py port:=8765
from launch_ros.substitutions import FindPackageShare
from launch_ros.actions import Node
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, DeclareLaunchArgument
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import PathJoinSubstitution, LaunchConfiguration


def generate_launch_description():
    port = LaunchConfiguration('port')

    return LaunchDescription([
        DeclareLaunchArgument('port', default_value='8765',
                              description='Foxglove Bridge WebSocket port'),

        # The headless simulator (physics + ROS topics, no window).
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource([
                PathJoinSubstitution([
                    FindPackageShare('bringup'), 'launch', 'stonefish_no_gui.py'
                ])
            ])
        ),

        # Foxglove Bridge: serves the ROS graph over a WebSocket.
        # address 0.0.0.0 so it is reachable from outside a container.
        Node(
            package='foxglove_bridge',
            executable='foxglove_bridge',
            name='foxglove_bridge',
            output='screen',
            parameters=[{
                'port': port,
                'address': '0.0.0.0',
            }],
        ),
    ])
