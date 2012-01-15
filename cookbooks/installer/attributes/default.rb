# This is the path where the installers will be saved once they're created
default[:installer][:output_dir] = File.expand_path("../../../../dist", __FILE__)

case platform
when 'windows'
  default[:installer][:staging_dir] = "#{ENV['SYSTEMDRIVE']}\\vagrant-temp"
else
  default[:installer][:staging_dir] = "/tmp/vagrant-temp"
end
