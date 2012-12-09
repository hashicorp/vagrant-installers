hashicorp_modules = [
  'autotools',
  'build_essential',
  'download',
  'fpm',
  'libffi',
  'libyaml',
  'openssl',
  'params_lookup',
  'patch',
  'powershell',
  'readline',
  'ruby',
  'util',
  'vagrant',
  'vagrant_installer',
  'wget',
  'wix',
  'zlib',
]

hashicorp_modules.each do |module_name|
  # The options to pass for our module
  opts = {}

  # If the LOCAL environmental variable is set, then we load the Puppet
  # modules from a local path.
  if ENV["LOCAL"]
    opts[:path] = "../puppet-modules/modules/#{module_name}"
  else
    opts[:git] = "git://github.com/hashicorp/puppet-modules.git"
    opts[:ref] = "5c3c887e1c17f8974c8035e89a54d0134c6d7be3"
    opts[:path] = "modules/#{module_name}"
  end

  mod module_name, opts
end
