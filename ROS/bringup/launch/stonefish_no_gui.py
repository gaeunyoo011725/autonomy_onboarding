from launch_ros.substitutions import FindPackageShare
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import PathJoinSubstitution

def generate_launch_description():
    return LaunchDescription([
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource([
                PathJoinSubstitution([
                    FindPackageShare('stonefish_ros2'),
                    'launch',
                    'stonefish_simulator_nogpu.launch.py'
                ])
            ]),
            launch_arguments = {
                'simulation_data' : PathJoinSubstitution([FindPackageShare('bringup')]),
                'scenario_desc' : PathJoinSubstitution([FindPackageShare('bringup'), 'scenarios', 'underwater.scn']),
                'simulation_rate' : '300.0',
            }.items()
        )
    ])