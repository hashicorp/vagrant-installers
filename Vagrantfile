# -*- mode: ruby -*-
# vi: set ft=ruby :

build_boxes = [
  'centos-5.11',
  'centos-5.11-i386',
  'osx-10.9',
  'ubuntu-10.04',
  'ubuntu-10.04-i386',
  'win-7'
]

# Valid types: "substrate", "package"
build_type = ENV.fetch('VAGRANT_BUILD_TYPE', 'substrate')
# Box name prefix to allow custom box usage
box_prefix = ENV.fetch('VAGRANT_BUILD_BOX_PREFIX', 'spox')
script_base = File.join(build_type, "vagrant-scripts")

script_env_vars = Hash[
  ENV.map do |key, value|
    if key.start_with?('VAGRANT_INSTALLER_')
      [key.sub('VAGRANT_INSTALLER_', ''), value]
    end
  end.compact
]

Vagrant.configure("2") do |config|
  build_boxes.each do |box_basename|
    config.vm.define(box_basename) do |box_config|
      script_name = box_basename.split('-').first
      script_ext = script_name.start_with?('win') ? 'ps1' : 'sh'
      provision_script = File.join(script_base, "#{script_name}.#{script_ext}")

      box_config.vm.box = "#{box_prefix}/#{box_basename}"
      if box_basename.include?('osx')
        box_config.vm.provision 'shell', inline: "sysctl -w net.inet.tcp.win_scale_factor=8\nsysctl " \
                                                 "-w net.inet.tcp.autorcvbufmax=33554432\nsysctl -w " \
                                                 "net.inet.tcp.autosndbufmax=33554432\n"
      end
      box_config.vm.provision "shell", path: provision_script, env: script_env_vars
      if script_name.start_with?('win')
        box_config.vm.communicator = 'winrm'
      end

      ["vmware_fusion", "vmware_workstation"].each do |p|
        config.vm.provider "p" do |v|
          v.vmx["memsize"] = "4096"
          v.vmx["numvcpus"] = "2"
          v.vmx["cpuid.coresPerSocket"] = "1"
        end
      end
    end
  end
end
