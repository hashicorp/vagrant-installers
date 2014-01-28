# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<CODE
wget -O- https://raw.github.com/hashicorp/puppet-bootstrap/master/ubuntu.sh | sh
CODE

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"

  config.vm.provision "shell", inline: $script

  ["vmware_fusion", "vmware_workstation"].each do |p|
    config.vm.provider "p" do |v|
      v.vmx["memsize"] = "2048"
      v.vmx["numvcpus"] = "2"
      v.vmx["cpuid.coresPerSocket"] = "1"
    end
  end
end
