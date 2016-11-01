# ros-pr-transplant
Script to automatically clone a pull request targeted to an specific ROS release to one or more differente releases. It will use the original commits and create a new pull request with the same original description. 

## Usage

* Install hub https://hub.github.com/
* Edit the transplan_pr script to set ALL_BRANCHES properly if you are not using ${ROS_RELEASE}-devel schema
* transplant_pr --help

## Example

`transplant_pr https://github.com/ros-simulation/gazebo_ros_pkgs/pull/500 kinetic-devel`

Result: https://github.com/ros-simulation/gazebo_ros_pkgs/pull/501
