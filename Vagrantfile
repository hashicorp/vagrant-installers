# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.customize ["modifyvm", :id, "--memory", "1024"]

  config.vm.define :ubuntu_32 do |vm|
    vm.vm.box = "lucid32"
    vm.vm.provision :shell, :path => "support/vagrant/ubuntu.sh"
  end

  config.vm.define :ubuntu_64 do |vm|
    vm.vm.box = "lucid64"
    vm.vm.provision :shell, :path => "support/vagrant/ubuntu.sh"
  end
end
