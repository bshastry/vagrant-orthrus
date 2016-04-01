# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.provision "shell" do |s|
	s.path = "scripts/provision.sh"
  end
  config.vm.provider "virtualbox" do |v|
	v.name = "joern-runtime-vm"
	v.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
	v.memory = 4096
	v.cpus = 1
  end
  config.ssh.forward_agent = true 
  config.ssh.forward_x11 = true
end
