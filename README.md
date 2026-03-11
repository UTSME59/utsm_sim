# UTSM sim
Containerised ROS2 Humble environment for development of the UTS Motorsports Autonomous software stack. Includes a ROS Gym bridge, RViz visualization, and a development workspace for implementing and testing nodes in a reproducible Docker environment. 

# Installation

**Supported Systems:**

- Ubuntu (tested on 22.04) native with ROS 2
- Ubuntu (tested on 22.04) with an NVIDIA gpu and nvidia-docker2 support
- Windows 10, macOS, and Ubuntu without an NVIDIA gpu (using noVNC)

This installation guide will be split into instruction for installing the ROS 2 package natively, and for systems with or without an NVIDIA gpu in Docker containers.

It is recommended to install via the docker container with NoVNC. 

## Docker w/o an NVIDIA gpu:

**Install the following dependencies:**

If your system does not support nvidia-docker2, noVNC will have to be used to forward the display.
- Again you'll need **Docker**. Follow the instruction from above.
- Additionally you'll need **docker-compose**. Follow the instruction [here](https://docs.docker.com/compose/install/) to install docker-compose.

**Installing the simulation:**

1. Clone this repo 
2. Bringup the novnc container and the sim container with docker-compose:
```bash
docker-compose up
``` 
3. **Before launching the simulation**, open your browser and go to [http://localhost:8080/vnc.html](http://localhost:8080/vnc.html). Click **Connect** to attach to the virtual desktop. The RViz window will appear in this browser tab when you launch the simulation.
4. In a separate terminal, get a bash session in the simulation container (the container name should be `_sim-sim-1`, you can check by running `docker ps -a`):
```bash
docker exec -it utsm_sim-sim-1 /bin/bash
```

### Launching the Simulation

1. `tmux` is included in the container, so you can create multiple bash sessions in the same terminal.
2. Make sure you have already opened [http://localhost:8080/vnc.html](http://localhost:8080/vnc.html) in your browser and clicked **Connect**. Then, in the bash session inside the container, all of the required setup files should already be sourced, but if something isn't working right try to source the workspace (`/opt/ros/humble/setup.bash`, `/sim_ws/install/setup.bash` and `/ros_ws/install/setup.bash`) Run the simulator by entering the following:
```bash
$ ros2 launch rosgym gym_bridge_launch.py
```

   The launch will print: **Open http://localhost:8080/vnc.html in your browser and click Connect to view RViz.** The RViz window appears in that browser tab (not as a separate window on your host). If RViz still does not appear, open the browser and click Connect *before* starting the launch, or run headless with `launch_rviz:=false`.

3. **Headless (no RViz):** To run without the GUI, use:
```bash
$ ros2 launch rosgym gym_bridge_launch.py launch_rviz:=false
```

You can then run another node by creating another bash session in `tmux`.

## With an NVIDIA gpu:

**Install the following dependencies:**

- **Docker** Follow the instructions [here](https://docs.docker.com/install/linux/docker-ce/ubuntu/) to install Docker. A short tutorial can be found [here](https://docs.docker.com/get-started/) if you're not familiar with Docker. If you followed the post-installation steps you won't have to prepend your docker and docker-compose commands with sudo.
- **nvidia-docker2**, follow the instructions [here](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) if you have a support GPU. It is also possible to use Intel integrated graphics to forward the display, see details instructions from the Rocker repo. If you are on windows with an NVIDIA GPU, you'll have to use WSL (Windows Subsystem for Linux). Please refer to the guide [here](https://developer.nvidia.com/cuda/wsl), [here](https://docs.nvidia.com/cuda/wsl-user-guide/index.html), and [here](https://dilililabs.com/zh/blog/2021/01/26/deploying-docker-with-gpu-support-on-windows-subsystem-for-linux/).
- **rocker** [https://github.com/osrf/rocker](https://github.com/osrf/rocker). This is a tool developed by OSRF to run Docker images with local support injected. We use it for GUI forwarding. If you're on Windows, WSL should also support this.

**Installing the simulation:**

1. Clone this repo
2. Build the docker image by:
```bash
$ cd utsm_sim
$ docker build -t utsm_sim -f Dockerfile .
```
3. To run the containerised environment, start a docker container by running the following. (example showned here with nvidia-docker support). By running this, the directory `utsm_sim/rosgym` is mounted in the container at `/sim_ws/src/rosgym`. When developing your own node `utsm_sim/ros_ws` will be mounted at `/ros_ws` so use this folder. The changes you make in the repo on the host system will also reflect in the container.
```bash
$ rocker --nvidia --x11 --volume .:/sim_ws/src/rosgym -- utsm_sim
```


## Native on Ubuntu 22.04

**Install the following dependencies:**
- **ROS 2** Follow the instructions [here](https://docs.ros.org/en/humble/Installation.html) to install ROS 2 Humble.

**Installing the simulation:**
- Create a workspace: ```cd $HOME && mkdir -p sim_ws/src```
- Clone the repo into the workspace:
  ```bash
  cd $HOME/sim_ws/src
  git clone https://github.com/UTSME59/utsm_sim.git
  ```
- Update correct parameter for path to map file:
  Go to `sim.yaml` [https://github.com/UTSME59/utsm_sim/blob/main/rosgym/config/sim.yaml](https://github.com/UTSME59/utsm_sim/blob/main/rosgym/config/sim.yaml) in your cloned repo, change the `map_path` parameter to point to the correct location. It should be `'<your_home_dir>/sim_ws/src/rosgym/maps/levine'`
- Install dependencies with rosdep:
  ```bash
  source /opt/ros/humble/setup.bash
  cd ..
  rosdep install -i --from-path src --rosdistro humble -y
  ```
- Build the workspace: ```colcon build```




# Configuring the simulation
- The configuration file for the simulation is at `rosgym/config/sim.yaml`.
- The default RViz config has the **Map** display disabled to avoid a known GLSL shader error in some environments. You can enable it from the RViz Displays panel if you want to see the map.
- Topic names and namespaces can be configured but is recommended to leave uncahnged.
- The map can be changed via the `map_path` parameter. You'll have to use the full path to the map file in the container. The map follows the ROS convention. It is assumed that the image file and the `yaml` file for the map are in the same directory with the same name. See the note below about mounting a volume to see where to put your map file.
- The `num_agent` parameter can be changed to either 1 or 2 for single or two agent racing.
- The ego and opponent starting pose can also be changed via parameters, these are in the global map coordinate frame.

The entire directory of the repo is mounted to a workspace `/sim_ws/src` as a package. All changes made in the repo on the host system will also reflect in the container. After changing the configuration, run `colcon build` again in the container workspace to make sure the changes are reflected.


# Topics published by the simulation

In **single** agent:

`/scan`: The ego agent's laser scan

`/ego_racecar/odom`: The ego agent's odometry

`/map`: The map of the environment

A `tf` tree is also maintained.

In **two** agents:

In addition to the topics available in the single agent scenario, these topics are also available:

`/opp_scan`: The opponent agent's laser scan

`/ego_racecar/opp_odom`: The opponent agent's odometry for the ego agent's planner

`/opp_racecar/odom`: The opponent agents' odometry

`/opp_racecar/opp_odom`: The ego agent's odometry for the opponent agent's planner

# Topics subscribed by the simulation

In **single** agent:

`/drive`: The ego agent's drive command via `AckermannDriveStamped` messages

`/initalpose`: This is the topic for resetting the ego's pose via RViz's 2D Pose Estimate tool. Do **NOT** publish directly to this topic unless you know what you're doing.

TODO: kb teleop topics

In **two** agents:

In addition to all topics in the single agent scenario, these topics are also available:

`/opp_drive`: The opponent agent's drive command via `AckermannDriveStamped` messages. Note that you'll need to publish to **both** the ego's drive topic and the opponent's drive topic for the cars to move when using 2 agents.

`/goal_pose`: This is the topic for resetting the opponent agent's pose via RViz's 2D Goal Pose tool. Do **NOT** publish directly to this topic unless you know what you're doing.

# Keyboard Teleop

The keyboard teleop node from `teleop_twist_keyboard` is also installed as part of the simulation's dependency. To enable keyboard teleop, set `kb_teleop` to `True` in `sim.yaml`. After launching the simulation, in another terminal, run:
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```
Then, press `i` to move forward, `u` and `o` to move forward and turn, `,` to move backwards, `m` and `.` to move backwards and turn, and `k` to stop in the terminal window running the teleop node.

# Developing and creating your own agent in ROS 2

There are multiple ways to launch your own agent to control the vehicles.

- The first one is creating a new package for your agent in the `/ros_ws` workspace inside the sim container. After launch the simulation, launch the agent node in another bash session while the sim is running.
- The second one is to create a new ROS 2 container for you agent node. Then create your own package and nodes inside. Launch the sim container and the agent container both. With default networking configurations for `docker`, the behavior is to put The two containers on the same network, and they should be able to discover and talk to each other on different topics. If you're using noVNC, create a new service in `docker-compose.yml` for your agent node. You'll also have to put your container on the same network as the sim and novnc containers.
