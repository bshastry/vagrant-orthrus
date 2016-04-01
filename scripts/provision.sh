#!/bin/bash

echo I am provisioning...

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
sudo apt-get update &> /dev/null

echo -e "Installing basic toolset"
sudo apt-get install -y python-software-properties &> /dev/null
sudo apt-get install -y python-bs4 python-pip &> /dev/null
sudo apt-get update &> /dev/null

echo -e "Installing JDK and boilerplate stuff"
sudo apt-get install -y cmake make tmux git \
	vim htop xdot openjdk-7-jdk unzip gdb \
	graphviz libgraphviz-dev python-setuptools python-dev \
	libz-dev libncurses5-dev ant &> /dev/null

sudo ln -s /vagrant/scripts/fetch.sh /usr/bin/fetch &> /dev/null
echo -e "Provisioning done. Login to provisioned VM by doing 'vagrant ssh'"
