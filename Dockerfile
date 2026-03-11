FROM ros:humble

SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git \
                       nano \
                       vim \
                       python3-pip \
                       libeigen3-dev \
                       tmux \
                       ros-humble-rviz2
RUN apt-get -y dist-upgrade
RUN pip3 install transforms3d

RUN mkdir gym
COPY ./gym /gym
RUN cd gym && \
    pip3 install -e .

RUN mkdir -p sim_ws/src/rosgym 
RUN mkdir -p ros_ws/src
COPY ./rosgym /sim_ws/src/rosgym
RUN source /opt/ros/humble/setup.bash && \
    cd sim_ws && \
    apt-get update && \
    rosdep install -i --from-path src --rosdistro humble -y && \
    colcon build 

RUN cd / && \
    echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
    echo "source /sim_ws/install/setup.bash" >> /root/.bashrc && \
    echo "source /ros_ws/install/setup.bash" >> /root/.bashrc

WORKDIR '/ros_ws'

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

