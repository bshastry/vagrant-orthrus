#!/bin/bash

echo I am provisioning...

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
sudo apt-get update &> /dev/null

echo -e "Installing basic toolset"
sudo apt-get install -y python-software-properties &> /dev/null
sudo apt-get install -y python-bs4 python-pip &> /dev/null
wget -q -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - &> /dev/null
sudo add-apt-repository -y "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.8 main" &> /dev/null
sudo apt-get update &> /dev/null

echo -e "Installing JDK and boilerplate stuff"
sudo apt-get install -y cmake make tmux git \
	vim htop xdot openjdk-7-jdk unzip gdb \
	graphviz libgraphviz-dev python-setuptools python-dev \
	libz-dev libncurses5-dev ant execstack &> /dev/null

echo -e "Installing clang 3.8 and all associated runtime libs"
sudo apt-get install -y clang-3.8 libclang-common-3.8-dev llvm-3.8-runtime &> /dev/null
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-3.8 50 &> /dev/null
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.8 50 &> /dev/null

sudo ln -s /vagrant/scripts/fetch.sh /usr/local/bin/fetch &> /dev/null
echo -e "Provisioning done. Login to provisioned VM by doing 'vagrant ssh'"
