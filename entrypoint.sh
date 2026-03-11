#!/bin/bash
set -e

source /opt/ros/humble/setup.bash
source /sim_ws/install/setup.bash

exec "$@"