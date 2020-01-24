# -*- mode: ruby -*-
# vi: set ft=ruby :

build_boxes = [
  'appimage',
#  'archlinux',
  'centos-6',
  'centos-6-i386',
  'osx-10.15',
  'ubuntu-14.04',
  'ubuntu-14.04-i386',
  'win-7',
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
  build_boxes.delete("archlinux")
  build_boxes.delete("appimage")
end

unprivileged_provision = ["archlinux"]

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

      box_config.vm.box = "#{box_prefix}/#{box_mappings.fetch(box_basename, box_basename)}"

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
      box_config.vm.provision "shell", path: provision_script, env: script_env_vars,
                              privileged: !unprivileged_provision.include?(box_basename)
      if script_name.start_with?('win')
        box_config.vm.communicator = 'winrm'
        if File.exist?("Win_CodeSigning.p12")
          box_config.vm.provision "file", source: "Win_CodeSigning.p12", destination: "C:/Users/vagrant/Win_CodeSigning.p12"
        end
      end

      config.vm.provider :vmware_desktop do |v|
        v.ssh_info_public = true
        v.vmx["memsize"] = ENV.fetch("VAGRANT_GUEST_MEMORY_#{script_name.upcase}", ENV.fetch("VAGRANT_GUEST_MEMORY", "4096"))
        v.vmx["numvcpus"] = ENV.fetch("VAGRANT_GUEST_CPUS_#{script_name.upcase}", ENV.fetch("VAGRANT_GUEST_CPUS", "1"))
        v.vmx["tools.upgrade.policy"] = "manual"
        v.vmx["cpuid.coresPerSocket"] = "1"
      end
    end
  end
end

if Vagrant.version?("<= 2.2.6")
  require Vagrant.source_root.join("plugins/guests/darwin/cap/mount_vmware_shared_folder.rb")

  VagrantPlugins::GuestDarwin::Cap::MountVmwareSharedFolder.class_eval do
    def self.mount_vmware_shared_folder(machine, name, guestpath, options)
      # Use this variable to determine which machines
      # have been registered with after hook
      @apply_firmlinks ||= Hash.new{ |h, k| h[k] = {bootstrap: false, content: []} }

      machine.communicate.tap do |comm|
        # check if we are dealing with an APFS root container
        if comm.test("test -d /System/Volumes/Data")
          parts = Pathname.new(guestpath).descend.to_a
          firmlink = parts[1].to_s
          firmlink.slice!(0, 1) if firmlink.start_with?("/")
          if parts.size > 2
            guestpath = File.join("/System/Volumes/Data", guestpath)
          else
            guestpath = nil
          end
        end

        # Remove existing symlink or directory if defined
        if guestpath
          if comm.test("test -L \"#{guestpath}\"")
            comm.sudo("rm -f \"#{guestpath}\"")
          elsif comm.test("test -d \"#{guestpath}\"")
            comm.sudo("rm -Rf \"#{guestpath}\"")
          end

          # create intermediate directories if needed
          intermediate_dir = File.dirname(guestpath)
          if intermediate_dir != "/"
            comm.sudo("mkdir -p \"#{intermediate_dir}\"")
          end

          comm.sudo("ln -s \"/Volumes/VMware Shared Folders/#{name}\" \"#{guestpath}\"")
        end

        if firmlink && !system_firmlink?(firmlink)
          if guestpath.nil?
            guestpath = "/Volumes/VMware Shared Folders/#{name}"
          else
            guestpath = File.join("/System/Volumes/Data", firmlink)
          end

          share_line = "#{firmlink}\t#{guestpath}"

          # Check if the line is already defined. If so, bail since we are done
          if !comm.test("[[ \"$(</etc/synthetic.conf)\" = *\"#{share_line}\"* ]]")
            comm.sudo("echo -e #{share_line.inspect} > /etc/synthetic.conf")
            comm.sudo("/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B")
          end
        end
      end
    end

    # Check if firmlink is provided by the system
    #
    # @param [String] firmlink Firmlink path
    # @return [Boolean]
    def self.system_firmlink?(firmlink)
      if !@_firmlinks
        if File.exist?("/usr/share/firmlinks")
          @_firmlinks = File.readlines("/usr/share/firmlinks").map do |line|
            line.split.first
          end
        else
          @_firmlinks = []
        end
      end
      firmlink = "/#{firmlink}" if !firmlink.start_with?("/")
      @_firmlinks.include?(firmlink)
    end
  end
end
