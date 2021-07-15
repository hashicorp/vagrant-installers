# -*- mode: ruby -*-
# vi: set ft=ruby :

build_boxes = [
  'appimage',
  'archlinux',
  'centos-7',
  'centos-7-i386',
  'osx-10.15',
  'ubuntu-14.04',
  'ubuntu-14.04-i386',
  'win-8',
]

box_mappings = {
  'appimage' => 'ubuntu-14.04',
  'appimage-i386' => 'ubuntu-14.04-i386',
}

skip_boxes = ENV['VAGRANT_SKIP_BOXES'].to_s.split(',')
build_boxes.delete_if{|b| skip_boxes.include?(b) }

only_boxes = ENV['VAGRANT_ONLY_BOXES'].to_s.split(',')
if !only_boxes.empty?
  build_boxes.delete_if{|b| !only_boxes.include?(b) }
end

# Valid types: "substrate", "package"
build_type = ENV.fetch('VAGRANT_BUILD_TYPE', 'substrate')
# Box name prefix to allow custom box usage
box_prefix = ENV.fetch('VAGRANT_BUILD_BOX_PREFIX', 'hashicorp-vagrant')
script_base = File.join(build_type, "vagrant-scripts")

if build_type == 'substrate'
  build_boxes.delete("appimage")
end

unprivileged_provision = []
if build_type != 'substrate'
  #unprivileged_provision << "archlinux"
end

script_env_vars = Hash[
  ENV.map do |key, value|
    if key.start_with?('VAGRANT_INSTALLER_')
      [key.sub('VAGRANT_INSTALLER_', ''), value]
    end
  end.compact
]

Vagrant.configure("2") do |config|
  config.vm.base_mac = nil
  build_boxes.each do |box_basename|
    config.vm.define(box_basename) do |box_config|
      script_name = box_basename.split('-').first
      script_ext = script_name.start_with?('win') ? 'ps1' : 'sh'
      provision_script = File.join(script_base, "#{script_name}.#{script_ext}")

      box_name = box_mappings.fetch(box_basename, box_basename)
      box_name = "#{box_prefix}/#{box_name}" if !box_name.include?("/")
      box_config.vm.box = box_name

      if box_basename.include?('osx')
        box_config.vm.provision 'shell', inline: "sysctl -w net.inet.tcp.win_scale_factor=8\nsysctl " \
                                                 "-w net.inet.tcp.autorcvbufmax=33554432\nsysctl -w " \
                                                 "net.inet.tcp.autosndbufmax=33554432\n"
        ["MacOS_CodeSigning.p12", "MacOS_PackageSigning.cert", "MacOS_PackageSigning.key"].each do |path|
          if File.exist?(path)
            box_config.vm.provision "file", source: path, destination: "/Users/vagrant/#{path}"
          end
        end
      end

      if script_name.start_with?('win')
        box_config.vm.communicator = 'winrm'
        box_config.vm.guest = :windows
        if File.exist?("Win_CodeSigning.p12")
          box_config.vm.provision "file", source: "Win_CodeSigning.p12", destination: "C:/Users/vagrant/Win_CodeSigning.p12"
        end
      end

      box_config.vm.provision "shell", path: provision_script, env: script_env_vars,
                              privileged: !unprivileged_provision.include?(box_basename)

      config.vm.provider :vmware_desktop do |v|
        v.ssh_info_public = true
        v.vmx["memsize"] = ENV.fetch("VAGRANT_GUEST_MEMORY_#{script_name.upcase}", ENV.fetch("VAGRANT_GUEST_MEMORY", "4096"))
        v.vmx["numvcpus"] = ENV.fetch("VAGRANT_GUEST_CPUS_#{script_name.upcase}", ENV.fetch("VAGRANT_GUEST_CPUS", "3"))
        v.vmx["tools.upgrade.policy"] = "manual"
        v.vmx["cpuid.coresPerSocket"] = "1"
      end
    end
  end
end
