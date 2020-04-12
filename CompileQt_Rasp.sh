#!/bin/bash

sudo apt-get update
sudo apt-get -y build-dep qt5-qmake
sudo apt-get -y build-dep libqt5gui5
sudo apt-get -y build-dep libqt5webengine-data
sudo apt-get -y build-dep libqt5webkit5
sudo apt-get -y install libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0 gdbserver

sudo mkdir /usr/local/RaspberryQt
sudo chown -R pi:pi /usr/local/RaspberryQt

sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh
sudo mkdir -p /home/pi/.ssh
sudo chmod 700 /home/pi/.ssh