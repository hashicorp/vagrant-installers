hashicorp_modules = [
  'autotools',
  'bsdtar',
  'build_essential',
  'download',
  'fpm',
  'homebrew',
  'libffi',
  'libyaml',
  'openssl',
  'params_lookup',
  'patch',
  'powershell',
  'readline',
  'ruby',
  'rubyencoder',
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
    opts[:ref] = "c9d47c55c8cb7f7d7a963ca76298160e911d4c4d"
    opts[:path] = "modules/#{module_name}"
  end

  mod module_name, opts
end
