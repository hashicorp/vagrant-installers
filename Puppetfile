hashicorp_modules = [
  'autotools',
  'bsdtar',
  'build_essential',
  'curl',
  'download',
  'fpm',
  'homebrew',
  'libffi',
  'libiconv',
  'libxml2',
  'libxslt',
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
    opts[:ref] = "c35caa677d1c29e2cd71fa965ec97b8db1dc61c9"
    opts[:path] = "modules/#{module_name}"
  end

  mod module_name, opts
end
